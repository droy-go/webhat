import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'screens/home_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/library_screen.dart';
import 'services/story_service.dart';
import 'services/settings_service.dart';
import 'services/native_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize native channel
  NativeChannelService().initialize();

  runApp(const WebHatApp());
}

class WebHatApp extends StatelessWidget {
  const WebHatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoryService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
      ],
      child: MaterialApp(
        title: 'WebHat StoryPack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1E1E2E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF181825),
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF252536),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/library': (context) => const LibraryScreen(),
          '/reader': (context) => const ReaderScreen(),
          '/editor': (context) => const EditorScreen(),
        },
      ),
    );
  }
}
