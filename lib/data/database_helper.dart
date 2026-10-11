import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static const _databaseName = "hexa_quest_v2.db";
  static const _databaseVersion = 5;

  static const tableUser = 'user_profile';
  static const tableLevelProgress = 'level_progress';

  // User Profile
  static const colId = 'id';
  static const colBrainSize = 'brain_size';
  static const colTotalScore = 'total_score';
  static const colHintsRegular = 'hints_regular';
  static const colHintsMega = 'hints_mega';
  static const colHintsUltra = 'hints_ultra';
  static const colDailyStreak = 'daily_streak';
  static const colLastPlayed = 'last_played_date';
  static const colSound = 'sound_enabled';
  static const colHaptics = 'haptics_enabled';
  static const colAdsRemoved = 'ads_removed';

  // Stats
  static const colWordsFound = 'words_found';
  static const colLevelsCompleted = 'levels_completed';
  static const colHintsUsedTotal = 'hints_used_total';
  static const colClaimedAchievements = 'claimed_achievements';
  static const colCoins = 'coins';
  static const colVillageBuildings = 'village_buildings';

  // Level Progress
  static const colBiomeId = 'biome_id';
  static const colPackId = 'pack_id';
  static const colLevelNum = 'level_number';
  static const colIsCompleted = 'is_completed';
  static const colStars = 'stars';
  static const colHintsUsed = 'hints_used';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE $tableUser ADD COLUMN $colWordsFound INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUser ADD COLUMN $colLevelsCompleted INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUser ADD COLUMN $colHintsUsedTotal INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUser ADD COLUMN $colClaimedAchievements TEXT DEFAULT ""',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUser ADD COLUMN $colCoins INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUser ADD COLUMN $colVillageBuildings TEXT DEFAULT "{}"',
        );
      } catch (_) {}

      try {
        await db.execute('''
          CREATE TABLE $tableLevelProgress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            $colBiomeId INTEGER NOT NULL,
            $colPackId INTEGER NOT NULL,
            $colLevelNum INTEGER NOT NULL,
            $colIsCompleted INTEGER DEFAULT 0,
            $colStars INTEGER DEFAULT 0,
            $colHintsUsed INTEGER DEFAULT 0,
            UNIQUE($colBiomeId, $colPackId, $colLevelNum)
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableLevelProgress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            $colBiomeId INTEGER NOT NULL,
            $colPackId INTEGER NOT NULL,
            $colLevelNum INTEGER NOT NULL,
            $colIsCompleted INTEGER DEFAULT 0,
            $colStars INTEGER DEFAULT 0,
            $colHintsUsed INTEGER DEFAULT 0,
            UNIQUE($colBiomeId, $colPackId, $colLevelNum)
          )
        ''');
      } catch (e) {
        // Table might already exist
      }
    }
    if (oldVersion < 5) {
      // Catch users who upgraded to v4 while the migration was accidentally in _onCreate
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableLevelProgress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            $colBiomeId INTEGER NOT NULL,
            $colPackId INTEGER NOT NULL,
            $colLevelNum INTEGER NOT NULL,
            $colIsCompleted INTEGER DEFAULT 0,
            $colStars INTEGER DEFAULT 0,
            $colHintsUsed INTEGER DEFAULT 0,
            UNIQUE($colBiomeId, $colPackId, $colLevelNum)
          )
        ''');
      } catch (e) {
        // Table might already exist
      }
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUser (
        $colId INTEGER PRIMARY KEY,
        $colBrainSize INTEGER DEFAULT 0,
        $colTotalScore INTEGER DEFAULT 0,
        $colHintsRegular INTEGER DEFAULT 5,
        $colHintsMega INTEGER DEFAULT 0,
        $colHintsUltra INTEGER DEFAULT 0,
        $colDailyStreak INTEGER DEFAULT 0,
        $colLastPlayed TEXT,
        $colSound INTEGER DEFAULT 1,
        $colHaptics INTEGER DEFAULT 1,
        $colAdsRemoved INTEGER DEFAULT 0,
        $colWordsFound INTEGER DEFAULT 0,
        $colLevelsCompleted INTEGER DEFAULT 0,
        $colHintsUsedTotal INTEGER DEFAULT 0,
        $colClaimedAchievements TEXT DEFAULT '',
        $colCoins INTEGER DEFAULT 0,
        $colVillageBuildings TEXT DEFAULT '{}'
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableLevelProgress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $colBiomeId INTEGER NOT NULL,
        $colPackId INTEGER NOT NULL,
        $colLevelNum INTEGER NOT NULL,
        $colIsCompleted INTEGER DEFAULT 0,
        $colStars INTEGER DEFAULT 0,
        $colHintsUsed INTEGER DEFAULT 0,
        UNIQUE($colBiomeId, $colPackId, $colLevelNum)
      )
    ''');

    await db.insert(tableUser, {colId: 1, colHintsRegular: 5});
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      tableUser,
      where: '$colId = ?',
      whereArgs: [1],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateUserProfile(Map<String, dynamic> row) async {
    try {
      Database db = await instance.database;
      int count = await db.update(tableUser, row, where: '$colId = ?', whereArgs: [1]);
      if (count == 0) {
        Map<String, dynamic> insertRow = Map<String, dynamic>.from(row);
        insertRow[colId] = 1;
        return await db.insert(tableUser, insertRow, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return count;
    } catch (e) {
      debugPrint('Error updating user profile in DB: $e');
      return 0;
    }
  }

  Future<int> saveLevelProgress(Map<String, dynamic> row) async {
    try {
      Database db = await instance.database;
      return await db.insert(
        tableLevelProgress,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving level progress in DB: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllLevelProgress() async {
    Database db = await instance.database;
    return await db.query(tableLevelProgress);
  }
}
