import 'package:flutter/material.dart';
import '../../providers/game_provider.dart';
import 'board_cell.dart';

class MathBoardView extends StatelessWidget {
  final GameProvider provider;

  const MathBoardView({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final puzzle = provider.currentPuzzle;
    if (puzzle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 24; // 12px padding each side
        final availableHeight = constraints.maxHeight - 16;

        // Determine base cell size to fit cleanly on screen
        final cellWidth = availableWidth / puzzle.cols;
        final cellHeight = availableHeight / puzzle.rows;
        final optimalCellSize = (cellWidth < cellHeight ? cellWidth : cellHeight).clamp(36.0, 56.0);

        final totalGridWidth = puzzle.cols * optimalCellSize + (puzzle.cols - 1) * 4.0;
        final totalGridHeight = puzzle.rows * optimalCellSize + (puzzle.rows - 1) * 4.0;

        final isPannable = totalGridWidth > availableWidth || totalGridHeight > availableHeight;

        final gridWidget = Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(puzzle.rows, (r) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(puzzle.cols, (c) {
                      final cell = puzzle.grid[r][c];
                      final isSelected = provider.selectedCell?.x == r && provider.selectedCell?.y == c;
                      final isHintTarget = provider.activeHint?.targetCell.x == r &&
                          provider.activeHint?.targetCell.y == c;

                      // Check satisfied/violated equations containing this cell
                      bool inViolated = false;
                      bool inSatisfied = false;
                      for (final eq in puzzle.equations) {
                        if (eq.numberCells.any((nc) => nc.row == r && nc.col == c)) {
                          if (provider.violatedEquationIds.contains(eq.id)) {
                            inViolated = true;
                          }
                          if (provider.satisfiedEquationIds.contains(eq.id)) {
                            inSatisfied = true;
                          }
                        }
                      }

                      final cellNotes = provider.cellNotes['$r,$c'];
                      final currentValue = provider.currentValues[r][c];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: BoardCellWidget(
                          cell: cell,
                          currentValue: currentValue,
                          isSelected: isSelected,
                          isHighlightedInHint: isHintTarget,
                          isInViolatedEquation: inViolated,
                          isInSatisfiedEquation: inSatisfied,
                          notes: cellNotes,
                          size: optimalCellSize,
                          onTap: () => provider.selectCell(r, c),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );

        if (!isPannable) {
          return Center(child: SingleChildScrollView(child: gridWidget));
        }

        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(40),
          minScale: 0.6,
          maxScale: 2.5,
          child: Center(child: gridWidget),
        );
      },
    );
  }
}
