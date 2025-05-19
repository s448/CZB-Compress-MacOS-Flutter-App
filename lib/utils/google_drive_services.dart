import 'dart:developer';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class GoogleDriveService {
  late drive.DriveApi _driveApi;

  /// 🔐 Authenticate to Google Drive
  Future<bool> authenticate() async {
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(
        File('credentials.json').readAsStringSync(),
      );

      final scopes = [drive.DriveApi.driveFileScope];
      final authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      _driveApi = drive.DriveApi(authClient);
      print("✅ Google Drive Authentication Successful");

      return true;
    } catch (e) {
      print("❌ Google Drive Authentication Failed: $e");
      return false;
    }
  }

  /// 🚀 Upload a file to Google Drive
  Future<void> uploadFile(String filePath, String folderId) async {
    bool isAuthenticated = await authenticate();
    if (!isAuthenticated) {
      log(
        "⚠️ Google Drive is not authenticated. Please call authenticate() first.",
      );
      return;
    }

    try {
      final fileToUpload = File(filePath);

      var driveFile = drive.File();
      driveFile.name = fileToUpload.uri.pathSegments.last;
      driveFile.parents = [folderId];

      final response = await _driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(
          fileToUpload.openRead(),
          fileToUpload.lengthSync(),
        ),
      );

      print("✅ File Uploaded to Google Drive: ${response.id}");
    } catch (e) {
      print("❌ File Upload Failed: $e");
    }
  }
}
