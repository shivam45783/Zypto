import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as path;
import 'package:google_sign_in/google_sign_in.dart';

const _scopes = [ga.DriveApi.driveFileScope];

class GoogleDrive {
  Future<http.Client> getClient() async {
    final googleUser = await GoogleSignIn().signInSilently();
    if (googleUser == null) throw Exception("No signed-in Google user");

    final googleAuth = await googleUser.authentication;
    final token = googleAuth.accessToken;

    if (token == null) throw Exception("No access token");

    final accessToken = AccessToken(
      'Bearer',
      token,
      DateTime.now().add(Duration(minutes: 60)).toUtc(), 
    );

    return authenticatedClient(
      http.Client(),
      AccessCredentials(accessToken, null, _scopes),
    );
  }

  Future<String> getOrCreateFolder(String folderName) async {
    final client = await getClient();
    final drive = ga.DriveApi(client);
    final query =
        "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";
    final fileList = await drive.files.list(q: query, spaces: 'drive');

    if (fileList.files != null && fileList.files!.isNotEmpty) {
  
      return fileList.files!.first.id!;
    }

    final folderMetadata = ga.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final folder = await drive.files.create(folderMetadata);
    return folder.id!;
  }

  Future upload(File file, String folderName) async {
    var client = await getClient();
    var drive = ga.DriveApi(client);

    final folderId = await getOrCreateFolder(folderName);
    final fileMetadata = ga.File()
      ..name = path.basename(file.path)
      ..parents = [folderId];

    final media = ga.Media(file.openRead(), file.lengthSync());
    try {
      final response = await drive.files.create(
        fileMetadata,
        uploadMedia: media,
      );
      print("Uploaded File ID: ${response.id}");
      return response.id;
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
       
        print("Internet disconnected!");
        return "No Internet";
      
      } else {
        print("Upload failed: $e");
      }
    }
  }
}

