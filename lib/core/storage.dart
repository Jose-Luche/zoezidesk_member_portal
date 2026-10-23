import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AppStorage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey  = 'member_token';
  static const _memberKey = 'member_data';

  // Save auth token after OTP verify
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get token for API requests
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save member info so we don't need to re-fetch on every app open
  static Future<void> saveMember(Map<String, dynamic> member) async {
    await _storage.write(key: _memberKey, value: jsonEncode(member));
  }

  static Future<Map<String, dynamic>?> getMember() async {
    final raw = await _storage.read(key: _memberKey);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  // Clear on logout
  static Future<void> clear() async {
    await _storage.deleteAll();
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}