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

  /// Simule une partie complète entre deux joueurs avec IA intelligente
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
    
    // Set pour tracker les positions déjà tirées
    final shotPositions = <(int, int)>{};
    
    // Stratégie aléatoire du joueur (varie par partie)
    final strategy = _random.nextInt(4); // 0=random, 1=hunt, 2=grid, 3=intelligent

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

    // Simulation avec IA
    while (!gameEnded && totalMoves < 250) {
      // Joueur attaque le board de l'adversaire
      late (int, int) target;

      // Sélectionner la cible basée sur la stratégie
      if (strategy == 0) {
        // Stratégie 1: Aléatoire pur
        target = _getRandomTarget(shotPositions);
      } else if (strategy == 1) {
        // Stratégie 2: Hunt & Destroy (cherche les navires)
        target = _getHuntTarget(opponentBoard, hitPositions, shotPositions);
      } else if (strategy == 2) {
        // Stratégie 3: Grille (motif systématique)
        target = _getGridTarget(shotPositions);
      } else {
        // Stratégie 4: Intelligente (mélange)
        if (hitPositions.length < 3) {
          target = _getGridTarget(shotPositions);
        } else {
          target = _getHuntTarget(opponentBoard, hitPositions, shotPositions);
        }
      }

      shotPositions.add(target);
      final (row, col) = target;

      if (opponentBoard.hasShip(row, col)) {
        playerHits++;
        hitPositions.add((row, col));
        opponentShipsDestroyed.add((row, col));
        
        // Marquer comme touché
        final cell = opponentBoard.getCell(row, col);
        if (cell.state == CellState.empty) {
          opponentBoard = opponentBoard.updateCell(row, col, CellState.hit);
        }
      } else {
        playerMisses++;
        missPositions.add((row, col));
        
        // Marquer comme manqué
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

    // Durée variable selon la performance
    final durationSeconds = _calculateGameDuration(playerWon, totalShots);

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
      shipsDestroyed: _countDestroyedShips(opponentBoard),
      accuracy: totalShots > 0 ? (playerHits / totalShots) * 100 : 0,
    );
  }

  /// Obtient une cible aléatoire non encore tirée
  static (int, int) _getRandomTarget(Set<(int, int)> shotPositions) {
    late (int, int) target;
    int attempts = 0;
    const maxAttempts = 50;
    
    do {
      target = (_random.nextInt(Board.size), _random.nextInt(Board.size));
      attempts++;
      
      // Si on a trop d'essais, retourner n'importe quelle position
      if (attempts > maxAttempts) {
        for (int r = 0; r < Board.size; r++) {
          for (int c = 0; c < Board.size; c++) {
            if (!shotPositions.contains((r, c))) {
              return (r, c);
            }
          }
        }
        break;
      }
    } while (shotPositions.contains(target));
    
    return target;
  }

  /// Stratégie Hunt & Destroy - cherche autour des hits
  static (int, int) _getHuntTarget(
    Board board,
    List<(int, int)> hitPositions,
    Set<(int, int)> shotPositions,
  ) {
    // 70% de chance de chercher autour d'un hit existant
    if (hitPositions.isNotEmpty && _random.nextDouble() < 0.7) {
      final lastHit = hitPositions.last;
      final directions = [
        (lastHit.$1 - 1, lastHit.$2), // Haut
        (lastHit.$1 + 1, lastHit.$2), // Bas
        (lastHit.$1, lastHit.$2 - 1), // Gauche
        (lastHit.$1, lastHit.$2 + 1), // Droite
      ];

      final validDirections = directions.where((pos) {
        return pos.$1 >= 0 &&
            pos.$1 < Board.size &&
            pos.$2 >= 0 &&
            pos.$2 < Board.size &&
            !shotPositions.contains(pos);
      }).toList();

      if (validDirections.isNotEmpty) {
        return validDirections[_random.nextInt(validDirections.length)];
      }
    }

    return _getRandomTarget(shotPositions);
  }

  /// Stratégie Grille - tire selon un motif régulier
  static (int, int) _getGridTarget(Set<(int, int)> shotPositions) {
    // Utilise un motif en grille (tous les 2-3 carrés)
    late (int, int) target;
    int attempts = 0;
    const maxAttempts = 50;
    
    do {
      final row = _random.nextInt(5) * 2 + _random.nextInt(2);
      final col = _random.nextInt(5) * 2 + _random.nextInt(2);
      target = (row, col);
      attempts++;
      
      // Si on a trop d'essais, tomber sur Random
      if (attempts > maxAttempts) {
        return _getRandomTarget(shotPositions);
      }
    } while (shotPositions.contains(target) || target.$1 >= Board.size || target.$2 >= Board.size);
    
    return target;
  }

  /// Calcule la durée du jeu de manière variable
  static int _calculateGameDuration(bool won, int totalShots) {
    // Durée variable selon le résultat et l'efficacité
    int baseDuration = (totalShots * 0.3).toInt();
    
    if (won) {
      // Si victoire, durée plus courte (joueur efficace)
      baseDuration = ((totalShots * 0.2) + _random.nextInt(15)).toInt();
    } else {
      // Si défaite ou non terminé, durée plus longue
      baseDuration = ((totalShots * 0.4) + _random.nextInt(30)).toInt();
    }
    
    return baseDuration.clamp(5, 180);
  }

  /// Compte le nombre réel de navires détruits
  static int _countDestroyedShips(Board board) {
    int destroyedCount = 0;
    for (final ship in board.ships) {
      if (ship.cells.every((cell) => 
          board.getCell(cell.$1, cell.$2).state == CellState.hit)) {
        destroyedCount++;
      }
    }
    return destroyedCount;
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
