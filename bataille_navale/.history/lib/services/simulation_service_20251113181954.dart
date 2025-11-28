import 'dart:math';
import '../models/index.dart';

/// Service de simulation de parties
class SimulationService {
  static final Random _random = Random();

  /// Génère un board aléatoire avec tous les navires placés
  static Board generateRandomBoard() {
    var board = Board.empty();
    final shipTypes = [
      ShipType.carrier,
      ShipType.battleship,
      ShipType.cruiser,
      ShipType.submarine,
      ShipType.destroyer,
    ];

    for (int i = 0; i < shipTypes.length; i++) {
      final shipType = shipTypes[i];
      bool placed = false;
      int attempts = 0;

      while (!placed && attempts < 100) {
        final row = _random.nextInt(Board.size);
        final col = _random.nextInt(Board.size);
        final isVertical = _random.nextBool();

        if (_canPlaceShip(board, row, col, shipType.size, isVertical)) {
          final cells = _generateCells(row, col, shipType.size, isVertical);
          final ship = Ship(
            id: 'ship_${i}_${DateTime.now().millisecondsSinceEpoch}',
            type: shipType,
            cells: cells,
            isVertical: isVertical,
          );
          board = board.addShip(ship);
          placed = true;
        }
        attempts++;
      }
    }

    return board;
  }

  /// Génère les cellules pour un navire
  static List<(int, int)> _generateCells(
    int row,
    int col,
    int size,
    bool isVertical,
  ) {
    final cells = <(int, int)>[];
    for (int i = 0; i < size; i++) {
      if (isVertical) {
        cells.add((row + i, col));
      } else {
        cells.add((row, col + i));
      }
    }
    return cells;
  }

  /// Vérifie si un navire peut être placé
  static bool _canPlaceShip(
    Board board,
    int row,
    int col,
    int size,
    bool isVertical,
  ) {
    if (isVertical) {
      if (row + size > Board.size) return false;
      for (int i = 0; i < size; i++) {
        if (board.hasShip(row + i, col)) return false;
      }
    } else {
      if (col + size > Board.size) return false;
      for (int i = 0; i < size; i++) {
        if (board.hasShip(row, col + i)) return false;
      }
    }
    return true;
  }

  /// Simule une partie complète entre deux joueurs
  static GameStatistics simulateGame({
    required String playerId,
    required String opponentId,
    int? seed,
  }) {
    if (seed != null) {
      // Utiliser la seed pour des tests reproductibles
    }

    var board2 = generateRandomBoard();

    int player1Hits = 0;
    int player1Misses = 0;
    final hitPositions1 = <(int, int)>[];
    final missPositions1 = <(int, int)>[];

    int totalMoves = 0;
    bool gameEnded = false;

    // Simulation simple et rapide
    while (!gameEnded && totalMoves < 200) {
      // Joueur 1 attaque
      int row = _random.nextInt(Board.size);
      int col = _random.nextInt(Board.size);

      if (board2.hasShip(row, col)) {
        player1Hits++;
        hitPositions1.add((row, col));
        
        // Marquer comme touché sur le board
        final cell = board2.getCell(row, col);
        if (cell.state == CellState.empty) {
          board2 = board2.updateCell(row, col, CellState.hit);
        }
      } else {
        player1Misses++;
        missPositions1.add((row, col));
        
        // Marquer comme manqué sur le board
        final cell = board2.getCell(row, col);
        if (cell.state == CellState.empty) {
          board2 = board2.updateCell(row, col, CellState.miss);
        }
      }

      // Vérifier si tous les navires sont coulés
      if (board2.allShipsSunk) {
        gameEnded = true;
      }

      totalMoves++;
    }

    // Déterminer le gagnant
    final player1Won = board2.allShipsSunk;
    final player1Shots = player1Hits + player1Misses;

    return GameStatistics(
      gameId: 'sim_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
      playerId: playerId,
      opponentId: opponentId,
      totalMoves: player1Shots,
      hits: player1Hits,
      misses: player1Misses,
      hitPositions: hitPositions1,
      missPositions: missPositions1,
      gameDuration: Duration(seconds: totalMoves * 2),
      recordedAt: DateTime.now(),
      won: player1Won,
      shipsDestroyed: player1Hits ~/ 2, // Approximation
      accuracy: player1Shots > 0 ? (player1Hits / player1Shots) * 100 : 0,
    );
  }

  /// Simule n parties
  static Future<List<GameStatistics>> simulateGames({
    required int count,
    required String playerId,
    required String opponentId,
    required Function(int, int) onProgress, // (current, total)
  }) async {
    final stats = <GameStatistics>[];

    for (int i = 0; i < count; i++) {
      final gameStat = simulateGame(
        playerId: playerId,
        opponentId: opponentId,
        seed: i, // Seed différente pour chaque partie
      );
      stats.add(gameStat);
      onProgress(i + 1, count);

      // Petit délai pour ne pas bloquer l'interface
      await Future.delayed(Duration(milliseconds: 10));
    }

    return stats;
  }

  /// Calcule les statistiques agrégées
  static PlayerStatisticsAggregate calculateAggregateStats(
    String playerId,
    List<GameStatistics> games,
  ) {
    int totalGames = games.length;
    int totalWins = games.where((g) => g.won).length;
    int totalLosses = totalGames - totalWins;

    double totalAccuracy = 0;
    int totalHits = 0;
    int totalMisses = 0;

    for (final game in games) {
      totalAccuracy += game.accuracy;
      totalHits += game.hits;
      totalMisses += game.misses;
    }

    double averageAccuracy = totalGames > 0 ? totalAccuracy / totalGames : 0;
    double winRate = totalGames > 0 ? (totalWins / totalGames) * 100 : 0;

    return PlayerStatisticsAggregate(
      playerId: playerId,
      totalGames: totalGames,
      totalWins: totalWins,
      totalLosses: totalLosses,
      winRate: winRate,
      averageAccuracy: averageAccuracy,
      totalHits: totalHits,
      totalMisses: totalMisses,
      heatmap: List<int>.filled(100, 0),
      moveTiming: {},
    );
  }
}
