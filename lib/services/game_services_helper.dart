import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';
export 'package:games_services/games_services.dart';

/// Helper service for managing Google Play Games Services (Android)
/// and Apple Game Center (iOS).
///
/// Handles automatic silent sign-in, leaderboards, achievement unlocking,
/// cloud saves, and UI presentation with robust offline & test fallback.
class GameServicesHelper {
  // Leaderboard IDs (configurable / matched with Play Console)
  static const String leaderboardBrainSize = 'leaderboard_brain_power';
  static const String leaderboardLevelsCompleted = 'leaderboard_levels_completed';
  static const String leaderboardDailyStreak = 'leaderboard_daily_streak';

  // In-Game Achievement ID to Play Games Achievement ID mapping
  static const Map<String, String> achievementIdMap = {
    'words_50': 'achievement_math_apprentice',
    'words_250': 'achievement_arithmetic_wizard',
    'words_1000': 'achievement_crossmath_legend',
    'levels_10': 'achievement_beginner',
    'levels_50': 'achievement_explorer',
    'levels_150': 'achievement_conqueror',
    'hints_20': 'achievement_need_a_hand',
    'streak_3': 'achievement_warming_up',
    'streak_7': 'achievement_on_fire',
  };

  static bool _isSignedIn = false;
  static PlayerData? _currentPlayer;
  static bool _hasAttemptedAutoSignIn = false;

  /// Notifiers for reactive UI binding in settings and headers
  static final ValueNotifier<bool> isSignedInNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<PlayerData?> playerNotifier = ValueNotifier<PlayerData?>(null);

  /// Current signed-in status
  static bool get isSignedIn => _isSignedIn;

  /// Current player data (displayName, playerID, iconImage)
  static PlayerData? get currentPlayer => _currentPlayer;

  /// Whether current platform supports Games Services (Android & iOS)
  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// Silent initialization called during app launch
  static Future<void> initialize() async {
    if (!isPlatformSupported) return;
    if (_hasAttemptedAutoSignIn) return;
    _hasAttemptedAutoSignIn = true;

    try {
      // Listen to player data stream if available
      GameAuth.player.listen((player) {
        _currentPlayer = player;
        _isSignedIn = player != null;
        isSignedInNotifier.value = _isSignedIn;
        playerNotifier.value = player;
      }, onError: (err) {
        debugPrint('Play Games player stream error: $err');
      });

      // Check current sign-in status
      final signedIn = await GameAuth.isSignedIn;
      _isSignedIn = signedIn;
      isSignedInNotifier.value = signedIn;

      if (!signedIn) {
        // Attempt silent sign-in
        final result = await GameAuth.signIn();
        if (result != null && result.isNotEmpty) {
          _isSignedIn = true;
          isSignedInNotifier.value = true;
          debugPrint('Play Games auto sign-in successful: $result');
        }
      }
    } on MissingPluginException {
      // Running in unit / widget tests or unsupported environment
      debugPrint('Play Games not available in current environment (test/mock).');
    } catch (e) {
      debugPrint('Play Games silent initialization notice: $e');
    }
  }

  /// Explicit interactive sign-in triggered by user tap
  static Future<bool> signIn() async {
    if (!isPlatformSupported) return false;

    try {
      final result = await GameAuth.signIn();
      _isSignedIn = await GameAuth.isSignedIn;
      isSignedInNotifier.value = _isSignedIn;
      debugPrint('Play Games explicit sign-in result: $result (isSignedIn: $_isSignedIn)');
      return _isSignedIn;
    } catch (e) {
      debugPrint('Play Games explicit sign-in error: $e');
      _isSignedIn = false;
      isSignedInNotifier.value = false;
      return false;
    }
  }

  /// Explicit sign-out (resets local status; OS account is managed by device settings)
  static Future<void> signOut() async {
    _isSignedIn = false;
    _currentPlayer = null;
    isSignedInNotifier.value = false;
    playerNotifier.value = null;
    debugPrint('Play Games local session reset.');
  }

  /// Unlocks an achievement by in-game achievement ID
  static Future<void> unlockAchievement(String internalId, {int percentComplete = 100}) async {
    if (!isPlatformSupported) return;

    try {
      final gpgsId = achievementIdMap[internalId] ?? internalId;
      await Achievements.unlock(
        achievement: Achievement(
          androidID: gpgsId,
          iOSID: gpgsId,
          percentComplete: percentComplete.toDouble(),
        ),
      );
      debugPrint('Play Games achievement unlocked: $gpgsId');
    } catch (e) {
      // Gracefully catch when offline, not logged in, or ID pending in Play Console
      debugPrint('Play Games achievement unlock notice: $e');
    }
  }

  /// Increments an achievement (for progressive achievements on Android)
  static Future<void> incrementAchievement(String internalId, {int steps = 1}) async {
    if (!isPlatformSupported) return;

    try {
      final gpgsId = achievementIdMap[internalId] ?? internalId;
      await Achievements.increment(
        achievement: Achievement(
          androidID: gpgsId,
          iOSID: gpgsId,
          steps: steps,
        ),
      );
      debugPrint('Play Games achievement incremented: $gpgsId by $steps');
    } catch (e) {
      debugPrint('Play Games achievement increment notice: $e');
    }
  }

  /// Submits a numeric score to a specific leaderboard
  static Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    if (!isPlatformSupported) return;

    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: leaderboardId,
          iOSLeaderboardID: leaderboardId,
          value: score,
        ),
      );
      debugPrint('Play Games score submitted to $leaderboardId: $score');
    } catch (e) {
      debugPrint('Play Games score submit notice: $e');
    }
  }

  /// Syncs all key player scores (Brain Size, Levels Completed, Daily Streak)
  static Future<void> syncAllPlayerScores({
    required int brainSize,
    required int levelsCompleted,
    required int dailyStreak,
  }) async {
    if (!isPlatformSupported) return;

    await submitScore(leaderboardId: leaderboardBrainSize, score: brainSize);
    await submitScore(leaderboardId: leaderboardLevelsCompleted, score: levelsCompleted);
    await submitScore(leaderboardId: leaderboardDailyStreak, score: dailyStreak);
  }

  /// Opens the native Google Play Games / Game Center Achievements UI
  static Future<void> showAchievements() async {
    if (!isPlatformSupported) return;

    try {
      await Achievements.showAchievements();
    } catch (e) {
      debugPrint('Play Games showAchievements notice: $e');
    }
  }

  /// Opens the native Google Play Games / Game Center Leaderboards UI
  static Future<void> showLeaderboards({String? leaderboardId}) async {
    if (!isPlatformSupported) return;

    try {
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: leaderboardId ?? leaderboardBrainSize,
        iOSLeaderboardID: leaderboardId ?? leaderboardBrainSize,
      );
    } catch (e) {
      debugPrint('Play Games showLeaderboards notice: $e');
    }
  }

  /// Saves player game snapshot to Google Play Games Cloud Saves
  static Future<bool> saveCloudSnapshot({
    required Map<String, dynamic> gameData,
    String slotName = 'number_haven_cloud_save',
    String description = 'Number Haven Progress Backup',
  }) async {
    if (!isPlatformSupported) return false;

    try {
      final jsonString = jsonEncode(gameData);
      final coverBytes = Uint8List(0); // Optional cover image bytes
      final result = await SaveGame.saveGame(
        data: jsonString,
        name: slotName,
        description: description,
        coverImage: coverBytes,
      );
      debugPrint('Play Games cloud snapshot saved: $result');
      return true;
    } catch (e) {
      debugPrint('Play Games saveCloudSnapshot notice: $e');
      return false;
    }
  }

  /// Loads player game snapshot from Google Play Games Cloud Saves
  static Future<Map<String, dynamic>?> loadCloudSnapshot({
    String slotName = 'number_haven_cloud_save',
  }) async {
    if (!isPlatformSupported) return null;

    try {
      final result = await SaveGame.loadGame(name: slotName);
      if (result != null && result.isNotEmpty) {
        final decoded = jsonDecode(result);
        if (decoded is Map<String, dynamic>) {
          debugPrint('Play Games cloud snapshot loaded successfully.');
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Play Games loadCloudSnapshot notice: $e');
    }
    return null;
  }
}
