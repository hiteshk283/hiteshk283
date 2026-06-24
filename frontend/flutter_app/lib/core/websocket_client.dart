import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebSocketClient {
  static const String wsUrl = 'ws://localhost:8000/ws';
  WebSocketChannel? _channel;
  final _messageController = StreamController<String>.broadcast();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Stream<String> get messages => _messageController.stream;

  Future<void> connect() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final uri = Uri.parse('$wsUrl?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (message) {
          _messageController.add(message);
        },
        onDone: () {
          // Reconnection logic could go here
        },
        onError: (error) {
          print('WebSocket Error: $error');
        },
      );
    } catch (e) {
      print('WebSocket Connection Error: $e');
    }
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
