import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class LobbyScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const LobbyScreen({
    Key? key,
    required this.playerId,
    required this.playerName,
  }) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _gameNameController = TextEditingController();
  List<Game> _availableGames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableGames();
  }

  Future<void> _loadAvailableGames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // À implémenter: récupérer les parties en attente
      // final games = await firebase.getAvailableGames();
      // setState(() {
      //   _availableGames = games;
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createGame() {
    final gameName = _gameNameController.text.trim();
    if (gameName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entrez un nom de partie')),
      );
      return;
    }

    // Créer la partie
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partie créée: $gameName')),
    );
    _gameNameController.clear();
    _loadAvailableGames();
  }

  void _joinGame(Game game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejoignez la partie: ${game.id}')),
    );
    // Naviguer vers GameScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby multijoueur'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // En-tête avec infos joueur
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade700,
                  child: Text(
                    widget.playerName.isNotEmpty
                        ? widget.playerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.playerName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Joueur ID: ${widget.playerId.substring(0, 8)}...',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _loadAvailableGames,
                  icon: Icon(Icons.refresh),
                  label: Text('Actualiser'),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Créer une nouvelle partie
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créer une nouvelle partie',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _gameNameController,
                            decoration: InputDecoration(
                              hintText: 'Nom de la partie',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text('Créer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          // Parties disponibles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Parties disponibles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _availableGames.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade300),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucune partie disponible',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _availableGames.length,
                              itemBuilder: (context, index) {
                                final game = _availableGames[index];
                                return _buildGameCard(game);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(Game game) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.id,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      SizedBox(width: 4),
                      Text(
                        'Adversaire en attente',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _joinGame(game),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }
}
