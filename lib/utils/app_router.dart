import 'package:flutter/material.dart';
import '../screens/home/screens.dart';
import '../screens/user/screens.dart';
import '../screens/knowledge/screens.dart';
import '../screens/persona/screens.dart';
import '../screens/message/screens.dart';
import '../screens/shared/screens.dart';

import '../models/knowledge.dart';
import '../models/persona.dart';

class AppRouter {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String knowledge = '/knowledge';
  static const String persona = '/persona';
  static const String message = '/message';
  static const String about = '/about';
  static const String settings = '/settings';
  static const String knowledgeDetail = '/knowledge_detail';
  static const String personaDetail = '/persona_detail';
  static const String messageDetail = '/message_detail';
  static const String upload = '/upload';
  static const String editKnowledge = '/editKnowledge';
  static const String editPersona = '/editPersona';
  static const String myContent = '/my_content';

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
      case register:
        return _createRoute(const RegisterScreen(), settings);
      case knowledge:
        return _createRoute(const KnowledgeScreen(), settings);
      case persona:
        return _createRoute(const PersonaScreen(), settings);
      case message:
        return _createRoute(const MessageScreen(), settings);
      case about:
        return _createRoute(const AboutScreen(), settings);
      case AppRouter.settings:
        return _createRoute(const SettingsScreen(), settings);
      case myContent:
        return _createRoute(const MyContentScreen(), settings);
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
        String personaId = '';
        if (settings.arguments != null) {
          if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            personaId = args['personaId'] as String? ?? '';
          } else if (settings.arguments is String) {
            // 兼容直接传递字符串的情况
            personaId = settings.arguments as String;
          }
        }
        return _createRoute(
          PersonaDetailScreen(personaId: personaId),
          settings,
        );
      case messageDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final messageId = args?['messageId'] as String?;
        return _createRoute(
          MessageDetailScreen(messageId: messageId ?? ''),
          settings,
        );
      // Upload路由已删除，统一上传功能通过管理页面提供
      case editKnowledge:
        Knowledge? knowledge;
        if (settings.arguments is Knowledge) {
          knowledge = settings.arguments as Knowledge;
        } else if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          if (args['knowledge'] is Knowledge) {
            knowledge = args['knowledge'] as Knowledge;
          } else if (args['knowledge'] is Map<String, dynamic>) {
            knowledge = Knowledge.fromJson(
              args['knowledge'] as Map<String, dynamic>,
            );
          }
        }
        return _createRoute(
          EditKnowledgeScreen(knowledge: knowledge!),
          settings,
        );
      case editPersona:
        final args = settings.arguments as Map<String, dynamic>?;
        final rawPersona = args?['persona'];
        Persona? persona;
        if (rawPersona is Persona) {
          persona = rawPersona;
        } else if (rawPersona is Map<String, dynamic>) {
          persona = Persona.fromJson(rawPersona);
        }
        return _createRoute(
          EditPersonaScreen(persona: persona!),
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
