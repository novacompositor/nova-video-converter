import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:creos/core/theme/app_theme.dart';
import 'package:creos/presentation/screens/home_screen.dart';
import 'package:creos/presentation/providers/app_providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CreosApp(),
    ),
  );
}

class CreosApp extends ConsumerWidget {
  const CreosApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    return MaterialApp(
      title: 'Creos',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
