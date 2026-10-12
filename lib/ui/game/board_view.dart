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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Optimal base cell size based on board density
        final double baseCellSize;
        if (puzzle.cols <= 5) {
          baseCellSize = 52.0;
        } else if (puzzle.cols <= 7) {
          baseCellSize = 46.0;
        } else if (puzzle.cols <= 9) {
          baseCellSize = 40.0;
        } else {
          baseCellSize = 36.0; // 11x11 or 13x13 expert boards
        }

        const double cellGap = 3.0;
        const double boardPadding = 8.0;

        // Active equations containing the player's selected cell
        final activeEquationIds = <int>{};
        if (provider.selectedCell != null) {
          final selR = provider.selectedCell!.x;
          final selC = provider.selectedCell!.y;
          for (final eq in puzzle.equations) {
            if (eq.cells.any((c) => c.row == selR && c.col == selC)) {
              activeEquationIds.add(eq.id);
            }
          }
        }

        // Build the core grid board widget
        final gridWidget = Container(
          padding: const EdgeInsets.all(boardPadding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF26190F), // Deep walnut
                Color(0xFF180F09), // Aged dark cedar
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF5D3E24), // Warm carved wood rim
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Color(0x33F59E0B),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(puzzle.rows, (r) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: cellGap / 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(puzzle.cols, (c) {
                    final cell = puzzle.grid[r][c];
                    final isSelected = provider.selectedCell?.x == r && provider.selectedCell?.y == c;
                    final isHintTarget = provider.activeHint?.targetCell.x == r &&
                        provider.activeHint?.targetCell.y == c;

                    // Check equation statuses for this cell
                    bool inViolated = false;
                    bool inSatisfied = false;
                    bool inActive = false;

                    for (final eq in puzzle.equations) {
                      final hasThisCell = eq.cells.any((ec) => ec.row == r && ec.col == c);
                      if (hasThisCell) {
                        if (provider.violatedEquationIds.contains(eq.id)) {
                          inViolated = true;
                        }
                        if (provider.satisfiedEquationIds.contains(eq.id)) {
                          inSatisfied = true;
                        }
                        if (activeEquationIds.contains(eq.id)) {
                          inActive = true;
                        }
                      }
                    }

                    final cellNotes = provider.cellNotes['$r,$c'];
                    final currentValue = provider.currentValues[r][c];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: cellGap / 2),
                      child: BoardCellWidget(
                        cell: cell,
                        currentValue: currentValue,
                        isSelected: isSelected,
                        isHighlightedInHint: isHintTarget,
                        isInActiveEquation: inActive,
                        isInViolatedEquation: inViolated,
                        isInSatisfiedEquation: inSatisfied,
                        notes: cellNotes,
                        size: baseCellSize,
                        onTap: () => provider.selectCell(r, c),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );

        // For massive expert puzzles (11+ cols or 11+ rows):
        // Allow smooth zoom and pan without ANY constraint clipping
        final isMassiveBoard = puzzle.cols >= 11 || puzzle.rows >= 11;

        if (isMassiveBoard) {
          return ClipRect(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.65,
              maxScale: 2.5,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: gridWidget,
              ),
            ),
          );
        }

        // For standard boards (5x5, 5x7, 7x7, 9x7):
        // FittedBox guarantees perfect proportional scaling to fit available space
        // with ZERO RenderFlex overflow on ANY screen size!
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: gridWidget,
            ),
          ),
        );
      },
    );
  }
}
