import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../data/models.dart';

class UserProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/users/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _users = data.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateLinkCode() async {
    try {
      final response = await _apiClient.post('/api/connections/code', {});
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['code'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> linkWithCode(String code) async {
    try {
      final response = await _apiClient.post('/api/connections/link?code=$code', {});
      if (response.statusCode == 200) {
        await fetchUsers(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      final response = await _apiClient.post('/api/connections/$userId/block', {});
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      final response = await _apiClient.post('/api/connections/$userId/unblock', {});
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
