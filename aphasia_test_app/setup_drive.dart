import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;

Future<void> main() async {
  final String serviceAccountJson = r'''
{
  "comment": "REPLACED_FOR_GITHUB_PUSH"
}
''';

  const _scopes = [drive.DriveApi.driveFileScope];
  final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
  final client = await auth.clientViaServiceAccount(credentials, _scopes);
  final driveApi = drive.DriveApi(client);

  print('Creating folder in Service Account Drive...');
  final folder = drive.File();
  folder.name = 'WAT_검사데이터';
  folder.mimeType = 'application/vnd.google-apps.folder';

  final createdFolder = await driveApi.files.create(folder);
  final folderId = createdFolder.id!;
  print('Folder created with ID: $folderId');

  print('Granting permission to wat2026tool@gmail.com...');
  final permission = drive.Permission();
  permission.type = 'user';
  permission.role = 'writer';
  permission.emailAddress = 'wat2026tool@gmail.com';

  await driveApi.permissions.create(permission, folderId, sendNotificationEmail: true);
  print('Done! The folder has been shared.');
}
