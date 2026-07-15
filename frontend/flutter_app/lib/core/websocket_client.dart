import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebSocketClient {
  static const String wsUrl = 'wss://d1w8csqzvughb4.cloudfront.net/ws';
  WebSocketChannel? _channel;
  final _messageController = StreamController<String>.broadcast();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  
  Stream<String> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;
    _shouldReconnect = true;

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      _isConnecting = false;
      return;
    }

    final uri = Uri.parse('$wsUrl?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      
      _startHeartbeat();

      _channel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message);
            if (decoded['type'] == 'pong') {
              return;
            }
          } catch (_) {}
          _messageController.add(message);
        },
        onDone: () {
          _isConnecting = false;
          _stopHeartbeat();
          if (_shouldReconnect) {
            print('WebSocket closed. Reconnecting...');
            Future.delayed(const Duration(seconds: 3), () => connect());
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _isConnecting = false;
          _stopHeartbeat();
          if (_shouldReconnect) {
            print('WebSocket error. Reconnecting...');
            Future.delayed(const Duration(seconds: 3), () => connect());
          }
        },
      );
    } catch (e) {
      print('WebSocket Connection Error: $e');
      _isConnecting = false;
      _stopHeartbeat();
      if (_shouldReconnect) {
        Future.delayed(const Duration(seconds: 3), () => connect());
      }
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      sendMessage(jsonEncode({"type": "ping"}));
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;
    _isConnecting = false;
  }
}
