import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscure = true;
  final Color primaryBlue = const Color(0xFF3ba4f5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // LOGO
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 50),

              // CAMPO EMAIL (ESTILO "POP OUT")
              _buildPopOutInput(
                icon: Icons.mail_outline,
                hint: 'Email',
                color: primaryBlue,
              ),

              const SizedBox(height: 25),
              // CAMPO SENHA (ESTILO "POP OUT")
              _buildPopOutInput(
                icon: Icons.password,
                hint: 'Password',
                color: primaryBlue,
                isPassword: true,
                isObscure: _isObscure,
                onToggleVisibility: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),

              const SizedBox(height: 10),

              // ESQUECEU A SENHA
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Esqueceu a sua password?',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // BOTÃO ENTRAR
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 30),

              // DIVISOR
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Ou entra com',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 30),

              // BOTÃO GMAIL (COM STACK)
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. O icon alinhado a esquerda
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 135.0),
                          child: Image.asset('assets/google.png', height: 35),
                        ),
                      ),

                      // 2. O TEXTO (Fica no centro absoluto)
                      const Text(
                        'Gmail',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // RODAPÉ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sem conta? ',
                    style: TextStyle(color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Criar conta',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopOutInput({
    required IconData icon,
    required String hint,
    required Color color,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
  }) {
    //tamanhos
    const double totalHeight = 64.0;
    const double inputHeight = 50.0;
    const double circleSize = 64.0;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 1. A BARRA DE TEXTO (Fica atrás e recuada)
          Container(
            height: inputHeight,
            // Mantém a margem da barra fixa
            margin: const EdgeInsets.only(left: 30.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              border: Border.all(color: color, width: 1.2),
            ),
            child: Row(
              children: [
                // Espaço esquerda do texto
                const SizedBox(width: 45),

                // ----------------------
                Expanded(
                  child: TextFormField(
                    obscureText: isObscure,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 4),
                    ),
                  ),
                ),
                // Ícone do Olho (Senha)
                if (isPassword)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: onToggleVisibility,
                      child: Icon(
                        isObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. O CÍRCULO (Fica na frente, maior e na ponta)
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }
}
