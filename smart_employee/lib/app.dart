// app.dart
// Main application widget for Smart Employee
//
// This file defines the MaterialApp with theme configuration,
// routing, and global application settings.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'utils/constants.dart';
import 'theme/app_theme.dart';

/// Main application widget
class SmartEmployeeApp extends StatelessWidget {
  const SmartEmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeController, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<AuthController, AuthState>(
          builder: (context, authState) {
            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeState.mode,
              initialRoute: _getInitialRoute(authState),
              onGenerateRoute: AppRouter.generateRoute,
            );
          },
        );
      },
    );
  }

  /// Determine initial route based on authentication state
  String _getInitialRoute(AuthState state) {
    if (state is AuthAuthenticated) {
      return state.user.isAdmin
          ? AppRoutes.adminDashboard
          : AppRoutes.employeeDashboard;
    }
    return AppRoutes.login;
  }

  // Theme builders are now centralized in AppTheme
}
