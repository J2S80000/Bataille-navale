import 'package:bataille_navale/bataille_navale.dart';
import 'package:test/test.dart';
import 'dart:math';

void main() {
  group('GameService Tests', () {
    late GameService gameService;

    setUp(() {
      gameService = GameService();
    });

    test('Ship placement validation', () {
      var board = Board.empty();

      // Placement valide
      expect(
        gameService.canPlaceShip(
          board,
          0,
          0,
          ShipType.carrier,
          false,
        ),
        true,
      );

      // Placement invalide (hors limites)
      expect(
        gameService.canPlaceShip(
          board,
          9,
          6,
          ShipType.carrier,
          false,
        ),
        false,
      );
    });

    test('Random ship placement generates valid board', () {
      final board = gameService.generateRandomShipPlacement();

      expect(board.ships.length, 5);
      expect(board.ships[0].type, ShipType.carrier);

      // Vérifier qu'aucun navire se chevauche
      for (int i = 0; i < board.ships.length; i++) {
        for (int j = i + 1; j < board.ships.length; j++) {
          final ship1 = board.ships[i];
          final ship2 = board.ships[j];

          final intersection = ship1.cells
              .where((cell) => ship2.cells.contains(cell))
              .toList();

          expect(intersection.isEmpty, true);
        }
      }
    });

    test('Move processing - hit', () {
      var board1 = Board.empty();
      var board2 = Board.empty();

      // Placer un navire sur board1
      board1 = gameService.placeShip(
        board1,
        0,
        0,
        ShipType.destroyer,
        false,
      );

      final player1 = Player(
        id: 'player1',
        name: 'Alice',
        email: 'alice@example.com',
        createdAt: DateTime.now(),
      );

      final player2 = Player(
        id: 'player2',
        name: 'Bob',
        email: 'bob@example.com',
        createdAt: DateTime.now(),
      );

      var game = gameService.createGame(player1, player2);
      game = game.copyWith(
        board1: board1,
        board2: board2,
        status: GameStatus.playing,
      );

      // Tirer sur le navire
      final (result, updatedGame) = gameService.processMove(game, 0, 0);

      expect(result, MoveResult.hit);
      expect(updatedGame.moves.length, 1);
    });

    test('Game win condition', () {
      var board1 = Board.empty();
      board1 = gameService.placeShip(
        board1,
        0,
        0,
        ShipType.carrier,
        true,
      );

      final player1 = Player(
        id: 'p1',
        name: 'Alice',
        email: 'alice@example.com',
        createdAt: DateTime.now(),
      );

      final player2 = Player(
        id: 'p2',
        name: 'Bob',
        email: 'bob@example.com',
        createdAt: DateTime.now(),
      );

      var game = gameService.createGame(player1, player2);
      game = game.copyWith(
        board1: board1,
        board2: Board.empty(),
        status: GameStatus.playing,
      );

      // Couler tous les navires
      for (int i = 0; i < 5; i++) {
        final (_, updatedGame) = gameService.processMove(game, i, 0);
        game = updatedGame;
      }

      expect(game.status, GameStatus.finished);
      expect(game.winnerId, isNotNull);
    });
  });

  group('GameStatistics Tests', () {
    test('Statistics calculation', () {
      final gameService = GameService();
      final player1 = Player(
        id: 'p1',
        name: 'Alice',
        email: 'alice@example.com',
        createdAt: DateTime.now(),
      );

      final player2 = Player(
        id: 'p2',
        name: 'Bob',
        email: 'bob@example.com',
        createdAt: DateTime.now(),
      );

      var game = gameService.createGame(player1, player2);
      game = game.copyWith(
        board1: gameService.generateRandomShipPlacement(),
        board2: gameService.generateRandomShipPlacement(),
        status: GameStatus.playing,
      );

      // Ajouter quelques coups
      final move1 = Move(
        id: 'move1',
        row: 5,
        col: 5,
        result: MoveResult.hit,
        timestamp: DateTime.now(),
        playerId: player1.id,
      );

      final move2 = Move(
        id: 'move2',
        row: 3,
        col: 3,
        result: MoveResult.miss,
        timestamp: DateTime.now(),
        playerId: player1.id,
      );

      game = game.copyWith(moves: [move1, move2]);

      final stats = gameService.calculateGameStatistics(game, player1.id);

      expect(stats.totalMoves, 2);
      expect(stats.hits, 1);
      expect(stats.misses, 1);
      expect(stats.accuracy, 50.0);
    });
  });

  group('Genetic Algorithm Tests', () {
    test('Strategy mutation', () {
      final random = Random();
      final strategy = AIStrategy.random(random);
      final original = strategy.weights;

      final mutated = strategy.mutate(random);

      // Les poids doivent être différents (au moins un)
      expect(mutated.weights != original, true);
    });

    test('Strategy crossover', () {
      final random = Random();
      final parent1 = AIStrategy(
        weights: [0.1, 0.2, 0.3, 0.4, 0.5],
        id: 'p1',
      );
      final parent2 = AIStrategy(
        weights: [0.9, 0.8, 0.7, 0.6, 0.5],
        id: 'p2',
      );

      final child = AIStrategy.crossover(parent1, parent2, random);

      // L'enfant doit avoir des poids de l'un ou l'autre parent
      for (int i = 0; i < child.weights.length; i++) {
        expect(
          child.weights[i] == parent1.weights[i] ||
              child.weights[i] == parent2.weights[i],
          true,
        );
      }
    });

    test('Genetic algorithm evolution', () {
      final ga = GeneticAlgorithm(
        populationSize: 10,
        generations: 5,
      );

      // Données de test
      final testStats = [
        GameStatistics(
          gameId: 'g1',
          playerId: 'p1',
          opponentId: 'p2',
          totalMoves: 20,
          hits: 15,
          misses: 5,
          hitPositions: [(1, 1), (2, 2), (3, 3)],
          missPositions: [(0, 0), (1, 0)],
          playerShipPositions: [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)],
          opponentShipPositions: [(5, 5), (6, 6), (7, 7), (8, 8), (9, 9)],
          gameDuration: Duration(minutes: 5),
          recordedAt: DateTime.now(),
          won: true,
          shipsDestroyed: 5,
          accuracy: 75.0,
        ),
      ];

      ga.train(testStats);

      final best = ga.getBestStrategy();
      expect(best.fitness > 0, true);
      expect(ga.getFitnessHistory().length, 5);
    });
  });

  group('Serialization Tests', () {
    test('Player serialization', () {
      final player = Player(
        id: 'user123',
        name: 'Alice',
        email: 'alice@example.com',
        wins: 10,
        losses: 5,
        gamesPlayed: 15,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = player.toJson();
      final restored = Player.fromJson(json);

      expect(restored.id, player.id);
      expect(restored.name, player.name);
      expect(restored.wins, player.wins);
    });

    test('Move serialization', () {
      final move = Move(
        id: 'move1',
        row: 5,
        col: 3,
        result: MoveResult.hit,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        playerId: 'player1',
      );

      final json = move.toJson();
      final restored = Move.fromJson(json);

      expect(restored.row, 5);
      expect(restored.col, 3);
      expect(restored.result, MoveResult.hit);
    });

    test('Board serialization', () {
      final gameService = GameService();
      var board = Board.empty();
      board = gameService.placeShip(
        board,
        0,
        0,
        ShipType.destroyer,
        false,
      );

      final json = board.toJson();
      final restored = Board.fromJson(json);

      expect(restored.ships.length, 1);
      expect(restored.ships[0].type, ShipType.destroyer);
    });
  });
}
