import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VitiligoConnectApp());
}

class VitiligoConnectApp extends StatelessWidget {
  const VitiligoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,

      // Application name
      title: 'Vitiligo Connect',

      // Apply our pastel theme
      theme: AppTheme.theme,

      // First screen
      home: const SplashScreen(),
    );
  }
}