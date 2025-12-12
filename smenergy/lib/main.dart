import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
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
        // Palete cores
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3ba4f5)),
        useMaterial3: true,
      ),
      // Chamada Login Page
      home: const LoginPage(),
    );
  }
}
