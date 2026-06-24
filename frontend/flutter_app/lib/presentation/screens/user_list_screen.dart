import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter out current user from list
          final otherUsers = userProvider.users.where((u) => u.id != currentUserId).toList();

          return ListView(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF6C63FF),
                  child: Icon(Icons.public, color: Colors.white),
                ),
                title: const Text('Global Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Chat with everyone'),
                onTap: () {
                  context.push('/chat/global');
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('DIRECT MESSAGES', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              ...otherUsers.map((user) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2A2A2A),
                      child: Text(user.username.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(user.username),
                    onTap: () {
                      context.push('/chat/${user.id}?name=${user.username}');
                    },
                  )),
            ],
          );
        },
      ),
    );
  }
}
