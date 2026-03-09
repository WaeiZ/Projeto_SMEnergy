import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMEnergy',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Open Sans',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF1D7EF8),
          onPrimary: Colors.white,
          secondary: const Color(0xFF3DA5FA),
          onSecondary: Colors.white,
          surface: const Color(0xFFE3F0FE),
          onSurface: const Color(0xFF49454F),
          error: const Color(0xFFDB3918),
          onError: Colors.white,
          outline: const Color(0xFF3DA5FA).withValues(alpha: 0.5),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
    );
  }
}
