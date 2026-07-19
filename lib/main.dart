import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/staff_dashboard_screen.dart';

import 'firebase_options.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/auth_gate.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Try loading dotenv variables. Handled gracefully if file does not exist.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If not found, app defaults to mock fallback conversational responses.
  }

  runApp(const ProviderScope(child: StadiumGenieApp()));
}

class StadiumGenieApp extends ConsumerWidget {
  const StadiumGenieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.isDarkMode;

    return MaterialApp(
      title: 'StadiumGenie - FIFA 2026',
      debugShowCheckedModeBanner: false,

      // Light Mode theme config matching Stitch design
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),

      // Dark Mode theme config matching Stitch design
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        primaryColor: AppColors.primaryContainer,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryContainer,
          brightness: Brightness.dark,
          primary: AppColors.primaryContainer,
          secondary: AppColors.secondaryContainer,
          surface: AppColors.darkSurface,
          error: AppColors.error,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/staff': (context) => const StaffDashboardScreen(),
      },
    );
  }
}
