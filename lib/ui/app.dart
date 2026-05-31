import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import 'router.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/settings_provider.dart';

class GanneApp extends ConsumerWidget {
  const GanneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);
    final settings = ref.watch(appSettingsProvider);

    if (authState.isLoading) {
      return MaterialApp(
        theme: AppTheme.darkTheme(null, 'purple'),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(lightDynamic, settings.themeAccent),
          darkTheme: AppTheme.darkTheme(darkDynamic, settings.themeAccent),
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
