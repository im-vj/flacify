import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/navidrome_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_colors.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Global Error Handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[GLOBAL ERROR] ${details.exception}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[PLATFORM ERROR] $error\n$stack');
      return true;
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'A rendering error occurred.\n\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    };

    try {
      debugPrint('[DEBUG] Initializing Hive...');
      await Hive.initFlutter();
      
      debugPrint('[DEBUG] Initializing StorageService...');
      final storageService = StorageService();
      await storageService.init();

      debugPrint('[DEBUG] Initializing JustAudioBackground...');
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.imvj.flacify.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      );

      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));
      
      debugPrint('[DEBUG] Starting App...');
      runApp(
        ProviderScope(
          overrides: [
            storageProvider.overrideWithValue(storageService),
          ],
          child: const FlacifyApp(),
        ),
      );
    } catch (e, stack) {
      debugPrint('[DEBUG] Initialization Error: $e');
      debugPrint('[DEBUG] Stack Trace: $stack');
      runApp(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SelectableText(
                  'Initialization Error:\n$e',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    debugPrint('[ZONED GUARDED] Uncaught error: $error\n$stack');
  });
}

class FlacifyApp extends ConsumerWidget {
  const FlacifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerProvider);
    debugPrint('[DEBUG] Active Server: ${activeServer?.name ?? "NULL (Showing Login Screen)"}');

    return MaterialApp(
      title: 'Flacify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.sky,
          onPrimary: Colors.black,
          secondary: AppColors.teal,
          onSecondary: Colors.black,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceTint: Colors.transparent,
          tertiary: AppColors.neonYellow,
        ),
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.surface,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        dividerColor: Colors.white12,
        listTileTheme: const ListTileThemeData(
          textColor: AppColors.textPrimary,
          iconColor: AppColors.textSecondary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(color: AppColors.textSecondary, size: 24),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.sky,
            foregroundColor: Colors.black,
          ),
        ),
        useMaterial3: true,
      ),
      home: activeServer == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
