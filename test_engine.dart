// ignore_for_file: avoid_print, unused_local_variable, prefer_final_fields
import 'dart:math';
class HexCell { int q, r; String letter; HexCell(this.q, this.r, {this.letter = ' '}); }
class Engine {
  int cols = 5; int rows = 5; List<List<HexCell>> grid = []; Random _random = Random();
  Engine() { _initGrid(); }
  void _initGrid() { grid = List.generate(cols, (q) => List.generate(rows, (r) => HexCell(q, r))); }
  List<HexCell> getNeighbors(int q, int r) {
    List<HexCell> neighbors = [];
    List<List<int>> dirs = q.isEven ? [[0, -1], [1, -1], [1, 0], [0, 1], [-1, 0], [-1, -1]] : [[0, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0]];
    for (var d in dirs) {
      int nq = q + d[0]; int nr = r + d[1];
      if (nq >= 0 && nq < cols && nr >= 0 && nr < rows) { neighbors.add(grid[nq][nr]); }
    }
    return neighbors;
  }
  bool _tryPlaceWordDFS(String word, int index, int q, int r, Set<String> visited) {
    if (visited.contains('\$q,\$r')) return false;
    if (grid[q][r].letter != ' ') return false;
    if (index == word.length - 1) { grid[q][r].letter = word[index]; return true; }
    visited.add('\$q,\$r'); grid[q][r].letter = word[index];
    List<HexCell> neighbors = getNeighbors(q, r)..shuffle(_random);
    for (var neighbor in neighbors) {
      if (_tryPlaceWordDFS(word, index + 1, neighbor.q, neighbor.r, visited)) return true;
    }
    grid[q][r].letter = ' '; visited.remove('\$q,\$r'); return false;
  }
  bool placeWords(List<String> words) {
    for (int i = 0; i < words.length; i++) {
      String word = words[i]; bool placed = false; int attempts = 0;
      while (!placed && attempts < 500) {
        int startQ = _random.nextInt(cols); int startR = _random.nextInt(rows);
        placed = _tryPlaceWordDFS(word, 0, startQ, startR, <String>{});
        attempts++;
      }
      if (!placed) return false;
    }
    return true;
  }
  int getAttempts(List<String> remaining) {
    int attempts = 0;
    while (attempts < 100000) {
      _initGrid();
      if (placeWords(remaining)) return attempts;
      attempts++;
    }
    return -1;
  }
}
void main() {
  Engine e = Engine();
  int a = e.getAttempts(['SPIDER', 'WHALE', 'PAPER', 'BEAR']);
  print('Attempts needed: \$a');
}
