import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/websocket_client.dart';
import '../../data/models.dart';

class ChatProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final WebSocketClient _wsClient;
  
  List<Message> _messages = [];
  bool _isLoading = false;

  ChatProvider(this._wsClient) {
    _initWsListener();
  }

  String? _currentReceiverId;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentReceiverId => _currentReceiverId;

  void setCurrentChatContext(String? receiverId) {
    _currentReceiverId = receiverId;
    fetchMessages();
  }

  void _initWsListener() {
    _wsClient.messages.listen((data) {
      try {
        final decoded = jsonDecode(data);
        if (decoded['type'] == 'new_message') {
          final newMsg = Message.fromJson(decoded['data']);
          
          bool isForCurrentChat = false;
          if (_currentReceiverId == null) {
            // Global chat context
            if (newMsg.receiverId == null) isForCurrentChat = true;
          } else {
            // Private chat context
            if (newMsg.receiverId != null) {
               if (newMsg.senderId == _currentReceiverId || newMsg.receiverId == _currentReceiverId) {
                  isForCurrentChat = true;
               }
            }
          }

          if (isForCurrentChat) {
            _messages.insert(0, newMsg); // Add to top
            notifyListeners();
          }
        }
      } catch (e) {
        // Handle parsing error
      }
    });
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = _currentReceiverId == null 
          ? '/api/messages/' 
          : '/api/messages/?receiver_id=$_currentReceiverId';
      final response = await _apiClient.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _messages = data.map((json) => Message.fromJson(json)).toList();
        // Since API returns chronological (oldest to newest), we reverse for UI
        _messages = _messages.reversed.toList();
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String text) async {
    try {
      final body = <String, dynamic>{
        'message_text': text,
      };
      if (_currentReceiverId != null) {
        body['receiver_id'] = _currentReceiverId;
      }
      final response = await _apiClient.post('/api/messages/', body);
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
