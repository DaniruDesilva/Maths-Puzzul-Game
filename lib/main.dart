import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'app_router.dart';
import 'data/word_dictionary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the full English dictionary in the background (used for bonus words)
  WordDictionary.instance.load();
  
  await NotificationService.initialize();
  await NotificationService.scheduleDailyReminder();
  await SoundService.init();

  // Lock to portrait mode for best hex grid experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Dark icons for light background
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const WordPuzzleApp(),
    ),
  );
}

class WordPuzzleApp extends StatefulWidget {
  const WordPuzzleApp({super.key});

  @override
  State<WordPuzzleApp> createState() => _WordPuzzleAppState();
}

class _WordPuzzleAppState extends State<WordPuzzleApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.inactive) {
      SoundService.pauseAmbience();
    } else if (state == AppLifecycleState.resumed) {
      SoundService.resumeAmbience();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Haven: Cozy Math Village',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5DD), // Warmer, earthy off-white
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D4037), // Rich wood brown
          primary: const Color(0xFF5D4037),
          secondary: const Color(0xFF7CB342), // Bright meadow green
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.baloo2().fontFamily,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF4A4A4A)),
          bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
          titleLarge: TextStyle(color: Color(0xFF2C3E35), fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
