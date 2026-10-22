import 'dart:convert';
import 'package:flutter/services.dart';
import '../engine/math/models.dart';
import '../engine/math/puzzle_factory.dart';
import '../engine/math/puzzle_codec.dart';

class MathLevelRepository {
  static List<MathPuzzle>? _cachedCampaign;
  static bool _isLoading = false;

  /// Total number of crafted campaign levels in current release
  static const int totalCampaignLevels = 280;

  static bool get isCampaignLoaded => _cachedCampaign != null && _cachedCampaign!.isNotEmpty;

  /// Loads the 280 frozen levels from JSON asset.
  static Future<void> preloadCampaign() async {
    if (_cachedCampaign != null && _cachedCampaign!.isNotEmpty) return;
    if (_isLoading) return;
    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString('assets/levels/campaign_v1.json');
      final list = jsonDecode(jsonString) as List;
      _cachedCampaign = list.map((item) => MathPuzzle.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      // In headless test environments or asset bundle issues, lazy generation fallback is used
      _cachedCampaign = null;
    } finally {
      _isLoading = false;
    }
  }

  /// Retrieves a campaign level (1 to 280). If level > 280, loops or generates procedural infinite levels.
  static Future<MathPuzzle> getCampaignLevel(int levelNumber) async {
    if (_cachedCampaign == null) {
      await preloadCampaign();
    }

    if (_cachedCampaign != null && levelNumber >= 1 && levelNumber <= _cachedCampaign!.length) {
      return _cachedCampaign![levelNumber - 1];
    }

    // Procedural fallback or beyond 280
    return generateLevelForNumber(levelNumber);
  }

  /// Synchronous getter if campaign is already loaded, otherwise generates synchronously.
  static MathPuzzle getCampaignLevelSync(int levelNumber) {
    if (_cachedCampaign != null && levelNumber >= 1 && levelNumber <= _cachedCampaign!.length) {
      return _cachedCampaign![levelNumber - 1];
    }
    return generateLevelForNumber(levelNumber);
  }

  /// Generates a deterministic puzzle for any level index.
  static MathPuzzle generateLevelForNumber(int level) {
    if (_cachedCampaign != null && _cachedCampaign!.isNotEmpty) {
      final idx = (level - 1) % _cachedCampaign!.length;
      return _cachedCampaign![idx].copyWith(id: level);
    }

    Difficulty difficulty;
    if (level <= 40) {
      difficulty = Difficulty.easy;
    } else if (level <= 120) {
      difficulty = Difficulty.medium;
    } else if (level <= 200) {
      difficulty = Difficulty.hard;
    } else {
      difficulty = Difficulty.expert;
    }

    return MathPuzzleFactory.generate(
      id: level,
      seed: 50000 + level * 31,
      difficulty: difficulty,
      maxRetries: 2,
    );
  }

  /// Retrieves or generates the daily challenge for a given calendar date instantly.
  static MathPuzzle getDailyChallenge(DateTime date) {
    // Alternate difficulties by day of week for fun variety
    final weekday = date.weekday;
    int startLevel, count;
    Difficulty diff;
    if (weekday <= 2) {
      diff = Difficulty.easy;
      startLevel = 1;
      count = 40;
    } else if (weekday <= 4) {
      diff = Difficulty.medium;
      startLevel = 41;
      count = 80;
    } else if (weekday <= 6) {
      diff = Difficulty.hard;
      startLevel = 121;
      count = 80;
    } else {
      diff = Difficulty.expert; // Sunday special
      startLevel = 201;
      count = 80;
    }

    // 1. Instant instant return from curated pre-validated campaign bank if loaded
    if (_cachedCampaign != null && _cachedCampaign!.length >= 280) {
      final dayHash = ((date.year * 372) + (date.month * 31) + date.day).abs();
      final levelIndex = startLevel + (dayHash % count);
      final base = _cachedCampaign![levelIndex - 1];
      return base.copyWith(
        id: date.year * 10000 + date.month * 100 + date.day,
        difficulty: diff,
      );
    }

    // 2. Safe fast fallback
    return MathPuzzleFactory.generate(
      id: date.year * 10000 + date.month * 100 + date.day,
      seed: MathPuzzleCodec.dailySeedForDate(date),
      difficulty: diff,
      maxRetries: 2,
    );
  }

  /// Resolves a custom shareable code into a MathPuzzle.
  static MathPuzzle? getFromSeedCode(String code) {
    final parsed = MathPuzzleCodec.decodeSeed(code);
    if (parsed == null) return null;
    return MathPuzzleFactory.generate(
      id: parsed.id,
      seed: parsed.seed,
      difficulty: parsed.difficulty,
      maxRetries: 2,
    );
  }
}
