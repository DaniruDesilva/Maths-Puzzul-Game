// ignore_for_file: avoid_print
import 'lib/data/level_data.dart';

void main() {
  final levels = LevelData.generateAllLevels();
  print('Generated ${levels.length} levels successfully.');
}
