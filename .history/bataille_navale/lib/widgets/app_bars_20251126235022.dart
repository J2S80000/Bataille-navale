import 'package:flutter/material.dart';

/// AppBar réutilisable avec style cohérent pour toute l'app
class GameAppBar extends AppBar {
  GameAppBar({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
    Color? backgroundColor,
    Key? key,
  }) : super(
    key: key,
    title: Text(title),
    backgroundColor: backgroundColor ?? Colors.blue.shade700,
    elevation: 0,
    actions: actions,
    automaticallyImplyLeading: showBackButton, // Flutter gère automatiquement le bouton retour
  );
}

/// AppBar pour la page de sélection de difficulté
class DifficultySelectorAppBar extends AppBar {
  DifficultySelectorAppBar({Key? key})
      : super(
    key: key,
    title: const Text('Choisir la difficulté'),
    backgroundColor: Colors.blue.shade700,
    elevation: 0,
    automaticallyImplyLeading: true,
  );
}

/// AppBar pour la page de placement des navires
class PlacementAppBar extends AppBar {
  PlacementAppBar({
    required VoidCallback onComplete,
    Key? key,
  }) : super(
    key: key,
    title: const Text('Disposition des navires'),
    backgroundColor: Colors.blue.shade700,
    elevation: 0,
    automaticallyImplyLeading: true,
    actions: [
      IconButton(
        icon: const Icon(Icons.check),
        onPressed: onComplete,
        tooltip: 'Prêt',
      ),
    ],
  );
}

/// AppBar pour la page de statistiques
class StatsAppBar extends AppBar {
  StatsAppBar({Key? key})
      : super(
    key: key,
    title: const Text('Statistiques'),
    backgroundColor: Colors.blue.shade700,
    elevation: 0,
    automaticallyImplyLeading: true,
  );
}

/// AppBar pour la page de jeu
class GameScreenAppBar extends AppBar {
  GameScreenAppBar({
    required String title,
    Key? key,
  }) : super(
    key: key,
    title: Text(title),
    backgroundColor: Colors.blue.shade700,
    elevation: 0,
    automaticallyImplyLeading: true,
  );
}
