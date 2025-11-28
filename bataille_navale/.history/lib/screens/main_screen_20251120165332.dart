import 'package:flutter/material.dart';
import '../models/index.dart';
import 'index.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final String playerId = 'player_123';
  final String playerName = 'Champion';

  void _startGameVsAI() {
    // Créer une partie contre l'IA
    final player1 = Player(
      id: playerId,
      name: playerName,
      email: 'player@example.com',
      createdAt: DateTime.now(),
    );
    final player2 = Player(
      id: 'ai_bot',
      name: 'IA Expert',
      email: 'ai@example.com',
      createdAt: DateTime.now(),
    );
    
    final gameId = 'game_ai_${DateTime.now().millisecondsSinceEpoch}';
    final mainScreenContext = context;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacementScreen(
          playerId: playerId,
          gameId: gameId,
          onPlacementComplete: (playerBoard) {
            try {
              // Créer le jeu avec le plateau du joueur
              final game = Game(
                id: gameId,
                player1: player1,
                player2: player2,
                board1: playerBoard,
                board2: Board.empty(isVisible: false),
                moves: [],
                currentTurnPlayerId: playerId,
                status: GameStatus.playing,
                createdAt: DateTime.now(),
                player2IsAI: true,
              );

              print('✓ Jeu créé: $gameId, board1 ships: ${game.board1.ships.length}');

              Navigator.of(mainScreenContext).pop();
              Navigator.of(mainScreenContext).push(
                MaterialPageRoute(
                  builder: (context) => GameScreen(game: game),
                ),
              );
            } catch (e) {
              print('❌ Erreur création jeu: $e');
              Navigator.of(mainScreenContext).pop();
              ScaffoldMessenger.of(mainScreenContext).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  void _startLocalGame() {
    // Créer une partie locale avec placement pour les deux joueurs
    final player1 = Player(
      id: playerId,
      name: playerName,
      email: 'player@example.com',
      createdAt: DateTime.now(),
    );
    final player2 = Player(
      id: 'player_2',
      name: 'Joueur 2',
      email: 'player2@example.com',
      createdAt: DateTime.now(),
    );
    
    final gameId = 'game_local_${DateTime.now().millisecondsSinceEpoch}';
    final mainScreenContext = context;

    // Afficher un dialog pour le joueur 1
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Joueur 1'),
        content: Text('${player1.name}, c\'est à toi de placer tes bateaux!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aller au placement screen pour joueur 1
              Navigator.push(
                mainScreenContext,
                MaterialPageRoute(
                  builder: (context) => PlacementScreen(
                    playerId: player1.id,
                    gameId: gameId,
                    onPlacementComplete: (board1) {
                      try {
                        // Maintenant afficher le dialog pour joueur 2
                        showDialog(
                          context: mainScreenContext,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            title: Text('Joueur 2'),
                            content: Text('${player2.name}, c\'est à toi de placer tes bateaux!'),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Aller au placement screen pour joueur 2
                                  Navigator.push(
                                    mainScreenContext,
                                    MaterialPageRoute(
                                      builder: (context) => PlacementScreen(
                                        playerId: player2.id,
                                        gameId: gameId,
                                        onPlacementComplete: (board2) {
                                          try {
                                            // Créer le jeu avec les deux plateaux
                                            final game = Game(
                                              id: gameId,
                                              player1: player1,
                                              player2: player2,
                                              board1: board1,
                                              board2: board2,
                                              moves: [],
                                              currentTurnPlayerId: player1.id,
                                              status: GameStatus.playing,
                                              createdAt: DateTime.now(),
                                            );

                                            print('✓ Jeu local créé: $gameId');
                                            print('  - Board1 ships: ${board1.ships.length}');
                                            print('  - Board2 ships: ${board2.ships.length}');

                                            Navigator.of(mainScreenContext).pop();
                                            Navigator.of(mainScreenContext).push(
                                              MaterialPageRoute(
                                                builder: (context) => GameScreen(game: game),
                                              ),
                                            );
                                          } catch (e) {
                                            print('❌ Erreur création jeu: $e');
                                            Navigator.of(mainScreenContext).pop();
                                            ScaffoldMessenger.of(mainScreenContext).showSnackBar(
                                              SnackBar(content: Text('Erreur: $e')),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Placer mes bateaux'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        print('❌ Erreur placement joueur 1: $e');
                        Navigator.of(mainScreenContext).pop();
                      }
                    },
                  ),
                ),
              );
            },
            child: Text('Placer mes bateaux'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_boat, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text('Bataille Navale'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête bienvenue
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Bienvenue, $playerName!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Préparez-vous pour l\'affrontement',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Section Parties
              Row(
                children: [
                  Icon(Icons.games, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Parties',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildGameModeCard(
                title: 'Nouvelle partie vs IA',
                description: 'Affrontez l\'algorithme génétique',
                icon: Icons.smart_toy,
                color: Colors.orange,
                onPressed: () {
                  // Créer une partie contre l'IA
                  _startGameVsAI();
                },
              ),
              SizedBox(height: 12),
              _buildGameModeCard(
                title: 'Partie 1v1 locale',
                description: 'Affrontez un ami',
                icon: Icons.people,
                color: Colors.purple,
                onPressed: () {
                  // Créer une partie locale
                  _startLocalGame();
                },
              ),
              SizedBox(height: 12),
              _buildGameModeCard(
                title: 'Partie en ligne',
                description: 'Matchmaking automatique',
                icon: Icons.cloud,
                color: Colors.green,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LobbyScreen(
                        playerId: playerId,
                        playerName: playerName,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              _buildGameModeCard(
                title: 'Simulateur de parties',
                description: 'Simuler n parties automatiquement',
                icon: Icons.auto_stories,
                color: Colors.red,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SimulationScreen(
                        playerId: playerId,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              
              // Section Infos joueur
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mon profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildProfileCard(),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickButton(
                      label: 'Statistiques',
                      icon: Icons.bar_chart,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StatsScreen(
                              playerId: playerId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickButton(
                      label: 'Leaderboard',
                      icon: Icons.leaderboard,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Leaderboard - À venir')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blue.shade700,
              child: Text(
                playerName[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Classement: À déterminer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
