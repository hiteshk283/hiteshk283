import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/api_client.dart';
import '../../core/websocket_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final WebSocketClient _wsClient;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _userId;

  AuthProvider(this._wsClient) {
    _checkAuth();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;

  Future<void> _checkAuth() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    
    if (token != null) {
      if (!JwtDecoder.isExpired(token)) {
        _isAuthenticated = true;
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        _userId = decodedToken['sub'];
        await _wsClient.connect();
      } else {
        // Attempt refresh or logout
        await logout();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.postForm('/auth/login', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiClient.saveTokens(data['access_token'], data['refresh_token']);
        
        Map<String, dynamic> decodedToken = JwtDecoder.decode(data['access_token']);
        _userId = decodedToken['sub'];
        
        _isAuthenticated = true;
        notifyListeners();
        await _wsClient.connect();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String email, String username, String password) async {
    try {
      final response = await _apiClient.post('/auth/register', {
        'email': email,
        'username': username,
        'password': password,
      });
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
    _wsClient.disconnect();
    _isAuthenticated = false;
    _userId = null;
    notifyListeners();
  }
}
