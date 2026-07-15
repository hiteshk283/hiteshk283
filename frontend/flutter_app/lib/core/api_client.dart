import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  //static const String baseUrl = 'http://127.0.0.1:8000'; 
  static const String baseUrl = 'https://d1w8csqzvughb4.cloudfront.net'; // CloudFront CDN URL
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    
    // Add a cache buster timestamp to prevent CloudFront from caching API responses
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = endpoint.contains('?') ? '&' : '?';
    final url = '$baseUrl$endpoint${separator}_t=$timestamp';
    
    return await http.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
  
  Future<http.Response> postForm(String endpoint, Map<String, String> body) async {
    // For OAuth2 Form data (login)
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
  }

  // Token management helpers
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
