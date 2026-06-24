import 'package:flutter/material.dart';

class AppRouter {
  static const initialRoute = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/auth':
        return MaterialPageRoute(builder: (_) => const SizedBox());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const SizedBox());
      case '/messages':
        return MaterialPageRoute(builder: (_) => const SizedBox());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const SizedBox());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SizedBox());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const SizedBox());
      default:
        return MaterialPageRoute(builder: (_) => const SizedBox());
    }
  }
}
