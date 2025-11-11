import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body, {String? token}) async {
    final headers = Map<String, String>.from(_jsonHeaders);
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final res = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> get(String url, {String? token}) async {
    final headers = Map<String, String>.from(_jsonHeaders);
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final res = await http.get(Uri.parse(url), headers: headers);
    return _parseResponse(res);
  }

  static Map<String, dynamic> _parseResponse(http.Response res) {
    try {
      if (res.body.isEmpty) return {'success': false, 'message': 'Empty response', 'statusCode': res.statusCode};
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected response format', 'raw': decoded};
    } catch (e) {
      return {'success': false, 'message': 'Parse error: $e', 'statusCode': res.statusCode};
    }
  }
}
