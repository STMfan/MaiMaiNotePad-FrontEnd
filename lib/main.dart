import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';
import 'screens/home/screens.dart';
import 'screens/user/screens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()..init()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()..init()),
      ],
      child: Consumer2<UserProvider, ThemeProvider>(
        builder: (context, userProvider, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.getLightTheme(themeProvider.primaryColor),
            darkTheme: AppTheme.getDarkTheme(themeProvider.primaryColor),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: userProvider.isLoggedIn
                ? const HomeScreen()
                : const LoginScreen(),
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
