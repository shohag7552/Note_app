import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:my_note_app/appwrite/app_write_config.dart';
import 'package:my_note_app/appwrite/app_write_service.dart';
import 'package:my_note_app/model/note_model.dart';

class AppWriteRepository {
  final AppwriteService _appwriteService = AppwriteService();

  Future<List<Note>> getNotes({
    int limit = 10,
    int offset = 0,
    required String authorId,
  }) async {
    try {
      List<String> queries = [
        Query.limit(limit),
        Query.offset(offset),
        Query.equal('author', authorId),
        // Query.orderDesc('createdAt'),
      ];

      final response = await _appwriteService.listDocuments(
        collectionId: AppwriteConfig.noteTable,
        queries: queries,
      );

      print('===notes response==> ${response.documents}');
      return response.documents.map((doc) => Note.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  Future<void> createNote({required Note note}) async {
    try {

      final response = await _appwriteService.createDocument(
        collectionId: AppwriteConfig.noteTable,
        data: note.toJson(),
      );

      // return Note.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Future<void> googleLogin() async {
  //   try {
  //    var response = await _appwriteService.signInWithGoogleJWT();
  //    print('===google login response==> $response');
  //   } catch (e) {
  //     throw Exception('Failed to login with Google: $e');
  //   }
  //
  // }
  //
  // Future<void> googleLogOut() async {
  //   try {
  //    await _appwriteService.signOut();
  //    print('===google signout');
  //   } catch (e) {
  //     throw Exception('Failed to login with Google: $e');
  //   }
  //
  // }

  // Future<User?> getCurrentUser() async {
  //   try {
  //     User? user = await _appwriteService.getCurrentUser();
  //     print('===current user==> $user');
  //     return user;
  //   } catch (e) {
  //     throw Exception('Failed to get current user: $e');
  //   }
  // }

  // Future<PostModel> updatePost({
  //   required String postId,
  //   String? title,
  //   String? content,
  //   String? categoryId,
  //   List<String>? tags,
  // }) async {
  //   try {
  //     Map<String, dynamic> data = {
  //       'updatedAt': DateTime.now().toIso8601String(),
  //     };
  //
  //     if (title != null) data['title'] = title;
  //     if (content != null) data['content'] = content;
  //     if (categoryId != null) data['category'] = categoryId;
  //     if (tags != null) data['tags'] = tags;
  //
  //     final response = await _appwriteService.updateDocument(
  //       collectionId: AppwriteConfig.postsCollection,
  //       documentId: postId,
  //       data: data,
  //     );
  //
  //     return PostModel.fromMap(response.data);
  //   } catch (e) {
  //     throw Exception('Failed to update post: $e');
  //   }
  // }
  //
  // Future<void> deletePost(String postId) async {
  //   try {
  //     await _appwriteService.deleteDocument(
  //       collectionId: AppwriteConfig.postsCollection,
  //       documentId: postId,
  //     );
  //   } catch (e) {
  //     throw Exception('Failed to delete post: $e');
  //   }
  // }
  //
  // Future<void> likePost(String postId, int currentLikes) async {
  //   try {
  //     await _appwriteService.updateDocument(
  //       collectionId: AppwriteConfig.postsCollection,
  //       documentId: postId,
  //       data: {'likes': currentLikes + 1},
  //     );
  //   } catch (e) {
  //     throw Exception('Failed to like post: $e');
  //   }
  // }
}