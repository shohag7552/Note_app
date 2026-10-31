import 'dart:developer';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' show DriveApi;
import 'package:http/http.dart' as http;
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/drive/drive_repository.dart';
import 'package:my_note_app/helper/note_image_helper.dart';
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
    scopes: ['email', 'profile', DriveApi.driveAppdataScope],
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

      // Step 2: Make sure the Drive permission was actually granted.
      final driveGranted =
          await _googleSignIn.requestScopes([DriveApi.driveAppdataScope]);

      // Step 3: Persist user info locally.
      await _saveAccount(googleAccount);

      _isLoading = false;
      update();

      if (!driveGranted) {
        // Local notes keep working. The drawer offers to connect Drive later.
        Get.offAllNamed(AppRoute.HOME);
        Get.find<SyncService>().syncNow();
        return;
      }

      // Step 4: Navigate to sync progress screen for visual feedback.
      Get.offAllNamed(AppRoute.SYNC_PROGRESS);

      // Step 5: Upload local notes and download notes from Drive.
      _triggerSync();
    } catch (e) {
      print('[AuthController] Login error: $e');
      _isLoading = false;
      update();
    }
  }

  /// Asks for Drive access for a user who is logged in without it, such as
  /// someone who logged in before the app moved to Google Drive.
  Future<bool> connectDrive() async {
    try {
      final account = _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently() ??
          await _googleSignIn.signIn();
      if (account == null) return false;
      if (!await _googleSignIn.requestScopes([DriveApi.driveAppdataScope])) {
        return false;
      }

      // Notes linked to another account's Drive must upload as new files.
      if (account.email != getUserToken()) {
        await DatabaseHelper.instance.markAllForReupload();
      }
      await _saveAccount(account);

      Get.find<SyncService>().clearDriveAccessPrompt();
      _triggerSync();
      return true;
    } catch (e) {
      print('[AuthController] Connect Drive error: $e');
      return false;
    }
  }

  /// Authenticated client for [DriveRepository]. Throws [DriveAuthRequired]
  /// when only the user can fix access. Other errors, such as being offline,
  /// pass through so they aren't mistaken for lost access.
  Future<http.Client> driveClient({bool forceRefresh = false}) async {
    try {
      final account = _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently(suppressErrors: false);
      if (account == null) throw DriveAuthRequired();
      if (forceRefresh) await account.clearAuthCache();
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) throw DriveAuthRequired();
      return client;
    } on PlatformException catch (e) {
      const accessErrors = {
        GoogleSignIn.kSignInRequiredError,
        GoogleSignIn.kSignInFailedError,
        'failed_to_recover_auth',
        'user_recoverable_auth',
      };
      if (accessErrors.contains(e.code)) throw DriveAuthRequired();
      rethrow;
    }
  }

  // ── Logout & Data Deletion ─────────────────────────────────────────────────

  /// Uploads pending changes, then signs out and clears this device, so the
  /// next person to log in can't see these notes.
  ///
  /// Returns false, without signing out, if notes couldn't be uploaded and
  /// [force] is false. Forcing permanently loses those notes on this device.
  Future<bool> googleLogOut({bool force = false}) async {
    _isLoading = true;
    update();
    try {
      final sync = Get.find<SyncService>();
      if (!force) {
        await sync.syncNow();
        final pending = await DatabaseHelper.instance.getPendingNotes();
        if (pending.isNotEmpty) return false;
      }
      await sync.reset();
      await _googleSignIn.signOut();
      await _clearLocalData();
      return true;
    } catch (error) {
      print('[AuthController] Logout error: $error');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// Permanently deletes the user's notes from Drive and this device, then
  /// revokes the app's access to their Google account.
  Future<bool> deleteAccountData() async {
    _isLoading = true;
    update();

    try {
      final sync = Get.find<SyncService>();
      await sync.reset();

      // Cloud data goes first. If this fails, nothing local has been lost.
      final drive = Get.find<DriveRepository>();
      await drive.deleteAllAppData();
      drive.endSession();

      await _googleSignIn.disconnect();
      await _clearLocalData();

      _isLoading = false;
      update();

      // Navigate to Welcome Screen
      Get.offAllNamed(AppRoute.WELCOME);
      return true;
    } catch (e) {
      print('[AuthController] Delete data error: $e');
      _isLoading = false;
      update();
      return false;
    }
  }

  // ── Manual Sync ────────────────────────────────────────────────────────────

  Future<void> syncNow() async {
    if (getUserToken() == null) return;
    _triggerSync();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _saveAccount(GoogleSignInAccount account) async {
    await sharedPreferences.setString(AppConstants.authKey, account.email);
    await sharedPreferences.setString(AppConstants.authName, account.displayName ?? '');
    await sharedPreferences.setString(AppConstants.authImage, account.photoUrl ?? '');
  }

  Future<void> _clearLocalData() async {
    await DatabaseHelper.instance.deleteAllNotes();
    await NoteImageHelper.deleteAll();

    if (Get.isRegistered<NoteController>()) {
      final notes = Get.find<NoteController>();
      notes.notes.clear();
      notes.deletedNotes.clear();
      notes.update();
    }

    await sharedPreferences.remove(AppConstants.authKey);
    await sharedPreferences.remove(AppConstants.authName);
    await sharedPreferences.remove(AppConstants.authImage);
  }

  void _triggerSync() async {
    _isSyncing = true;
    update();
    try {
      await Get.find<SyncService>().syncNow();
    } finally {
      _isSyncing = false;
      update();
    }
  }

  // ── User Info ──────────────────────────────────────────────────────────────

  bool isLoggedIn() => sharedPreferences.containsKey(AppConstants.authKey);

  String? getUserToken() => sharedPreferences.getString(AppConstants.authKey);

  UserModel? getUser() {
    return UserModel(
      name: sharedPreferences.getString(AppConstants.authName) ?? '',
      email: sharedPreferences.getString(AppConstants.authKey) ?? '',
      imageUrl: sharedPreferences.getString(AppConstants.authImage) ?? '',
    );
  }
}