import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bataille Navale'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue à Bataille Navale!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nouvelle partie - À venir')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Nouvelle Partie'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statistiques - À venir')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Mes Statistiques'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leaderboard - À venir')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Leaderboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
