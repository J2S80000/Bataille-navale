import 'dart:math';
import '../models/index.dart';

/// Service de simulation de parties
class SimulationService {
  static final Random _random = Random();

  /// Génère un board aléatoire avec tous les navires placés
  static Board generateRandomBoard() {
    final board = Board.empty();
    final ships = [
      Ship(id: 'ship_1', size: 5, name: 'Cuirassé'),
      Ship(id: 'ship_2', size: 4, name: 'Croiseur'),
      Ship(id: 'ship_3', size: 3, name: 'Destroyer'),
      Ship(id: 'ship_4', size: 3, name: 'Sous-marin'),
      Ship(id: 'ship_5', size: 2, name: 'Torpilleur'),
    ];

    for (final ship in ships) {
      bool placed = false;
      while (!placed) {
        final row = _random.nextInt(10);
        final col = _random.nextInt(10);
        final isHorizontal = _random.nextBool();

        if (_canPlaceShip(board, row, col, ship.size, isHorizontal)) {
          _placeShip(board, row, col, ship.size, isHorizontal, ship.id);
          placed = true;
        }
      }
    }

    return board;
  }

  /// Vérifie si un navire peut être placé
  static bool _canPlaceShip(
    Board board,
    int row,
    int col,
    int size,
    bool isHorizontal,
  ) {
    if (isHorizontal) {
      if (col + size > 10) return false;
      for (int i = 0; i < size; i++) {
        if (board.cells[row][col + i].hasShip) return false;
      }
    } else {
      if (row + size > 10) return false;
      for (int i = 0; i < size; i++) {
        if (board.cells[row + i][col].hasShip) return false;
      }
    }
    return true;
  }

  /// Place un navire sur le board
  static void _placeShip(
    Board board,
    int row,
    int col,
    int size,
    bool isHorizontal,
    String shipId,
  ) {
    if (isHorizontal) {
      for (int i = 0; i < size; i++) {
        board.cells[row][col + i] = board.cells[row][col + i].copyWith(
          hasShip: true,
          shipId: shipId,
        );
      }
    } else {
      for (int i = 0; i < size; i++) {
        board.cells[row + i][col] = board.cells[row + i][col].copyWith(
          hasShip: true,
          shipId: shipId,
        );
      }
    }
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

    final board1 = generateRandomBoard();
    final board2 = generateRandomBoard();

    int player1Hits = 0;
    int player1Misses = 0;
    int player2Hits = 0;
    int player2Misses = 0;

    final hitPositions1 = <(int, int)>[];
    final missPositions1 = <(int, int)>[];
    final hitPositions2 = <(int, int)>[];
    final missPositions2 = <(int, int)>[];

    int totalMoves = 0;
    bool player1Turn = true;
    bool gameEnded = false;

    // Simulation stratégique simple
    while (!gameEnded && totalMoves < 200) {
      if (player1Turn) {
        // Joueur 1 attaque
        int row = _random.nextInt(10);
        int col = _random.nextInt(10);

        if (board2.cells[row][col].hasShip) {
          player1Hits++;
          hitPositions1.add((row, col));
          board2.cells[row][col] =
              board2.cells[row][col].copyWith(state: CellState.hit);
        } else {
          player1Misses++;
          missPositions1.add((row, col));
          board2.cells[row][col] =
              board2.cells[row][col].copyWith(state: CellState.miss);
        }

        // Vérifier si tous les navires sont coulés
        if (board2.allShipsSunk) {
          gameEnded = true;
        }
      } else {
        // Joueur 2 attaque
        int row = _random.nextInt(10);
        int col = _random.nextInt(10);

        if (board1.cells[row][col].hasShip) {
          player2Hits++;
          hitPositions2.add((row, col));
          board1.cells[row][col] =
              board1.cells[row][col].copyWith(state: CellState.hit);
        } else {
          player2Misses++;
          missPositions2.add((row, col));
          board1.cells[row][col] =
              board1.cells[row][col].copyWith(state: CellState.miss);
        }

        // Vérifier si tous les navires sont coulés
        if (board1.allShipsSunk) {
          gameEnded = true;
        }
      }

      player1Turn = !player1Turn;
      totalMoves++;
    }

    // Déterminer le gagnant
    final player1Won = board2.allShipsSunk && !board1.allShipsSunk;
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
