import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage.dart';

class ApiClient {
  // Change this to your actual Laravel URL
  static const String baseUrl = 'https://gym.zoezidesk.com/api';

  // ── GET request ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await AppStorage.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  // ── POST request ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    final token = await AppStorage.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ── PUT request ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    final token = await AppStorage.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ── Response handler ──────────────────────────────────────────────
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Mirror how Laravel returns validation errors
    throw ApiException(
      message: data['message'] ?? 'Something went wrong',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await AppStorage.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});
}