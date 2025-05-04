// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:googleapis_auth/auth_io.dart';

// Future<drive.DriveApi> getDriveApi(GoogleSignInAccount account) async {
//   final authHeaders = await account.authHeaders;
//   final authenticateClient = GoogleAuthClient(authHeaders);
//   return drive.DriveApi(authenticateClient);
// }

// class GoogleAuthClient extends http.BaseClient {
//   final Map<String, String> _headers;
//   final http.Client _client = http.Client();

//   GoogleAuthClient(this._headers);

//   Future<http.StreamedResponse> send(http.BaseRequest request) {
//     request.headers.addAll(_headers);
//     return _client.send(request);
//   }
// }