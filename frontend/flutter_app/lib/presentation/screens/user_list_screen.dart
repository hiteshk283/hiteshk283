import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

import '../widgets/glass_container.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  void _showGenerateCodeDialog() async {
    final code = await context.read<UserProvider>().generateLinkCode();
    if (!mounted) return;

    if (code != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E0B2E),
          title: const Text('Your Invite Code', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code with your friend. It can only be used once.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                child: SelectableText(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF00FFC2))),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                Navigator.pop(context);
              },
              child: const Text('Copy & Close', style: TextStyle(color: Color(0xFFFF2A5F))),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate code')));
    }
  }

  void _showLinkFriendDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E0B2E),
        title: const Text('Link with Friend', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter Invite Code', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<UserProvider>().linkWithCode(controller.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully linked!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or used code')));
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient through
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code, color: Color(0xFF00FFC2)), onPressed: _showGenerateCodeDialog, tooltip: 'Generate Code'),
          IconButton(icon: const Icon(Icons.person_add, color: Color(0xFFFF2A5F)), onPressed: _showLinkFriendDialog, tooltip: 'Link Friend'),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF2A5F)));
          }

          final otherUsers = userProvider.users.where((u) => u.id != currentUserId).toList();

          if (otherUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 80, color: Colors.white30),
                  const SizedBox(height: 16),
                  const Text('No connections yet', style: TextStyle(fontSize: 20, color: Colors.white54)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Link with Friend'),
                    onPressed: _showLinkFriendDialog,
                  )
                ],
              ),
            );
          }

          final allUsersList = [
            ...otherUsers.where((u) => u.isAi),
            ...otherUsers.where((u) => !u.isAi),
          ];

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
            itemCount: allUsersList.length,
            itemBuilder: (context, index) {
              final user = allUsersList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: user.isAi
                            ? const LinearGradient(colors: [Color(0xFF00FFC2), Color(0xFF0080FF)])
                            : const LinearGradient(colors: [Color(0xFFFF2A5F), Color(0xFFFF8000)]),
                      ),
                      child: Center(
                        child: user.isAi
                            ? const Icon(Icons.smart_toy, color: Colors.white)
                            : Text(user.username.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                    ),
                    title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                    subtitle: user.isAi ? const Text('AI Assistant', style: TextStyle(color: Color(0xFF00FFC2))) : null,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      color: const Color(0xFF1E0B2E),
                      onSelected: (value) async {
                        if (value == 'block') {
                          final success = await userProvider.blockUser(user.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blocked ${user.username}')));
                          }
                        } else if (value == 'unblock') {
                          final success = await userProvider.unblockUser(user.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unblocked ${user.username}')));
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: 'block', child: Text('Block', style: TextStyle(color: Colors.orange))),
                        const PopupMenuItem<String>(value: 'unblock', child: Text('Unblock', style: TextStyle(color: Colors.green))),
                      ],
                    ),
                    onTap: () {
                      context.push('/chat/${user.id}?name=${user.username}');
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
