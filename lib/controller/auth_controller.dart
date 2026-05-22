import 'dart:convert';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_note_app/appwrite/app_write_service.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/model/user_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  AuthController({required this.sharedPreferences});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> googleLogin() async {
    _isLoading = true;
    update();

    try {
      // Step 1: Google Sign-In (native popup).
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      log('[AuthController] Google Sign-In result: ${googleAccount?.email} // ${googleAccount?.displayName}');
      if (googleAccount == null) {
        _isLoading = false;
        update();
        return;
      }

      // Step 2: Derive a deterministic Appwrite password from the Google ID.
      final password = _generateAppwritePassword(googleAccount.id);

      // Step 3: Create or resume an Appwrite session.
      final userId = await _createOrLoginAppwriteAccount(
        email: googleAccount.email,
        password: password,
        name: googleAccount.displayName ?? '',
      );

      // Check if user account was previously deactivated
      final prefs = await AppwriteService().account.getPrefs();
      if (prefs.data['status'] == 'deactivated') {
        // Immediately terminate session & log out
        await AppwriteService().deleteCurrentSession();
        await _googleSignIn.signOut();
        
        _isLoading = false;
        update();

        // Show deactivated warning toaster/dialog
        Get.defaultDialog(
          title: 'Account Deactivated',
          middleText: 'This account has been deactivated/scheduled for deletion.\n\n'
              'If you wish to restore your account, please contact support.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
        );
        return;
      }

      // Step 4: Persist user info locally.
      await sharedPreferences.setString(AppConstants.authKey, googleAccount.email);
      await sharedPreferences.setString(AppConstants.authName, googleAccount.displayName ?? '');
      await sharedPreferences.setString(AppConstants.authImage, googleAccount.photoUrl ?? '');
      await sharedPreferences.setString(AppConstants.authId, userId);

      _isLoading = false;
      update();

      // Step 5: Navigate to sync progress screen for visual feedback.
      Get.offAllNamed(AppRoute.SYNC_PROGRESS);

      // Step 6: Start real-time subscription + trigger full sync (background).
      Get.find<SyncService>().startRealtimeSync(googleAccount.email);
      _triggerSync(googleAccount.email);
    } catch (e) {
      print('[AuthController] Login error: $e');
      _isLoading = false;
      update();
    }
  }

  // ── Logout & Deactivation ──────────────────────────────────────────────────

  Future<void> googleLogOut() async {
    try {
      Get.find<SyncService>().stopRealtimeSync();
      await AppwriteService().deleteCurrentSession();
      await _googleSignIn.signOut();
      await sharedPreferences.remove(AppConstants.authKey);
      await sharedPreferences.remove(AppConstants.authName);
      await sharedPreferences.remove(AppConstants.authImage);
      await sharedPreferences.remove(AppConstants.authId);
    } catch (error) {
      print('[AuthController] Logout error: $error');
    }
    update();
  }

  Future<bool> deactivateAccount() async {
    _isLoading = true;
    update();

    try {
      // 1. Update preferences to mark status as deactivated in Appwrite
      await AppwriteService().account.updatePrefs(prefs: {
        'status': 'deactivated',
        'deactivatedAt': DateTime.now().toIso8601String(),
      });

      // 2. Stop real-time sync subscription
      Get.find<SyncService>().stopRealtimeSync();

      // 3. Delete Appwrite session & sign out from Google
      await AppwriteService().deleteCurrentSession();
      await _googleSignIn.signOut();

      // 4. Wipe local offline SQLite notes for privacy
      await DatabaseHelper.instance.deleteAllNotes();

      // 5. Clear GetX NoteController's cached notes
      if (Get.isRegistered<NoteController>()) {
        Get.find<NoteController>().notes.clear();
        Get.find<NoteController>().update();
      }

      // 6. Delete all auth credentials from SharedPreferences
      await sharedPreferences.remove(AppConstants.authKey);
      await sharedPreferences.remove(AppConstants.authName);
      await sharedPreferences.remove(AppConstants.authImage);
      await sharedPreferences.remove(AppConstants.authId);

      _isLoading = false;
      update();

      // Navigate to Welcome Screen
      Get.offAllNamed(AppRoute.WELCOME);
      return true;
    } catch (e) {
      print('[AuthController] Deactivation error: $e');
      _isLoading = false;
      update();
      return false;
    }
  }

  // ── Session Management ─────────────────────────────────────────────────────

  /// Ensures an Appwrite session is active. Called on app resume.
  /// If session expired, re-authenticates silently via Google.
  Future<void> ensureSession() async {
    if (!isLoggedIn()) return;
    final hasSession = await AppwriteService().hasActiveSession();
    if (hasSession) return;

    try {
      // Try silent Google re-sign-in (no UI shown if already signed in).
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount == null) return;
      final password = _generateAppwritePassword(googleAccount.id);
      await _createOrLoginAppwriteAccount(
        email: googleAccount.email,
        password: password,
        name: googleAccount.displayName ?? '',
      );
    } catch (e) {
      print('[AuthController] Silent re-auth failed: $e');
    }
  }

  // ── Manual Sync ────────────────────────────────────────────────────────────

  Future<void> syncNow() async {
    final email = getUserToken();
    if (email == null) return;
    await ensureSession();
    _triggerSync(email);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Tries to create an Appwrite session. If account doesn't exist,
  /// creates it first, then creates the session. Returns the Appwrite user.$id.
  Future<String> _createOrLoginAppwriteAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    final acc = AppwriteService().account;

    log('[AuthController] Attempting Appwrite login for $email');
    // Fast path: session for existing account.
    try {
      await acc.createEmailPasswordSession(email: email, password: password);
      final user = await acc.get();
      return user.$id;
    } on AppwriteException catch (e) {
      // Only continue if it's a "user not found" or "invalid credentials" error.
      if (e.code != 401 &&
          e.type != 'user_not_found' &&
          e.type != 'user_invalid_credentials') {
        rethrow;
      }
    }

    // Slow path: account doesn't exist yet — create it.
    try {
      await acc.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } on AppwriteException catch (e) {
      // Ignore "user already exists" — can happen on concurrent logins.
      if (e.code != 409 && e.type != 'user_already_exists') rethrow;
    }

    await acc.createEmailPasswordSession(email: email, password: password);
    final user = await acc.get();
    return user.$id;
  }

  /// Generates a deterministic Appwrite password from [googleId].
  ///
  /// Uses HMAC-SHA256 with a private salt. Always produces the same
  /// 64-char hex string for the same Google account on any device.
  ///
  /// ⚠️ NEVER change the salt after the app has been published — doing so
  /// will lock all existing users out of their Appwrite accounts.
  String _generateAppwritePassword(String googleId) {
    const salt = 'my_note_app_v1_2025';
    final hmac = Hmac(sha256, utf8.encode(salt));
    return hmac.convert(utf8.encode(googleId)).toString();
  }

  void _triggerSync(String email) async {
    _isSyncing = true;
    update();
    try {
      await Get.find<SyncService>().syncOnLogin(email);
    } catch (e) {
      print('[AuthController] Sync error: $e');
    } finally {
      _isSyncing = false;
      update();
    }
  }

  // ── User Info ──────────────────────────────────────────────────────────────

  bool isLoggedIn() => sharedPreferences.containsKey(AppConstants.authKey);

  String? getUserToken() => sharedPreferences.getString(AppConstants.authKey);

  String? getAppwriteUserId() =>
      sharedPreferences.getString(AppConstants.authId);

  UserModel? getUser() {
    return UserModel(
      name: sharedPreferences.getString(AppConstants.authName) ?? '',
      email: sharedPreferences.getString(AppConstants.authKey) ?? '',
      imageUrl: sharedPreferences.getString(AppConstants.authImage) ?? '',
    );
  }
}