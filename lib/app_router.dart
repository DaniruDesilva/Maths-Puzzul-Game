import 'package:flutter/material.dart';
import 'ui/splash_screen.dart';
import 'ui/game_screen.dart';
import 'ui/biome_map_screen.dart';
import 'ui/pack_list_screen.dart';
import 'ui/level_list_screen.dart';
import 'ui/achievement_screen.dart';
import 'ui/store_screen.dart';
import 'ui/custom_puzzle_screen.dart';
import 'ui/tutorial_screen.dart';
import 'ui/village_screen.dart';
import 'data/village_data.dart';

class AppRouter {
  static const splash = '/';
  static const home = '/home';
  static const game = '/game';
  static const biomeMap = '/biomeMap';
  static const packList = '/packList';
  static const levelList = '/levelList';
  static const achievements = '/achievements';
  static const store = '/store';
  static const customPuzzle = '/customPuzzle';
  static const tutorial = '/tutorial';
  static const village = '/village';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case splash:
        page = const SplashScreen();
        break;
      case home:
        page = VillageScreen(village: VillageData.meadow, isRoot: true);
        break;
      case game:
        page = const GameScreen();
        break;
      case biomeMap:
        page = const BiomeMapScreen();
        break;
      case achievements:
        page = const AchievementScreen();
        break;
      case store:
        page = const StoreScreen();
        break;
      case customPuzzle:
        page = const CustomPuzzleScreen();
        break;
      case tutorial:
        page = const TutorialScreen();
        break;
      case packList:
        final biome = settings.arguments as Map<String, dynamic>? ?? {};
        page = PackListScreen(biome: biome);
        break;
      case levelList:
        final pack = settings.arguments as Map<String, dynamic>? ?? {};
        page = LevelListScreen(pack: pack);
        break;
      case village:
        final villageDef = settings.arguments as VillageDef;
        page = VillageScreen(village: villageDef);
        break;
      default:
        page = Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        );
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
