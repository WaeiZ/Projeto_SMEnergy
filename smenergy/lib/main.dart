import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Certifica-te de que os caminhos abaixo batem certo com a tua estrutura de pastas
import 'firebase_options.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';
import 'services/config_service.dart';

void main() async {
  // OBRIGATÓRIO: Garante que as APIs nativas (como SharedPreferences)
  // são inicializadas antes da App correr.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMEnergy',

      // O teu tema global (mantido exatamente como tinhas)
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
          outline: const Color(0xFF3DA5FA).withOpacity(0.5),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),

      // LÓGICA DE ENTRADA DINÂMICA
      home: FutureBuilder<int>(
        future: ConfigService.getConfigStatus(),
        builder: (context, snapshot) {
          // 1. Enquanto está a ler a memória ( SharedPreferences )
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. Verifica o resultado da flag (1 = Dashboard, 0 = Login/Setup)
          // snapshot.data ?? 0 para garantir que se for nulo, vai para o Login
          if (snapshot.hasData && snapshot.data == 0) {
            return const DashboardPage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
