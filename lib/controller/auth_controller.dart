import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:notes_app/api/drive_api_client.dart';
import 'package:notes_app/api/text_file_menager.dart';
import 'package:path/path.dart';

enum GDriveStatus{
  uninitialized,
  initialized,
  isOnTask,
  failed,
  uploadComplete,
  downloadComplete,
}


class AuthController extends GetxController implements GetxService {
  final GoogleSignIn googleSignIn;
  AuthController({required this.googleSignIn});

  static const folderName = "GDrive_Backup_Sample_Folder";
  static const folderMime = "application/vnd.google-apps.folder";

  GDriveStatus _status = GDriveStatus.uninitialized;
  GDriveStatus get status => _status;

  DriveApi? driveApi;


  Future<void> _setDrive() async {
    final googleAuthData = await googleSignIn.signIn();
    if (googleAuthData == null) {
      _setStatus(GDriveStatus.failed);
      return;
    }

    final client = GoogleHttpClient(
        await googleAuthData.authHeaders
    );
    driveApi = DriveApi(client);
  }

  Future<void> upload() async {
    _setStatus(GDriveStatus.initialized);
    await _setDrive();

    final localFile = await LocalTextFile.getFile();

    final File gDriveFile = File();
    gDriveFile.name = basename(localFile.absolute.path);

    final existingFile = await _isFileExist(gDriveFile.name!);

    _setStatus(GDriveStatus.isOnTask);
    if (existingFile != null){
      try{
        await driveApi!.files.update(
            gDriveFile,
            existingFile.id!,
            uploadMedia: Media(localFile.openRead(), localFile.lengthSync())
        );
      } catch (err){
        _setStatus(GDriveStatus.failed);
        debugPrint('G-Drive Error : $err');
      }
      _setStatus(GDriveStatus.uploadComplete);
      return;
    }

    final folderId =  await _folderId();
    gDriveFile.parents = [folderId!];

    try{
      await driveApi!.files.create(
        gDriveFile,
        uploadMedia: Media(localFile.openRead(), localFile.lengthSync()),
      );
    } catch (err){
      _setStatus(GDriveStatus.failed);
      debugPrint('G-Drive Error : $err');
    }
    _setStatus(GDriveStatus.uploadComplete);
  }

  Future<void> download() async{
    _setStatus(GDriveStatus.initialized);
    await _setDrive();

    final localFile = await LocalTextFile.getFile();

    final File gDriveFile = File();
    gDriveFile.name = basename(localFile.absolute.path);

    final existingFile = await _isFileExist(gDriveFile.name!);

    if(existingFile ==null){
      _setStatus(GDriveStatus.failed);
      return;
    }

    _setStatus(GDriveStatus.isOnTask);
    Media? downloadedFile;
    try {
      downloadedFile = await driveApi!.files.get(
          existingFile.id!,
          downloadOptions: DownloadOptions.fullMedia
      ) as Media;
    } catch (err){
      _setStatus(GDriveStatus.failed);
      debugPrint('G-Drive Error : $err');
    }

    if(downloadedFile==null){
      _setStatus(GDriveStatus.failed);
      return;
    }

    await _overwriteLocalFile(downloadedFile);
    _setStatus(GDriveStatus.downloadComplete);
  }

  Future<File?> _isFileExist(String fileName) async {
    final folderId =  await _folderId();
    if (folderId == null){
      return null;
    }

    final query = "name = '$fileName' and '$folderId' in parents and trashed = false";
    final driveFileList = await driveApi!.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name, mimeType, parents)',
    );

    if (driveFileList.files == null || driveFileList.files!.isEmpty) {
      return null;
    }

    return driveFileList.files!.first;
  }

  Future<String?> _folderId() async {
    final found = await driveApi!.files.list(
      q: "mimeType = '$folderMime' and name = '$folderName'",
      $fields: "files(id, name)",
    );
    final files = found.files;

    if (files == null) {
      return null;
    }
    if (files.isEmpty){
      final newFolder = await _createNewFolder();
      return newFolder.id;
    }

    return files.first.id;
  }

  Future<File> _createNewFolder() async{
    final File folder = File();
    folder.name = folderName;
    folder.mimeType = folderMime;
    return await driveApi!.files.create(folder);
  }

  Future<void> _overwriteLocalFile(Media downloadedFile) async {
    final StringBuffer stringBuffer = StringBuffer();
    await for (var chunk in downloadedFile.stream) {
      stringBuffer.write(utf8.decode(chunk));
    }
    String fileContent = stringBuffer.toString();
    await LocalTextFile.writeFile(fileContent);
  }

  void _setStatus(GDriveStatus status){
    _status = status;
    update();
  }
}