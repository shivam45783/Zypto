import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class CheckConnection {
  Future<bool> isConnectedToInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      var code = response.statusCode;
      print('statusCode $code');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
