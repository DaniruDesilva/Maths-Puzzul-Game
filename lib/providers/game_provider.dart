import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../engine/level_engine.dart';
import '../data/level_data.dart';
import '../data/word_dictionary.dart';
import '../services/sound_service.dart';

enum WordStatus { none, correct, wrong, partial, bonus, alreadyFound }

class GameProvider extends ChangeNotifier {
  LevelEngine? engine;
  List<String> remainingWords = [];
  List<String> foundWords = [];
  List<String> bonusWordsList = [];
  List<HexCell> selectedCells = [];
  List<HexCell> lastSelectedCells = [];
  bool isLevelComplete = false;
  bool isLoading = false;
  int hintsUsedInLevel = 0;
  int comboCount = 0;
  int currentLevel = 1;
  int score = 0;
  int bonusWordsFound = 0;
  DateTime? lastWordTime;
  String currentWord = '';
  WordStatus lastWordStatus = WordStatus.none;
  bool isDailyChallenge = false;
  bool isCustomPuzzle = false;
  bool levelProgressSaved = false;

  VoidCallback? onWordFoundCallback;
  void Function(String word)? onBonusWordCallback;
  VoidCallback? onLevelCompleteCallback;

  int calculateStars() {
    if (hintsUsedInLevel == 0) return 3;
    if (hintsUsedInLevel <= 2) return 2;
    return 1;
  }

  /// Short floating message (e.g. "BONUS +20", "ALREADY FOUND").
  String? feedbackMessage;
  int _feedbackToken = 0;

  void showFeedback(String message, {int durationMs = 1200}) {
    feedbackMessage = message;
    final token = ++_feedbackToken;
    notifyListeners();
    Future.delayed(Duration(milliseconds: durationMs), () {
      if (token == _feedbackToken) {
        feedbackMessage = null;
        notifyListeners();
      }
    });
  }

  // Use the 280 generated levels
  late List<Map<String, dynamic>> levels;

  GameProvider() {
    levels = LevelData.generateAllLevels();
    _init();
  }

  void _init() {
    _startCurrentLevel();
  }

  void _startCurrentLevel() {
    if (isCustomPuzzle) return;
    
    int levelIndex = (currentLevel - 1) % levels.length;
    var levelData = levels[levelIndex];
    int biomeId = levelData['biome'] as int? ?? 1;
    SoundService.playBiomeAmbience(biomeId);
    
    startLevel(
      levelData['cols'] as int,
      levelData['rows'] as int,
      List<String>.from(levelData['words'] as List),
    );
  }

  void startSpecificLevel(int level) {
    currentLevel = level;
    isCustomPuzzle = false;
    isDailyChallenge = false;
    _startCurrentLevel();
  }

  void startCustomLevel(List<String> customWords) {
    isCustomPuzzle = true;
    isDailyChallenge = false;
    
    int totalLetters = customWords.join('').length;
    
    int cols = 6;
    int rows = 6;
    
    if (totalLetters > 40) {
      cols = 9;
      rows = 9;
    } else if (totalLetters > 25) {
      cols = 8;
      rows = 8;
    } else if (totalLetters > 15) {
      cols = 7;
      rows = 7;
    }
    
    startLevel(cols, rows, customWords);
  }

  String get currentTheme {
    if (isCustomPuzzle) return 'Custom Puzzle';
    if (isDailyChallenge) return 'Daily Challenge';
    
    int levelIndex = (currentLevel - 1) % levels.length;
    int biomeId = levels[levelIndex]['biome'] as int;
    switch (biomeId) {
      case 1: return 'Oakheart Village';
      case 2: return 'Tidepool Harbor';
      case 3: return 'Elderwood Grove';
      case 4: return 'Frostfall Summit';
      case 5: return 'Cinderforge Keep';
      case 6: return 'Starlight Nexus';
      case 7: return 'The Silent Abyss';
      default: return 'Unknown';
    }
  }

  void startLevel(int cols, int rows, List<String> words) {
    engine = LevelEngine(cols: cols, rows: rows, words: words);
    remainingWords = List.from(words.map((w) => w.toUpperCase()));
    foundWords.clear();
    bonusWordsList.clear();
    isLevelComplete = false;
    isLoading = false;
    selectedCells.clear();
    lastSelectedCells.clear();
    comboCount = 0;
    hintsUsedInLevel = 0;
    currentWord = '';
    score = 0;
    bonusWordsFound = 0;
    feedbackMessage = null;
    lastWordStatus = WordStatus.none;
    levelProgressSaved = false;
    notifyListeners();
  }

  void startDailyChallenge() {
    isDailyChallenge = true;
    isLoading = true;
    notifyListeners();
    
    var levelData = LevelData.generateDailyChallenge();
    startLevel(
      levelData['cols'] as int,
      levelData['rows'] as int,
      List<String>.from(levelData['words'] as List),
    );
    
    isLoading = false;
    notifyListeners();
  }

  void selectCell(int q, int r) {
    if (engine == null) return;
    if (q < 0 || q >= engine!.cols || r < 0 || r >= engine!.rows) return;
    HexCell cell = engine!.grid[q][r];
    if (cell.isFound) return;
    if (cell.letter == ' ') return;

    // Check if already selected (allow deselect last)
    if (selectedCells.isNotEmpty && selectedCells.last == cell) return;
    if (selectedCells.contains(cell)) return;

    // Check adjacency
    if (selectedCells.isEmpty) {
      selectedCells.add(cell);
      _triggerHaptic();
      SoundService.playThwack();
    } else {
      HexCell last = selectedCells.last;
      List<HexCell> neighbors = engine!.getNeighbors(last.q, last.r);
      if (neighbors.any((n) => n.q == cell.q && n.r == cell.r)) {
        selectedCells.add(cell);
        _triggerHaptic();
        SoundService.playThwack();
      } else {
        // Start a new word if tapped non-adjacent cell
        selectedCells.clear();
        selectedCells.add(cell);
        _triggerHaptic();
        SoundService.playThwack();
      }
    }

    currentWord = selectedCells.map((c) => c.letter).join();
    notifyListeners();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void endSelection({VoidCallback? onWordFound, void Function(String word)? onBonusWord, VoidCallback? onLevelComplete}) {
    if (selectedCells.isEmpty || engine == null) return;

    final wordFoundHandler = onWordFound ?? onWordFoundCallback;
    final bonusWordHandler = onBonusWord ?? onBonusWordCallback;
    final levelCompleteHandler = onLevelComplete ?? onLevelCompleteCallback;

    String selected = selectedCells.map((c) => c.letter).join();
    String reversed = selected.split('').reversed.join();

    String? foundWord;
    for (var word in remainingWords) {
      if (word == selected || word == reversed) {
        foundWord = word;
        break;
      }
    }

    if (foundWord != null) {
      wordFoundHandler?.call();
      lastWordStatus = WordStatus.correct;
      remainingWords.remove(foundWord);
      foundWords.add(foundWord);

      _handleCombo();
      score += foundWord.length * 10 * comboCount;
      
      if (comboCount > 1) {
        SoundService.playCombo(comboCount);
      } else {
        SoundService.playSuccess();
      }
      HapticFeedback.heavyImpact();

      for (var cell in selectedCells) {
        cell.isFound = true;
      }

      bool levelFinished = remainingWords.isEmpty;
      if (levelFinished && !levelProgressSaved) {
        levelCompleteHandler?.call();
      }

      // Delay grid collapse so UI can animate success
      Future.delayed(const Duration(milliseconds: 600), () {
        _collapseGrid();
        if (levelFinished) {
          isLevelComplete = true;
          SoundService.stopAmbience();
          SoundService.playLevelComplete();
        }
        notifyListeners();
      });
    } else {
      // Tiles that belong to the (unique) paths of the remaining targets.
      final Map<String, List<HexCell>> targetPaths = {};
      for (final w in remainingWords) {
        final p = _findValidPathForWord(w);
        if (p != null) targetPaths[w] = p;
      }
      final Set<HexCell> targetCells = targetPaths.values.expand((p) => p).toSet();

      // Is the selection the beginning (or end, if traced backwards) of a
      // target's real path? Then the player is on the right track.
      bool onTargetPath = targetPaths.values.any((p) {
        if (selectedCells.length >= p.length) return false;
        bool fromStart = true, fromEnd = true;
        for (int i = 0; i < selectedCells.length; i++) {
          if (selectedCells[i] != p[i]) fromStart = false;
          if (selectedCells[i] != p[p.length - 1 - i]) fromEnd = false;
        }
        return fromStart || fromEnd;
      });

      // Bonus word check (full English dictionary)
      String validBonus = '';
      if (selected.length >= 3) {
        if (WordDictionary.instance.contains(selected)) {
          validBonus = selected;
        } else if (WordDictionary.instance.contains(reversed)) {
          validBonus = reversed;
        }
      }
      // A target word (found or not) can never be a bonus word.
      if (foundWords.contains(validBonus) || remainingWords.contains(validBonus)) {
        validBonus = '';
      }

      if (onTargetPath) {
        lastWordStatus = WordStatus.partial;
      } else if (validBonus.isNotEmpty && bonusWordsList.contains(validBonus)) {
        // Already discovered this bonus word - no penalty.
        lastWordStatus = WordStatus.alreadyFound;
        showFeedback('ALREADY FOUND');
      } else if (validBonus.isNotEmpty) {
        lastWordStatus = WordStatus.bonus;
        SoundService.playSuccess();
        int bonusPoints = validBonus.length * 5;
        score += bonusPoints;
        bonusWordsFound++;
        bonusWordsList.add(validBonus);
        showFeedback('BONUS  +$bonusPoints');
        bonusWordHandler?.call(validBonus);

        bool brokeTargetWord = false;
        for (var cell in selectedCells) {
          if (targetCells.contains(cell)) {
            brokeTargetWord = true;
          }
          cell.isFound = true; // Remove all tiles!
        }
        
        Future.delayed(const Duration(milliseconds: 600), () {
          if (brokeTargetWord) {
            shuffleBoard();
          } else {
            _collapseGrid();
          }
          notifyListeners();
        });
      } else if (remainingWords.any((w) => w.startsWith(selected) || w.startsWith(reversed))) {
        lastWordStatus = WordStatus.partial;
      } else {
        SoundService.playFailure();
        lastWordStatus = WordStatus.wrong;
        comboCount = 0;
      }
    }

    lastSelectedCells = List.from(selectedCells);
    selectedCells.clear();
    
    // Auto-restore hints if the word was wrong or partial
    if (foundWord == null) {
      var path = _getAvailableHintPath();
      if (path != null) {
        for (var c in path) {
          if (c.isHinted) {
            selectedCells.add(c);
          } else {
            break;
          }
        }
      }
    }
    
    currentWord = selectedCells.map((c) => c.letter).join();
    notifyListeners();
    
    // Reset status after a delay so UI can animate
    Future.delayed(const Duration(milliseconds: 600), () {
      if (lastWordStatus != WordStatus.none) {
        lastWordStatus = WordStatus.none;
        lastSelectedCells.clear();
        notifyListeners();
      }
    });
  }

  void _handleCombo() {
    final now = DateTime.now();
    if (lastWordTime != null && now.difference(lastWordTime!).inSeconds < 5) {
      comboCount++;
    } else {
      comboCount = 1;
    }
    lastWordTime = now;
  }

  void _collapseGrid() {
    if (engine == null) return;

    // Safely clear the found cells so they disappear, BUT only if they are
    // not needed by any remaining word. Hints on surviving tiles are kept,
    // so a hint the player paid for is never lost.
    for (int q = 0; q < engine!.cols; q++) {
      for (int r = 0; r < engine!.rows; r++) {
        if (engine!.grid[q][r].isFound) {
          String originalLetter = engine!.grid[q][r].letter;
          if (originalLetter == ' ') continue; // Already deleted
          
          engine!.grid[q][r].letter = ' '; 
          
          bool usedByOther = false;
          for (String word in remainingWords) {
            if (_findValidPathForWord(word) == null) {
              usedByOther = true;
              break;
            }
          }
          
          if (usedByOther) {
            engine!.grid[q][r].letter = originalLetter;
            engine!.grid[q][r].isFound = false; // Restore it!
          } else {
            engine!.grid[q][r].isHinted = false;
          }
        }
      }
    }
  }

  void shuffleBoard() {
    if (engine == null) return;

    // Remember how many letters of each word were revealed by hints.
    final Map<String, int> hintedCounts = {};
    for (final w in remainingWords) {
      final p = _findValidPathForWord(w);
      if (p == null) continue;
      int n = 0;
      while (n < p.length && p[n].isHinted) {
        n++;
      }
      if (n > 0) hintedCounts[w] = n;
    }
    
    if (engine!.rePlaceWords(remainingWords)) {
      // Re-apply the revealed hint letters on the new board.
      hintedCounts.forEach((w, n) {
        final p = _findValidPathForWord(w);
        if (p == null) return;
        for (int i = 0; i < n && i < p.length; i++) {
          p[i].isHinted = true;
        }
      });

      selectedCells.clear();
      lastSelectedCells.clear();
      currentWord = '';
      lastWordStatus = WordStatus.none;
      notifyListeners();
    }
  }

  void nextLevel() {
    if (!isDailyChallenge && !isCustomPuzzle) {
      currentLevel++;
      _startCurrentLevel();
    }
  }

  void addHintUsed() {
    hintsUsedInLevel++;
    notifyListeners();
  }

  // --- HINT LOGIC ---

  List<HexCell>? _findValidPathForWord(String word) {
    if (engine == null) return null;
    for (int q = 0; q < engine!.cols; q++) {
      for (int r = 0; r < engine!.rows; r++) {
        HexCell startCell = engine!.grid[q][r];
        if (!startCell.isFound && startCell.letter == word[0]) {
          List<HexCell>? path = _dfsFindWord(word, 0, startCell, [startCell]);
          if (path != null) return path;
        }
      }
    }
    // Try reversed word
    String reversed = word.split('').reversed.join();
    for (int q = 0; q < engine!.cols; q++) {
      for (int r = 0; r < engine!.rows; r++) {
        HexCell startCell = engine!.grid[q][r];
        if (!startCell.isFound && startCell.letter == reversed[0]) {
          List<HexCell>? path = _dfsFindWord(reversed, 0, startCell, [startCell]);
          if (path != null) return path;
        }
      }
    }
    return null;
  }

  List<HexCell>? _dfsFindWord(String word, int index, HexCell currentCell, List<HexCell> path) {
    if (index == word.length - 1) return path;
    
    List<HexCell> neighbors = engine!.getNeighbors(currentCell.q, currentCell.r);
    for (var n in neighbors) {
      if (!n.isFound && !path.contains(n) && n.letter == word[index + 1]) {
        path.add(n);
        var result = _dfsFindWord(word, index + 1, n, path);
        if (result != null) return result;
        path.removeLast();
      }
    }
    return null;
  }

  List<HexCell>? _getAvailableHintPath() {
    for (String word in remainingWords) {
      var path = _findValidPathForWord(word);
      if (path != null && path.isNotEmpty) return path;
    }
    return null;
  }

  bool applyHint() {
    if (remainingWords.isEmpty) return false;
    var path = _getAvailableHintPath();
    if (path != null) {
      int hintedLetters = 0;
      for (int i = 0; i < path.length; i++) {
        if (path[i].isHinted) {
          hintedLetters++;
        } else {
          break;
        }
      }

      if (hintedLetters < path.length) {
        selectedCells.clear();
        for (int i = 0; i <= hintedLetters; i++) {
          path[i].isHinted = true;
          selectCell(path[i].q, path[i].r);
        }
        addHintUsed();
        
        // Auto-submit if fully hinted
        if (hintedLetters + 1 == path.length) {
          Future.delayed(const Duration(milliseconds: 150), () {
            endSelection();
          });
        }
        return true;
      }
    }
    return false;
  }

  bool applyMegaHint() {
    if (remainingWords.isEmpty) return false;
    
    // Find a path that doesn't already have its first and last letters hinted
    List<HexCell>? targetPath;
    for (String word in remainingWords) {
      var p = _findValidPathForWord(word);
      if (p != null && p.length > 1) {
        if (!p.first.isHinted || !p.last.isHinted) {
          targetPath = p;
          break;
        }
      }
    }
    
    if (targetPath != null) {
      targetPath.first.isHinted = true;
      targetPath.last.isHinted = true;
      addHintUsed();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool applyUltraHint() {
    if (remainingWords.isEmpty) return false;
    
    // Find a path that isn't fully hinted already
    List<HexCell>? targetPath;
    for (String word in remainingWords) {
      var p = _findValidPathForWord(word);
      if (p != null) {
        bool fullyHinted = true;
        for (var cell in p) {
          if (!cell.isHinted) {
            fullyHinted = false;
            break;
          }
        }
        if (!fullyHinted) {
          targetPath = p;
          break;
        }
      }
    }
    
    if (targetPath != null) {
      selectedCells.clear();
      for (var cell in targetPath) {
        cell.isHinted = true;
        selectCell(cell.q, cell.r);
      }
      addHintUsed();
      // Auto-submit the word
      Future.delayed(const Duration(milliseconds: 150), () {
        endSelection();
      });
      return true;
    }
    return false;
  }
}
