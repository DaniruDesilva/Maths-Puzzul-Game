import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../services/sound_service.dart';
import 'package:vibration/vibration.dart';

class UserProvider extends ChangeNotifier {
  int brainSize = 0;
  int totalScore = 0;
  int hintsRegular = 5;
  int hintsMega = 0;
  int hintsUltra = 0;
  int dailyStreak = 0;
  String? lastPlayedDate;
  
  // Dynamic getter that calculates if the streak is broken
  int get currentStreak {
    if (lastPlayedDate == null) return 0;
    String today = DateTime.now().toIso8601String().substring(0, 10);
    DateTime lastPlayed = DateTime.parse(lastPlayedDate!);
    DateTime current = DateTime.parse(today);
    int difference = current.difference(lastPlayed).inDays;
    
    if (difference > 1) {
      return 0; // Streak broken because more than 1 day has passed
    }
    return dailyStreak;
  }
  
  // Stats
  int wordsFound = 0;
  int levelsCompleted = 0;
  int get currentLevel => levelsCompleted + 1;
  int hintsUsedTotal = 0;
  List<String> claimedAchievements = [];
  bool adsRemoved = false;
  
  // Settings
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool hapticsEnabled = true;
  
  bool isLoading = true;
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  // Bonus Jar: every [bonusJarTarget] bonus words earns a free hint.
  static const int bonusJarTarget = 5;
  int bonusJar = 0;
  int totalBonusWords = 0;

  // Economy
  int coins = 0;

  // Village Building Levels (e.g., "Meadow_Bakery": 1)
  Map<String, int> villageBuildings = {};
  
  // Last collected time for village building rewards
  Map<String, DateTime> buildingRewardTimes = {};

  // High scores for each level (level_number -> stars)
  Map<int, int> levelStars = {};

  SharedPreferences? _prefs;

  UserProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadBonusJar();
    } catch (e) {
      debugPrint('SharedPreferences load error: $e');
    }

    try {
      await SoundService.init();
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }

    try {
      await _loadUser();
    } catch (e) {
      debugPrint('Database load error: $e');
    } finally {
      isLoading = false;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      notifyListeners();
    }
  }

  Future<void> _loadBonusJar() async {
    if (_prefs == null) return;
    bonusJar = _prefs!.getInt('bonus_jar') ?? 0;
    totalBonusWords = _prefs!.getInt('total_bonus_words') ?? 0;
    coins = _prefs!.getInt('coins') ?? 0;

    soundEnabled = _prefs!.getBool('setting_sound') ?? true;
    musicEnabled = _prefs!.getBool('setting_music') ?? true;
    hapticsEnabled = _prefs!.getBool('setting_haptics') ?? true;
    
    SoundService.setSoundEnabled(soundEnabled);
    SoundService.setMusicEnabled(musicEnabled);
    
    // Load village buildings
    final keys = _prefs!.getKeys();
    for (String key in keys) {
      if (key.startsWith('village_reward_')) {
        final timeStr = _prefs!.getString(key);
        if (timeStr != null) {
          buildingRewardTimes[key.substring(15)] = DateTime.parse(timeStr);
        }
      } else if (key.startsWith('village_')) {
        int savedStage = _prefs!.getInt(key) ?? 0;
        if (savedStage > 0) {
          villageBuildings[key.substring(8)] = savedStage;
        }
      }
    }
    
    notifyListeners();
  }

  /// Records a bonus word. Returns true when the jar fills up and a free
  /// hint is awarded.
  bool addBonusWord() {
    totalBonusWords++;
    bonusJar++;
    
    // Base is 1 coin. Library adds extra coins based on its stage!
    int extraCoins = 0;
    int libraryStage = villageBuildings['library'] ?? 0;
    if (libraryStage > 0) {
      // villageBuildings definition for library has bonusWordCoinsPerStage = 1
      // So Stage 1 = +1, Stage 2 = +2, Stage 3 = +3
      extraCoins = libraryStage * 1;
    }
    
    coins += 1 + extraCoins; 
    
    bool rewarded = false;
    if (bonusJar >= bonusJarTarget) {
      bonusJar = 0;
      hintsRegular += 1;
      rewarded = true;
      _saveUser();
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('bonus_jar', bonusJar);
      prefs.setInt('total_bonus_words', totalBonusWords);
      prefs.setInt('coins', coins);
    });
    notifyListeners();
    return rewarded;
  }

  void addCoins(int amount) {
    coins += amount;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('coins', coins));
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (coins >= amount) {
      coins -= amount;
      SharedPreferences.getInstance().then((prefs) => prefs.setInt('coins', coins));
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Whether the user has already received the one-time Starter Gift (+100 coins)
  bool get hasClaimedStarterGift => _prefs?.getBool('starter_coins_awarded') ?? false;

  /// Claims the 100 starter coins from the Welcome Bonus popup modal (strictly once)
  Future<void> claimStarterGift() async {
    if (hasClaimedStarterGift) return;
    coins += 100;
    if (_prefs != null) {
      await _prefs!.setBool('starter_coins_awarded', true);
      await _prefs!.setInt('coins', coins);
    }
    await _saveUser();
    notifyListeners();
  }

  void upgradeBuilding(String buildingId) {
    int currentLevel = villageBuildings[buildingId] ?? 0;
    villageBuildings[buildingId] = currentLevel + 1;
    if (_prefs != null) {
      _prefs!.setInt('village_$buildingId', currentLevel + 1);
      if (currentLevel == 0) {
        buildingRewardTimes[buildingId] = DateTime.now();
        _prefs!.setString('village_reward_$buildingId', DateTime.now().toIso8601String());
      }
    }
    _saveUser();
    notifyListeners();
  }

  Future<void> debugResetVillage() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (String key in keys) {
      if (key.startsWith('village_')) {
        prefs.remove(key);
      }
    }
    villageBuildings.clear();
    buildingRewardTimes.clear();
    notifyListeners();
  }

  // Calculate how many reward stacks are pending
  int getPendingRewards(String buildingId, List<Duration> intervals, int maxStack) {
    int currentStage = villageBuildings[buildingId] ?? 0;
    if (currentStage == 0) return 0; // Not built yet
    
    // Arrays are 0-indexed, stages are 1-indexed
    Duration interval = intervals[currentStage - 1];

    DateTime? lastCollected = buildingRewardTimes[buildingId];
    // If it was built before we added reward tracking, set it so they get a full stack now
    lastCollected ??= DateTime.now().subtract(const Duration(days: 365));
    
    int secondsPassed = DateTime.now().difference(lastCollected).inSeconds;
    int ticks = secondsPassed ~/ interval.inSeconds;
    
    if (ticks > maxStack) ticks = maxStack;
    return ticks;
  }

  // Collect pending rewards
  void collectBuildingReward(String buildingId, int amount, String type) {
    // Add rewards based on type
    if (type == 'coins') {
      coins += amount;
      SharedPreferences.getInstance().then((prefs) => prefs.setInt('coins', coins));
    } else if (type == 'hint') {
      hintsRegular += amount;
    } else if (type == 'megaHint') {
      hintsMega += amount;
    }

    // Reset timer to now
    buildingRewardTimes[buildingId] = DateTime.now();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('village_reward_$buildingId', DateTime.now().toIso8601String());
    });
    
    _saveUser();
    notifyListeners();
  }

  Future<void> _loadUser() async {
    final data = await DatabaseHelper.instance.getUserProfile();
    if (data != null) {
      brainSize = data[DatabaseHelper.colBrainSize] as int;
      totalScore = data[DatabaseHelper.colTotalScore] as int;
      hintsRegular = data[DatabaseHelper.colHintsRegular] as int;
      hintsMega = data[DatabaseHelper.colHintsMega] as int;
      hintsUltra = data[DatabaseHelper.colHintsUltra] as int;
      dailyStreak = data[DatabaseHelper.colDailyStreak] as int;
      adsRemoved = (data[DatabaseHelper.colAdsRemoved] as int? ?? 0) == 1;
      lastPlayedDate = data[DatabaseHelper.colLastPlayed] as String?;
      wordsFound = data[DatabaseHelper.colWordsFound] as int? ?? 0;
      levelsCompleted = data[DatabaseHelper.colLevelsCompleted] as int? ?? 0;
      hintsUsedTotal = data[DatabaseHelper.colHintsUsedTotal] as int? ?? 0;
      
      String claimed = data[DatabaseHelper.colClaimedAchievements] as String? ?? '';
      claimedAchievements = claimed.isNotEmpty ? claimed.split(',') : [];
    }
    
    // Load individual level progress to power the Star Gate progression!
    final progressList = await DatabaseHelper.instance.getAllLevelProgress();
    for (var row in progressList) {
      int levelNum = row[DatabaseHelper.colLevelNum] as int;
      int stars = row[DatabaseHelper.colStars] as int;
      int isCompleted = row[DatabaseHelper.colIsCompleted] as int? ?? 0;
      levelStars[levelNum] = stars;
      if (isCompleted == 1 && levelNum > levelsCompleted) {
        levelsCompleted = levelNum;
      }
    }

    // Reconcile with SharedPreferences backup to ensure no progress is ever lost
    if (_prefs != null) {
      final prefLevels = _prefs!.getInt('levels_completed') ?? 0;
      if (prefLevels > levelsCompleted) levelsCompleted = prefLevels;
      final prefBrain = _prefs!.getInt('brain_size') ?? 0;
      if (prefBrain > brainSize) brainSize = prefBrain;
      final prefScore = _prefs!.getInt('total_score') ?? 0;
      if (prefScore > totalScore) totalScore = prefScore;
      final prefWords = _prefs!.getInt('words_found') ?? 0;
      if (prefWords > wordsFound) wordsFound = prefWords;
    }
    
    // Retroactive coins for players who completed levels before the village update
    if (_prefs != null) {
      bool awardedRetroactive = _prefs!.getBool('awarded_retroactive_coins') ?? false;
      if (!awardedRetroactive && levelsCompleted > 0) {
        coins += levelsCompleted * 50;
        _prefs!.setBool('awarded_retroactive_coins', true);
        _prefs!.setInt('coins', coins);
      }
    }
    
    isLoading = false;
    notifyListeners();
  }

  void recordLevelComplete({
    required int levelIndex, 
    required int scoreEarned, 
    required int starsEarned, 
    required int hintsUsed,
    required bool isDaily,
    required bool isCustom
  }) {
    if (isDaily || isCustom) {
      totalScore += scoreEarned;
      brainSize += (starsEarned * 50); // Daily/Custom always grant full brain size
    } else {
      int previousStars = levelStars[levelIndex] ?? 0;
      int bestStars = starsEarned > previousStars ? starsEarned : previousStars;
      levelStars[levelIndex] = bestStars;
      
      // Star Gate System: Award Brain Size points for NEW stars earned!
      if (starsEarned > previousStars) {
        int newStars = starsEarned - previousStars;
        brainSize += (newStars * 50); 
        coins += (newStars * 10); // Reward extra coins for new stars earned!
      }
      
      // Always save level progress to SQLite
      DatabaseHelper.instance.saveLevelProgress({
        DatabaseHelper.colBiomeId: 1,
        DatabaseHelper.colPackId: 1, 
        DatabaseHelper.colLevelNum: levelIndex,
        DatabaseHelper.colIsCompleted: 1,
        DatabaseHelper.colStars: bestStars,
        DatabaseHelper.colHintsUsed: hintsUsed,
      });
      
      totalScore += scoreEarned;
      
      if (levelIndex > levelsCompleted) {
        levelsCompleted = levelIndex;
        coins += 50; // Earn 50 coins for completing a new level
      }
    }
    
    _saveUser();
    notifyListeners();
  }

  void addWordFound() {
    wordsFound++;
    _saveUser();
    notifyListeners();
  }

  bool useHint() {
    if (hintsRegular > 0) {
      hintsRegular--;
      hintsUsedTotal++;
      _saveUser();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useMegaHint() {
    if (hintsMega > 0) {
      hintsMega--;
      _saveUser();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useUltraHint() {
    if (hintsUltra > 0) {
      hintsUltra--;
      _saveUser();
      notifyListeners();
      return true;
    }
    return false;
  }

  void claimAchievement(String id, int rewardHints) {
    if (!claimedAchievements.contains(id)) {
      claimedAchievements.add(id);
      hintsRegular += rewardHints;
      _saveUser();
      notifyListeners();
    }
  }


  void addHint([int amount = 1]) {
    hintsRegular += amount;
    _saveUser();
    notifyListeners();
  }

  void addMegaHint([int amount = 1]) {
    hintsMega += amount;
    _saveUser();
    notifyListeners();
  }

  void addUltraHint([int amount = 1]) {
    hintsUltra += amount;
    _saveUser();
    notifyListeners();
  }

  void removeAds() {
    adsRemoved = true;
    _saveUser();
    notifyListeners();
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    if (_prefs != null) _prefs!.setBool('setting_sound', soundEnabled);
    SoundService.setSoundEnabled(soundEnabled);
    if (soundEnabled) SoundService.playClick();
    notifyListeners();
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    if (_prefs != null) _prefs!.setBool('setting_music', musicEnabled);
    SoundService.setMusicEnabled(musicEnabled);
    notifyListeners();
  }

  Future<void> toggleHaptics() async {
    hapticsEnabled = !hapticsEnabled;
    if (_prefs != null) _prefs!.setBool('setting_haptics', hapticsEnabled);
    
    if (hapticsEnabled) {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 50);
      }
    }
    notifyListeners();
  }

  bool canPlayDailyChallenge() {
    String today = DateTime.now().toIso8601String().substring(0, 10);
    return lastPlayedDate != today;
  }

  void completeDailyChallenge() {
    if (!canPlayDailyChallenge()) return; // Already completed today!

    String today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastPlayedDate != null) {
      DateTime lastPlayed = DateTime.parse(lastPlayedDate!);
      DateTime current = DateTime.parse(today);
      final difference = current.difference(lastPlayed).inDays;
      
      if (difference == 1) {
        dailyStreak++;
      } else if (difference > 1) {
        dailyStreak = 1;
      }
    } else {
      dailyStreak = 1; // First time
    }

    if (dailyStreak >= 30) {
      // Loop milestones without wiping visual streak
    }
    
    lastPlayedDate = today;
    
    // Reward for completing daily challenge (3 hints)
    hintsRegular += 3;

    // Milestone rewards
    if (dailyStreak == 14) {
      hintsRegular += 5;
    } else if (dailyStreak == 30) {
      hintsRegular += 10;
      hintsMega += 1;
    }
    
    _saveUser();
    notifyListeners();
  }

  Future<void> _saveUser() async {
    try {
      await DatabaseHelper.instance.updateUserProfile({
        DatabaseHelper.colBrainSize: brainSize,
        DatabaseHelper.colTotalScore: totalScore,
        DatabaseHelper.colHintsRegular: hintsRegular,
        DatabaseHelper.colHintsMega: hintsMega,
        DatabaseHelper.colHintsUltra: hintsUltra,
        DatabaseHelper.colDailyStreak: dailyStreak,
        DatabaseHelper.colAdsRemoved: adsRemoved ? 1 : 0,
        DatabaseHelper.colLastPlayed: lastPlayedDate,
        DatabaseHelper.colWordsFound: wordsFound,
        DatabaseHelper.colLevelsCompleted: levelsCompleted,
        DatabaseHelper.colHintsUsedTotal: hintsUsedTotal,
        DatabaseHelper.colClaimedAchievements: claimedAchievements.join(','),
        DatabaseHelper.colCoins: coins,
        DatabaseHelper.colVillageBuildings: '{}', // Kept for schema compat, logic moved fully to _prefs
      });
    } catch (e) {
      debugPrint('Error saving user profile to DB: $e');
    }
    
    // Backup all critical progress to SharedPreferences as well
    if (_prefs != null) {
      await _prefs!.setInt('coins', coins);
      await _prefs!.setInt('levels_completed', levelsCompleted);
      await _prefs!.setInt('brain_size', brainSize);
      await _prefs!.setInt('total_score', totalScore);
      await _prefs!.setInt('hints_regular', hintsRegular);
      await _prefs!.setInt('hints_mega', hintsMega);
      await _prefs!.setInt('hints_ultra', hintsUltra);
      await _prefs!.setInt('words_found', wordsFound);
    }
  }
}
