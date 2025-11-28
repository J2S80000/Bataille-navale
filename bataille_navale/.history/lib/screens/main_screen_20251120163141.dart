import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';
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
    // Créer une partie factice contre l'IA
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacementScreen(
          playerId: playerId,
          gameId: gameId,
          onPlacementComplete: (playerBoard) {
            // Placer le plateau de l'IA aussi (aléatoirement)
            final gameService = context.read<GameService>();
            Board aiBoard = Board.empty(isVisible: false);
            
            // Placer les bateaux de l'IA aléatoirement
            for (final ship in ShipType.values) {
              bool placed = false;
              int attempts = 0;
              while (!placed && attempts < 100) {
                final row = DateTime.now().millisecond % 10;
                final col = (DateTime.now().microsecond % 10);
                final horizontal = DateTime.now().millisecond % 2 == 0;
                placed = gameService.canPlaceShip(aiBoard, row, col, ship, horizontal);
                if (placed) {
                  aiBoard = gameService.placeShip(aiBoard, row, col, ship, horizontal);
                }
                attempts++;
              }
            }
            
            final game = Game(
              id: gameId,
              player1: player1,
              player2: player2,
              board1: playerBoard,
              board2: aiBoard,
              moves: [],
              currentTurnPlayerId: playerId,
              status: GameStatus.inProgress,
              createdAt: DateTime.now(),
              player2IsAI: true,
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameScreen(game: game),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startLocalGame() {
    // Créer une partie factice locale
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
    
    final game = Game(
      id: 'game_local_${DateTime.now().millisecondsSinceEpoch}',
      player1: player1,
      player2: player2,
      board1: Board.empty(isVisible: true),
      board2: Board.empty(isVisible: false),
      moves: [],
      currentTurnPlayerId: playerId,
      status: GameStatus.setup,
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(game: game),
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
