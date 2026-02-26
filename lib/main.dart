import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Это будет сгенерировано Flutter после `flutter run` или `flutter build`
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

import 'package:nova/core/theme/app_theme.dart';
import 'package:nova/presentation/screens/home_screen.dart';
import 'package:nova/presentation/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const NovaApp(),
    ),
  );
}

class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final locale = ref.watch(localeProvider);
    
    return MaterialApp(
      title: 'Nova',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      
      // Настройки локализации
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', ''),
        Locale('en', ''),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (var locale in supportedLocales) {
            if (locale.languageCode == deviceLocale.languageCode) {
              return deviceLocale;
            }
          }
        }
        // По умолчанию английский, если язык системы не русский и не английский
        return const Locale('en', '');
      },
      
      home: const HomeScreen(),
    );
  }
}
