
import '../config/api_endpoints.dart';
import 'api_service.dart';

class AuthService {
   static Future<Map<String, dynamic>> sendOtp(String email) async {
    final body = {"email": email};
    final res = await ApiService.post(AuthEndpoints.sendOtp, body);
    return res;
  }

  /// Verify OTP and reset password
  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp,
      {required String newPassword}) async {
    final body = {
      "email": email,
      "otp": otp,
      "newPassword": newPassword,
    };
    final res = await ApiService.post(AuthEndpoints.verifyOtp, body);
    return res;
  }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final body = {"email": email, "password": password};
    return await ApiService.post(AuthEndpoints.login, body);
  }

  static Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final body = {
      "email": email,
      "password": password,
      "conformPassword": confirmPassword, // matches backend
      "firstName": firstName,
      "lastName": lastName,
    };
    return await ApiService.post(AuthEndpoints.signUp, body);
  }
}

