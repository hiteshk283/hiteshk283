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
            if (newMsg.receiverId == null) isForCurrentChat = true;
          } else {
            if (newMsg.receiverId != null) {
               if (newMsg.senderId == _currentReceiverId || newMsg.receiverId == _currentReceiverId) {
                  isForCurrentChat = true;
               }
            }
          }

          if (isForCurrentChat) {
            // Deduplicate: Check if we have an optimistic message with same text
            final tempIndex = _messages.indexWhere((m) => m.id.startsWith('temp_') && m.messageText == newMsg.messageText);
            if (tempIndex != -1) {
              _messages[tempIndex] = newMsg; // Replace temp message with real one
            } else {
              _messages.insert(0, newMsg); // Add new message to top
            }
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

  Future<bool> sendOptimisticMessage(String text, String currentUserId) async {
    // 1. Optimistic UI Update - show instantly!
    final tempMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      receiverId: _currentReceiverId,
      messageText: text,
      createdAt: DateTime.now(),
    );
    _messages.insert(0, tempMsg);
    notifyListeners();

    // 2. Send to backend
    try {
      final body = <String, dynamic>{
        'message_text': text,
      };
      if (_currentReceiverId != null) {
        body['receiver_id'] = _currentReceiverId;
      }
      final response = await _apiClient.post('/api/messages/', body);
      if (response.statusCode != 201) {
         // Revert on failure
         _messages.removeWhere((m) => m.id == tempMsg.id);
         notifyListeners();
         return false;
      }
      return true;
    } catch (e) {
      // Revert on failure
      _messages.removeWhere((m) => m.id == tempMsg.id);
      notifyListeners();
      return false;
    }
  }
}
