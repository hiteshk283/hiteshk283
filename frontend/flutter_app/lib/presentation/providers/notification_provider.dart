import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/websocket_client.dart';
import '../../data/models.dart';

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final WebSocketClient _wsClient;
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  NotificationProvider(this._wsClient) {
    _initWsListener();
  }

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  void _initWsListener() {
    _wsClient.messages.listen((data) {
      try {
        final decoded = jsonDecode(data);
        if (decoded['type'] == 'notification') {
          final newNotif = AppNotification.fromJson(decoded['data']);
          _notifications.insert(0, newNotif); // Add to top
          notifyListeners();
        }
      } catch (e) {
        // Handle parsing error
      }
    });
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/notifications/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
