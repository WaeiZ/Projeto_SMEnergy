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

      // CONFIGURAÇÃO DO TEMA GLOBAL
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Open Sans',

        // Aplicando o Color Scheme baseado no teu design (Dashboard/Alertas)
        colorScheme: ColorScheme(
          brightness: Brightness.light,

          // Azul Forte: Anel do Sensor e Botões Principais
          primary: const Color(0xFF1D7EF8),
          onPrimary: Colors.white,

          // Azul Médio: Gráficos e Barras de Progresso
          secondary: const Color(0xFF3DA5FA),
          onSecondary: Colors.white,

          // Azul Muito Claro: Fundo de Cards de Alerta (Sensor 2/3)
          surface: const Color(0xFFE3F0FE),

          // Cinza: Textos e Ícones Inativos
          onSurface: const Color(0xFF49454F),

          // Laranja/Vermelho: Alertas de Consumo Anómalo
          error: const Color(0xFFDB3918),
          onError: Colors.white,

          // Cor de Contorno: Bordas e Linhas de Divisão
          outline: const Color(0xFF3DA5FA).withOpacity(0.5),
        ),

        // Forçar o fundo da aplicação a ser sempre branco puro
        scaffoldBackgroundColor: Colors.white,

        // Estilização global opcional para facilitar a criação de botões
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D7EF8),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),

      home: const LoginPage(),
    );
  }
}
