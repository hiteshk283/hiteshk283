import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

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
          title: const Text('Your Invite Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code with your friend. It can only be used once.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: SelectableText(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
              child: const Text('Copy & Close'),
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
        title: const Text('Link with Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter Invite Code', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code), onPressed: _showGenerateCodeDialog, tooltip: 'Generate Code'),
          IconButton(icon: const Icon(Icons.person_add), onPressed: _showLinkFriendDialog, tooltip: 'Link Friend'),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final otherUsers = userProvider.users.where((u) => u.id != currentUserId).toList();

          if (otherUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No connections yet', style: TextStyle(fontSize: 20, color: Colors.grey)),
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

          return ListView.builder(
            itemCount: otherUsers.length,
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6C63FF),
                  child: Text(user.username.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: PopupMenuButton<String>(
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
                    const PopupMenuItem<String>(value: 'block', child: Text('Block')),
                    const PopupMenuItem<String>(value: 'unblock', child: Text('Unblock')),
                  ],
                ),
                onTap: () {
                  context.push('/chat/${user.id}?name=${user.username}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
