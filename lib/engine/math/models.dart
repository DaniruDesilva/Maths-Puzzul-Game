enum Op {
  add,
  sub,
  mul,
  div;

  String get symbol {
    switch (this) {
      case Op.add:
        return '+';
      case Op.sub:
        return '-';
      case Op.mul:
        return '×';
      case Op.div:
        return '÷';
    }
  }

  int apply(int a, int b) {
    switch (this) {
      case Op.add:
        return a + b;
      case Op.sub:
        return a - b;
      case Op.mul:
        return a * b;
      case Op.div:
        if (b == 0 || a % b != 0) {
          throw ArgumentError('Invalid integer division: $a / $b');
        }
        return a ~/ b;
    }
  }
}

enum CellKind {
  block,
  number,
  op,
  equals,
}

enum Difficulty {
  easy,
  medium,
  hard,
  expert;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }
}

class MathCell {
  final int row;
  final int col;
  final CellKind kind;
  final Op? op;
  final int? solutionValue;
  final bool isGiven;

  const MathCell({
    required this.row,
    required this.col,
    required this.kind,
    this.op,
    this.solutionValue,
    this.isGiven = false,
  });

  bool get isNumber => kind == CellKind.number;
  bool get isBlank => isNumber && !isGiven;

  MathCell copyWith({
    int? row,
    int? col,
    CellKind? kind,
    Op? op,
    int? solutionValue,
    bool? isGiven,
  }) {
    return MathCell(
      row: row ?? this.row,
      col: col ?? this.col,
      kind: kind ?? this.kind,
      op: op ?? this.op,
      solutionValue: solutionValue ?? this.solutionValue,
      isGiven: isGiven ?? this.isGiven,
    );
  }

  Map<String, dynamic> toJson() => {
        'r': row,
        'c': col,
        'k': kind.name,
        if (op != null) 'op': op!.name,
        if (solutionValue != null) 'val': solutionValue,
        'given': isGiven,
      };

  factory MathCell.fromJson(Map<String, dynamic> json) {
    return MathCell(
      row: json['r'] as int,
      col: json['c'] as int,
      kind: CellKind.values.byName(json['k'] as String),
      op: json['op'] != null ? Op.values.byName(json['op'] as String) : null,
      solutionValue: json['val'] as int?,
      isGiven: json['given'] as bool? ?? false,
    );
  }
}

class MathEquation {
  final int id;
  final List<MathCell> cells;
  final bool isHorizontal;
  final int targetResult;

  const MathEquation({
    required this.id,
    required this.cells,
    required this.isHorizontal,
    required this.targetResult,
  });

  List<MathCell> get numberCells =>
      cells.where((c) => c.kind == CellKind.number).toList();

  List<MathCell> get operandCells {
    final nums = numberCells;
    if (nums.isEmpty) return const [];
    return nums.sublist(0, nums.length - 1);
  }

  MathCell get resultCell => numberCells.last;

  List<Op> get operators => cells
      .where((c) => c.kind == CellKind.op && c.op != null)
      .map((c) => c.op!)
      .toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'horizontal': isHorizontal,
        'target': targetResult,
        'cells': cells.map((c) => {'r': c.row, 'c': c.col}).toList(),
      };
}

class MathPuzzle {
  final int id;
  final int rows;
  final int cols;
  final int seed;
  final Difficulty difficulty;
  final List<List<MathCell>> grid;
  final List<MathEquation> equations;
  final List<int> trayNumbers;

  const MathPuzzle({
    required this.id,
    required this.rows,
    required this.cols,
    required this.seed,
    required this.difficulty,
    required this.grid,
    required this.equations,
    required this.trayNumbers,
  });

  List<MathCell> get blankCells {
    final list = <MathCell>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c].isBlank) {
          list.add(grid[r][c]);
        }
      }
    }
    return list;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rows': rows,
        'cols': cols,
        'seed': seed,
        'difficulty': difficulty.name,
        'tray': trayNumbers,
        'grid': [
          for (final row in grid) [for (final cell in row) cell.toJson()],
        ],
        'equations': equations.map((e) => e.toJson()).toList(),
      };

  factory MathPuzzle.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    final gridJson = json['grid'] as List;

    final grid = List.generate(rows, (r) {
      final rowList = gridJson[r] as List;
      return List.generate(cols, (c) {
        return MathCell.fromJson(rowList[c] as Map<String, dynamic>);
      });
    });

    final eqJson = json['equations'] as List;
    final equations = <MathEquation>[];
    for (final eq in eqJson) {
      final cellCoords = (eq['cells'] as List).cast<Map<String, dynamic>>();
      final cells = cellCoords
          .map((coord) => grid[coord['r'] as int][coord['c'] as int])
          .toList();
      equations.add(MathEquation(
        id: eq['id'] as int,
        cells: cells,
        isHorizontal: eq['horizontal'] as bool,
        targetResult: eq['target'] as int,
      ));
    }

    return MathPuzzle(
      id: json['id'] as int,
      rows: rows,
      cols: cols,
      seed: json['seed'] as int,
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      grid: grid,
      equations: equations,
      trayNumbers: (json['tray'] as List).cast<int>(),
    );
  }

  MathPuzzle copyWith({
    int? id,
    int? rows,
    int? cols,
    int? seed,
    Difficulty? difficulty,
    List<List<MathCell>>? grid,
    List<MathEquation>? equations,
    List<int>? trayNumbers,
  }) {
    return MathPuzzle(
      id: id ?? this.id,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      seed: seed ?? this.seed,
      difficulty: difficulty ?? this.difficulty,
      grid: grid ?? this.grid,
      equations: equations ?? this.equations,
      trayNumbers: trayNumbers ?? this.trayNumbers,
    );
  }
}
