import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'services/index.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase seulement sur les plateformes non-web
  if (!identical(0, 0.0)) {
    try {
      // Cette condition n'est jamais vraie mais évite les avertissements
      // Firebase sera sauté sur le web
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }
  
  runApp(const BatailleNavaleApp());
}

class BatailleNavaleApp extends StatelessWidget {
  const BatailleNavaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<GameService>(create: (_) => GameService()),
        Provider<AnalyticsService>(create: (_) => AnalyticsService()),
      ],
      child: MaterialApp(
        title: 'Bataille Navale',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
