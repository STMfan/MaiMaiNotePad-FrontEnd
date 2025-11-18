import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/knowledge_screen.dart';
import '../screens/persona_screen.dart';
import '../screens/message_screen.dart';
import '../screens/about_screen.dart';
import '../screens/stars_screen.dart';
import '../screens/knowledge_detail_screen.dart';
import '../screens/persona_detail_screen.dart';
import '../screens/unified_upload_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String login = '/login';
  static const String knowledge = '/knowledge';
  static const String persona = '/persona';
  static const String message = '/message';
  static const String about = '/about';
  static const String settings = '/settings';
  static const String knowledgeDetail = '/knowledge_detail';
  static const String personaDetail = '/persona_detail';
  static const String upload = '/upload';

  // 创建带动画的路由
  static Route<T> _createRoute<T>(
    Widget page,
    RouteSettings settings, {
    RouteTransitionsBuilder? transitionBuilder,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder:
          transitionBuilder ??
          (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _createRoute(const HomeScreen(), settings);
      case login:
        return _createRoute(const LoginScreen(), settings);
      case knowledge:
        return _createRoute(const KnowledgeScreen(), settings);
      case persona:
        return _createRoute(const PersonaScreen(), settings);
      case message:
        return _createRoute(const MessageScreen(), settings);
      case about:
        return _createRoute(const AboutScreen(), settings);
      case '/stars':
        return _createRoute(const StarsScreen(), settings);
      case knowledgeDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final knowledgeId = args?['knowledgeId'] as String?;
        return _createRoute(
          KnowledgeDetailScreen(knowledgeId: knowledgeId ?? ''),
          settings,
        );
      case personaDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final personaId = args?['personaId'] as String?;
        return _createRoute(
          PersonaDetailScreen(personaId: personaId ?? ''),
          settings,
        );
      case upload:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialType = args?['type'] as String?;
        return _createRoute(
          UnifiedUploadScreen(
            initialType: initialType == 'persona'
                ? UploadType.persona
                : UploadType.knowledge,
          ),
          settings,
        );
      default:
        return _createRoute(
          const Scaffold(body: Center(child: Text('页面不存在'))),
          settings,
        );
    }
  }
}
