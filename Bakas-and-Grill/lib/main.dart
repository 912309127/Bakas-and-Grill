import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import only the necessary logic and screens
import 'auth_wrapper.dart'; 
import 'pages/login_screen.dart'; 
import 'pages/kitchen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BakasGrillApp());
}

class BakasGrillApp extends StatelessWidget {
  const BakasGrillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakas & Grill - Kitchen Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFc00e22), 
          primary: const Color(0xFFc00e22),
        ),
        scaffoldBackgroundColor: const Color(0xFFf4f7f6),
      ),

      // The gatekeeper (Auth Overlay)
      home: const AuthWrapper(),

      // Static routes for simple navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/kitchen': (context) => const KitchenDashboard(),
      },
    );
  }
}