import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/navidrome_provider.dart';
import 'services/storage_service.dart';

import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  final storageService = StorageService();
  await storageService.init();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.imvj.flacify.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storageService),
      ],
      child: const FlacifyApp(),
    ),
  );
}

class FlacifyApp extends ConsumerWidget {
  const FlacifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerProvider);

    return MaterialApp(
      title: 'Flacify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Chora uses pure dark Material 3 with no tint
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white70,
          onSecondary: Colors.black,
          surface: Color(0xFF121212),
          onSurface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        dividerColor: Colors.white12,
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white70,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(color: Colors.white54, size: 24),
          ),
        ),
        useMaterial3: true,
      ),
      home: activeServer == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
