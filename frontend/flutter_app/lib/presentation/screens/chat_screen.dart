import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_gradient_bg.dart';
import '../widgets/glass_container.dart';

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

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.chatTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (widget.receiverId != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF1E0B2E),
                onSelected: (value) async {
                  if (value == 'clear') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E0B2E),
                        title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to delete all messages in this chat? This cannot be undone.', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final success = await context.read<ChatProvider>().clearChat(widget.receiverId!);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat cleared successfully')));
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clear chat')));
                      }
                    }
                  } else if (value == 'block') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E0B2E),
                        title: const Text('Block User', style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to block this user?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Block', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final success = await context.read<UserProvider>().blockUser(widget.receiverId!);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked successfully')));
                        context.pop();
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to block user')));
                      }
                    }
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: Text('Clear Chat', style: TextStyle(color: Colors.redAccent)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'block',
                    child: ListTile(
                      leading: Icon(Icons.block, color: Colors.orangeAccent),
                      title: Text('Block User', style: TextStyle(color: Colors.orangeAccent)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chat, child) {
                  if (chat.isLoading && chat.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFF2A5F)));
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                    itemCount: chat.messages.length + (chat.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (chat.isTyping && index == 0) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: GlassContainer(
                              blur: 10,
                              opacity: 0.1,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FFC2)),
                                  ),
                                  SizedBox(width: 12),
                                  Text("Typing...", style: TextStyle(color: Color(0xFF00FFC2), fontWeight: FontWeight.w500)),
                                ],
                              ),
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
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: isMe
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF2A5F), Color(0xFFFF8000)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF2A5F).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Text(msg.messageText, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                )
                              : GlassContainer(
                                  blur: 10,
                                  opacity: 0.1,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Text(msg.messageText, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassContainer(
                  blur: 15,
                  opacity: 0.15,
                  borderRadius: BorderRadius.circular(30),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF00FFC2), Color(0xFF0080FF)]),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _send,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
