import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'services/ad_service.dart';
import 'services/game_services_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.initialize();
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('setting_notifications') ?? true;
    if (notificationsEnabled) {
      await NotificationService.scheduleDailyReminder();
    }
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  try {
    await SoundService.init();
  } catch (e) {
    debugPrint('SoundService init error: $e');
  }

  try {
    AdService.initialize();
  } catch (e) {
    debugPrint('AdService init error: $e');
  }

  try {
    await GameServicesHelper.initialize();
  } catch (e) {
    debugPrint('GameServicesHelper init error: $e');
  }

  // Lock to portrait mode for best mobile experience
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (e) {
    debugPrint('Orientation lock error: $e');
  }

  // Make status bar transparent
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('SystemUIOverlayStyle error: $e');
  }

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
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        final isDark = user.darkModeEnabled;
        return MaterialApp(
          title: 'Number Haven: Cozy Math Village',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
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
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF14110E), // Cozy dark night
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8D6E63),
              primary: const Color(0xFFD7CCC8),
              secondary: const Color(0xFF81C784),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1813),
            ),
            fontFamily: GoogleFonts.baloo2().fontFamily,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFFECEFF1)),
              bodyMedium: TextStyle(color: Color(0xFFCFD8DC)),
              titleLarge: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.bold),
            ),
          ),
          initialRoute: AppRouter.splash,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
