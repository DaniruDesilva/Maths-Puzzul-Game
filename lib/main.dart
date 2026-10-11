import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  await NotificationService.scheduleDailyReminder();
  await SoundService.init();

  // Lock to portrait mode for best mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const NumberHavenApp(),
    ),
  );
}

class NumberHavenApp extends StatefulWidget {
  const NumberHavenApp({super.key});

  @override
  State<NumberHavenApp> createState() => _NumberHavenAppState();
}

class _NumberHavenAppState extends State<NumberHavenApp> with WidgetsBindingObserver {
  
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
