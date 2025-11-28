import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/index.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Catch all uncaught exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ Flutter Error: ${details.exception}');
    print('Stack: ${details.stack}');
  };

  runApp(const BatailleNavaleApp());
}

class BatailleNavaleApp extends StatelessWidget {
  const BatailleNavaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GameService>(create: (_) => GameService()),
        Provider<AnalyticsService>(create: (_) => AnalyticsService()),
        // Firebase service is optional for web
        Provider<FirebaseService?>(
          create: (_) {
            try {
              return FirebaseService();
            } catch (e) {
              print('Firebase not available: $e');
              return null;
            }
          },
        ),
      ],
      child: MaterialApp(
        title: 'Bataille Navale',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MainScreen(),
        builder: (context, child) {
          return child ?? const Placeholder();
        },
      ),
    );
  }
}
