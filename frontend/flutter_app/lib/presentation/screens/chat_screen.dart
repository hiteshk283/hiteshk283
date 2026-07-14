import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String? receiverId;
  final String chatTitle;

  const ChatScreen({
    super.key,
    this.receiverId,
    this.chatTitle = 'Global Chat',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setCurrentChatContext(widget.receiverId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    context.read<ChatProvider>().clearCurrentChatContext();
    super.deactivate();
  }

  void _send() {
    if (_textController.text.trim().isNotEmpty) {
      final text = _textController.text.trim();
      final authId = context.read<AuthProvider>().userId;
      if (authId != null) {
        context.read<ChatProvider>().sendOptimisticMessage(text, authId);
        _textController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authId = context.read<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
        actions: [
          if (widget.receiverId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat'),
                    content: const Text('Are you sure you want to delete all messages in this chat? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final success = await context.read<ChatProvider>().clearChat(widget.receiverId!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat cleared successfully')),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to clear chat')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, child) {
                if (chat.isLoading && chat.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.messages.length + (chat.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (chat.isTyping && index == 0) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text("Typing...", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final msgIndex = chat.isTyping ? index - 1 : index;
                    final msg = chat.messages[msgIndex];
                    final isMe = msg.senderId == authId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF6C63FF) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          msg.messageText,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: const Color(0xFF1E1E1E),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
