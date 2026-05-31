import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/main_navigation_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuthScreen = state.matchedLocation == '/login';

      if (!authState.isAuthenticated) {
        return isAuthScreen ? null : '/login';
      }

      if (isAuthScreen) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScreen(),
      ),
    ],
  );
});
