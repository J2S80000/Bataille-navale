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

    // Créer les boards pour les deux joueurs
    var playerBoard = generateRandomBoard(); // Board du joueur (défense)
    var opponentBoard = generateRandomBoard(); // Board de l'adversaire (cibles)

    int playerHits = 0;
    int playerMisses = 0;
    final hitPositions = <(int, int)>[];
    final missPositions = <(int, int)>[];
    final opponentShipsDestroyed = <(int, int)>[];

    int totalMoves = 0;
    bool gameEnded = false;

    // Capturer les positions initiales des navires du joueur
    final playerShipPositions = <(int, int)>[];
    for (int row = 0; row < Board.size; row++) {
      for (int col = 0; col < Board.size; col++) {
        if (playerBoard.hasShip(row, col)) {
          playerShipPositions.add((row, col));
        }
      }
    }

    // Simulation simple et rapide
    while (!gameEnded && totalMoves < 200) {
      // Joueur attaque le board de l'adversaire
      int row = _random.nextInt(Board.size);
      int col = _random.nextInt(Board.size);

      if (opponentBoard.hasShip(row, col)) {
        playerHits++;
        hitPositions.add((row, col));
        opponentShipsDestroyed.add((row, col));
        
        // Marquer comme touché sur le board de l'adversaire
        final cell = opponentBoard.getCell(row, col);
        if (cell.state == CellState.empty) {
          opponentBoard = opponentBoard.updateCell(row, col, CellState.hit);
        }
      } else {
        playerMisses++;
        missPositions.add((row, col));
        
        // Marquer comme manqué sur le board de l'adversaire
        final cell = opponentBoard.getCell(row, col);
        if (cell.state == CellState.empty) {
          opponentBoard = opponentBoard.updateCell(row, col, CellState.miss);
        }
      }

      // Vérifier si tous les navires de l'adversaire sont coulés
      if (opponentBoard.allShipsSunk) {
        gameEnded = true;
      }

      totalMoves++;
    }

    // Déterminer le gagnant
    final playerWon = opponentBoard.allShipsSunk;
    final totalShots = playerHits + playerMisses;

    // Calculer la durée de manière plus réaliste basée sur les coups réels
    // Plus de coups = partie plus longue (min 5s, max 180s)
    final durationSeconds = (totalShots * 0.5).clamp(5, 180).toInt();

    return GameStatistics(
      gameId: 'sim_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
      playerId: playerId,
      opponentId: opponentId,
      totalMoves: totalShots,
      hits: playerHits,
      misses: playerMisses,
      hitPositions: hitPositions,
      missPositions: missPositions,
      playerShipPositions: playerShipPositions,
      opponentShipPositions: opponentShipsDestroyed,
      gameDuration: Duration(seconds: durationSeconds),
      recordedAt: DateTime.now(),
      won: playerWon,
      shipsDestroyed: opponentShipsDestroyed.length ~/ 2, // Approximation (chaque navire = 2-5 positions)
      accuracy: totalShots > 0 ? (playerHits / totalShots) * 100 : 0,
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
