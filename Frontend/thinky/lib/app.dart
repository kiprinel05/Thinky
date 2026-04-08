import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/core_controls/services/theme_service.dart';
import 'package:thinky/core_controls/routing/app_router.dart';
import 'package:thinky/shared_controls/theme/app_theme.dart';

class ThinkyApp extends ConsumerWidget {
  const ThinkyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Force rebuild when translations are reloaded
    ref.watch(textRefreshProvider);

    return MaterialApp.router(
      title: 'Thinky',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ro'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
