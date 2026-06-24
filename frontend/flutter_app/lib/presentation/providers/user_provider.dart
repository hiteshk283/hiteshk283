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
}
