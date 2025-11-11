import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Save email
  Future<void> saveEmail(String email) async {
    await _storage.write(key: 'userEmail', value: email);
  }

  // Read saved email
  Future<String?> getEmail() async {
    return await _storage.read(key: 'userEmail');
  }

  // Delete email on logout
  Future<void> deleteEmail() async {
    await _storage.delete(key: 'userEmail');
  }
}
