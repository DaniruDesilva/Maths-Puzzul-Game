// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:number_haven/engine/math/models.dart';
import 'package:number_haven/engine/math/puzzle_factory.dart';

void main() async {
  print('--- Number Haven Campaign Generator ---');
  final stopwatch = Stopwatch()..start();

  final levels = <Map<String, dynamic>>[];
  const totalLevels = 280;

  for (int level = 1; level <= totalLevels; level++) {
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

    final puzzle = MathPuzzleFactory.generate(
      id: level,
      seed: 50000 + level * 31,
      difficulty: difficulty,
      maxRetries: 15,
    );

    levels.add(puzzle.toJson());
    if (level % 20 == 0 || level == totalLevels) {
      print('Generated $level / $totalLevels levels (${difficulty.name})');
    }
  }

  final dir = Directory('assets/levels');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final file = File('assets/levels/campaign_v1.json');
  file.writeAsStringSync(jsonEncode(levels));

  stopwatch.stop();
  final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
  print('Successfully saved $totalLevels levels to ${file.path} ($sizeKb KB in ${stopwatch.elapsedMilliseconds}ms)');
}
