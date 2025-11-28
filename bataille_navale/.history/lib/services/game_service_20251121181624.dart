import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/index.dart';

class GameService {
  static const int boardSize = 10;
  final Random _random = Random();
  GameService();

  // ============ GAME INITIALIZATION ============

  /// Crée une nouvelle partie
  Game createGame(Player player1, Player player2, {bool player2IsAI = false}) {
    final gameId = const Uuid().v4();
    return Game(
      id: gameId,
      player1: player1,
      player2: player2,
      board1: Board.empty(isVisible: true),
      board2: Board.empty(isVisible: false),
      moves: [],
      currentTurnPlayerId: player1.id,
      status: GameStatus.setup,
      createdAt: DateTime.now(),
      player1IsAI: false,
      player2IsAI: player2IsAI,
    );
  }

  // ============ SHIP PLACEMENT ============

  /// Valide le placement d'un navire
  bool canPlaceShip(
    Board board,
    int startRow,
    int startCol,
    ShipType type,
    bool isVertical,
  ) {
    final shipSize = type.size;

    // Vérifier les limites
    if (isVertical) {
      if (startRow + shipSize > boardSize) return false;
    } else {
      if (startCol + shipSize > boardSize) return false;
    }

    // Vérifier les collisions
    for (int i = 0; i < shipSize; i++) {
      final row = isVertical ? startRow + i : startRow;
      final col = isVertical ? startCol : startCol + i;

      if (board.hasShip(row, col)) return false;

      // Vérifier les cellules adjacentes avec vérification des limites
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final checkRow = row + dr;
          final checkCol = col + dc;
          if (checkRow >= 0 && checkRow < boardSize && 
              checkCol >= 0 && checkCol < boardSize) {
            if (board.hasShip(checkRow, checkCol)) return false;
          }
        }
      }
    }

    return true;
  }

  /// Place un navire sur le plateau
  Board placeShip(
    Board board,
    int startRow,
    int startCol,
    ShipType type,
    bool isVertical,
  ) {
    if (!canPlaceShip(board, startRow, startCol, type, isVertical)) {
      throw ArgumentError('Placement de navire invalide');
    }

    final cells = <(int, int)>[];
    final shipSize = type.size;

    for (int i = 0; i < shipSize; i++) {
      final row = isVertical ? startRow + i : startRow;
      final col = isVertical ? startCol : startCol + i;
      cells.add((row, col));
    }

    final ship = Ship(
      id: const Uuid().v4(),
      type: type,
      cells: cells,
      isVertical: isVertical,
    );

    // Ajouter le ship au board
    var updatedBoard = board.addShip(ship);

    // Mettre à jour les states des cells pour afficher les navires
    for (final (row, col) in cells) {
      updatedBoard = updatedBoard.updateCell(row, col, CellState.ship);
    }

    return updatedBoard;
  }

  /// Génère un placement aléatoire de tous les navires
  Board generateRandomShipPlacement() {
    var board = Board.empty();
    final shipTypes = ShipType.values;

    for (final shipType in shipTypes) {
      bool placed = false;
      int attempts = 0;

      while (!placed && attempts < 100) {
        final isVertical = _random.nextBool();
        final startRow = _random.nextInt(boardSize);
        final startCol = _random.nextInt(boardSize);

        if (canPlaceShip(board, startRow, startCol, shipType, isVertical)) {
          board = placeShip(board, startRow, startCol, shipType, isVertical);
          placed = true;
        }

        attempts++;
      }

      if (!placed) throw Exception('Impossible de générer le placement');
    }

    return board;
  }

  // ============ GAME MOVES ============

  /// Traite un coup
  (MoveResult result, Game updatedGame) processMove(
    Game game,
    int row,
    int col,
  ) {
    if (game.status != GameStatus.playing) {
      throw StateError('La partie n\'est pas en cours');
    }

    // Vérifier que la cellule n'a pas déjà été attaquée
    final currentBoard = game.currentPlayerBoard;
    final cell = currentBoard.getCell(row, col);

    print('🎯 Vérification coup ($row, $col):');
    print('   isPlayer1Turn: ${game.isPlayer1Turn}');
    print('   currentPlayerBoard == board2: ${identical(currentBoard, game.board2)}');
    print('   currentPlayerBoard == board1: ${identical(currentBoard, game.board1)}');
    print('   Cell state: ${cell.state}');

    if (cell.state != CellState.empty) {
      print('   ❌ Rejet: cellule déjà attaquée');
      throw ArgumentError('Cette cellule a déjà été attaquée');
    }
    print('   ✅ Cellule valide');

    // Déterminer le résultat
    MoveResult result;
    Board updatedBoard = currentBoard;

    if (game.currentPlayerBoard.hasShip(row, col)) {
      // Touché
      final ship = game.currentPlayerBoard.getShipAt(row, col);
      if (ship != null) {
        final updatedShip = ship.copyWith(hits: ship.hits + 1);

        // Mettre à jour la cellule ET le navire
        updatedBoard = currentBoard
            .updateCell(row, col, CellState.hit)
            .updateShip(updatedShip);

        if (updatedShip.isSunk) {
          result = MoveResult.sunk;
          print('💥 Navire coulé! ${updatedShip.type} avec ${updatedShip.hits} hits');
        } else {
          result = MoveResult.hit;
          print('✓ Touché! Ship has ${updatedShip.hits} hits now');
        }
      } else {
        result = MoveResult.miss;
      }
    } else {
      // Manqué
      updatedBoard = currentBoard.updateCell(row, col, CellState.miss);
      result = MoveResult.miss;
    }

    // Créer le coup
    final move = Move(
      id: const Uuid().v4(),
      row: row,
      col: col,
      result: result,
      timestamp: DateTime.now(),
      playerId: game.currentPlayer.id,
    );

    // Vérifier si la partie est terminée
    bool isGameOver = false;
    String? winnerId;

    final targetBoard = game.isPlayer1Turn ? game.board2 : game.board1;
    if (targetBoard.allShipsSunk) {
      isGameOver = true;
      winnerId = game.currentPlayer.id;
    }

    // Mettre à jour le jeu
    Game updatedGame = game.copyWith(
      board1: !game.isPlayer1Turn ? updatedBoard : game.board1,  // Si c'est le tour de J2 (IA), update board1
      board2: game.isPlayer1Turn ? updatedBoard : game.board2,   // Si c'est le tour de J1, update board2
      moves: [...game.moves, move],
      currentTurnPlayerId:
          isGameOver ? game.currentPlayer.id : game.opponent.id,
      status: isGameOver ? GameStatus.finished : GameStatus.playing,
      winnerId: winnerId,
      finishedAt: isGameOver ? DateTime.now() : null,
    );

    return (result, updatedGame);
  }

  // ============ GAME ANALYSIS ============

  /// Calcule les stats d'une partie
  GameStatistics calculateGameStatistics(
    Game game,
    String playerId,
  ) {
    final playerMoves = game.moves.where((m) => m.playerId == playerId).toList();
    final hits = playerMoves
        .where((m) => m.result == MoveResult.hit || m.result == MoveResult.sunk)
        .length;
    final misses = playerMoves.where((m) => m.result == MoveResult.miss).length;

    final hitPositions = playerMoves
        .where((m) => m.result == MoveResult.hit || m.result == MoveResult.sunk)
        .map((m) => (m.row, m.col))
        .toList();

    final missPositions = playerMoves
        .where((m) => m.result == MoveResult.miss)
        .map((m) => (m.row, m.col))
        .toList();

    final opponent = game.player1.id == playerId ? game.player2 : game.player1;
    final won = game.winnerId == playerId;
    final shipsDestroyed =
        won ? (game.player1.id == playerId ? game.board2 : game.board1).sunkShips : 0;

    final duration = game.finishedAt != null
        ? game.finishedAt!.difference(game.createdAt)
        : Duration.zero;

    final accuracy = playerMoves.isEmpty
        ? 0.0
        : (hits / playerMoves.length) * 100;

    return GameStatistics(
      gameId: game.id,
      playerId: playerId,
      opponentId: opponent.id,
      totalMoves: playerMoves.length,
      hits: hits,
      misses: misses,
      hitPositions: hitPositions,
      missPositions: missPositions,
      gameDuration: duration,
      recordedAt: DateTime.now(),
      won: won,
      shipsDestroyed: shipsDestroyed,
      accuracy: accuracy,
    );
  }

  /// Génère une heatmap 10x10 des coups
  List<int> generateHeatmap(List<GameStatistics> gameStats) {
    final heatmap = List<int>.filled(100, 0);

    for (final stat in gameStats) {
      for (final pos in stat.hitPositions) {
        final index = pos.$1 * 10 + pos.$2;
        heatmap[index]++;
      }
    }

    return heatmap;
  }

  /// Analyse les patterns de jeu
  Map<String, dynamic> analyzePlayerPatterns(List<GameStatistics> gameStats) {
    int cornerHits = 0;
    int edgeHits = 0;
    int centerHits = 0;

    for (final stat in gameStats) {
      for (final pos in stat.hitPositions) {
        final row = pos.$1;
        final col = pos.$2;

        // Coin (0-2 et 7-9)
        if ((row <= 2 || row >= 7) && (col <= 2 || col >= 7)) {
          cornerHits++;
        }
        // Bord
        else if (row <= 2 || row >= 7 || col <= 2 || col >= 7) {
          edgeHits++;
        }
        // Centre
        else {
          centerHits++;
        }
      }
    }

    return {
      'corner_hits': cornerHits,
      'edge_hits': edgeHits,
      'center_hits': centerHits,
      'total_analyzed': gameStats.fold<int>(
        0,
        (sum, stat) => sum + stat.hits,
      ),
    };
  }
}
