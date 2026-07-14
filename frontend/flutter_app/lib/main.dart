import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'core/websocket_client.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/user_list_screen.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/notification_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/admin_screen.dart';

void main() {
  runApp(const ControlCenterApp());
}

class ControlCenterApp extends StatefulWidget {
  const ControlCenterApp({super.key});

  @override
  State<ControlCenterApp> createState() => _ControlCenterAppState();
}

class _ControlCenterAppState extends State<ControlCenterApp> {
  final WebSocketClient _wsClient = WebSocketClient();
  late final AuthProvider _authProvider;
  late final ChatProvider _chatProvider;
  late final NotificationProvider _notificationProvider;
  late final UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(_wsClient);
    _chatProvider = ChatProvider(_wsClient);
    _notificationProvider = NotificationProvider(_wsClient);
    _userProvider = UserProvider();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _chatProvider),
        ChangeNotifierProvider.value(value: _notificationProvider),
        ChangeNotifierProvider.value(value: _userProvider),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          
          if (auth.isLoading) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          final router = GoRouter(
            initialLocation: auth.isAuthenticated ? '/chat' : '/login',
            routes: [
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/register',
                builder: (context, state) => const RegisterScreen(),
              ),
              ShellRoute(
                builder: (context, state, child) => HomeScreen(child: child),
                routes: [
                  GoRoute(
                    path: '/chat',
                    builder: (context, state) => const UserListScreen(),
                    routes: [
                      GoRoute(
                        path: 'global',
                        builder: (context, state) => const ChatScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id'];
                          final name = state.uri.queryParameters['name'] ?? 'Private Chat';
                          return ChatScreen(receiverId: id, chatTitle: name);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: '/notifications',
                    builder: (context, state) => const NotificationScreen(),
                  ),
                  GoRoute(
                    path: '/settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: '/admin',
                    builder: (context, state) => const AdminScreen(),
                  ),
                ],
              ),
            ],
            redirect: (context, state) {
              final loggedIn = auth.isAuthenticated;
              final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';

              if (!loggedIn && !isAuthRoute) return '/login';
              if (loggedIn && (isAuthRoute || state.uri.path == '/')) return '/chat';
              return null;
            },
          );

          return MaterialApp.router(
            title: 'Control Center',
            theme: AppTheme.darkTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
}
