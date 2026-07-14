import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(8),
            child: const ListTile(
              leading: Icon(Icons.person, color: Colors.white),
              title: Text('Account Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Manage your details', style: TextStyle(color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 12),
          if (context.watch<AuthProvider>().isAdmin) ...[
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF00FFC2)),
                title: const Text('Admin Dashboard', style: TextStyle(color: Color(0xFF00FFC2), fontWeight: FontWeight.bold)),
                onTap: () {
                  context.push('/admin');
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          GlassContainer(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.orangeAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E0B2E),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Are you sure you want to permanently delete your account? This action cannot be undone and you will lose all access to your connections.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final success = await context.read<AuthProvider>().deleteAccount();
                  if (success && context.mounted) {
                    context.go('/login');
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete account. Please try again later.')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
