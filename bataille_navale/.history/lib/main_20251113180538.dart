import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/index.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization is skipped on web platform
  
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
