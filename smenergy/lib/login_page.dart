import 'package:flutter/material.dart';
import 'package:smenergy/Register_Page';
import 'package:smenergy/widgets/custom_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 90),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // EMAIL
              CustomPopOutInput(
                icon: Icons.mail_outline,
                hint: 'Email',
                gradient: myGradient,
              ),

              const SizedBox(height: 25),

              // PASSWORD
              CustomPopOutInput(
                icon: Icons.lock_outline,
                hint: 'Password',
                gradient: myGradient,
                isPassword: true,
                isObscure: _isObscure,
                onToggleVisibility: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),

              // ESQUECEU A PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Esqueceu a sua password?',
                    style: TextStyle(
                      color: Color(0xFF1D7EF8), // Azul 500
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // BOTÃO ENTRAR
              CustomGradientButton(
                text: 'Entrar',
                gradient: myGradient,
                onPressed: () {},
              ),

              const SizedBox(height: 35),

              // DIVISOR
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Ou entra com',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 30),

              // BOTÃO GMAIL
              SizedBox(
                height: 55,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[200]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Image.asset('assets/google.png', height: 35),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Gmail',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // RODAPÉ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sem conta? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Criar conta',
                      style: TextStyle(
                        color: Color(0xFF1D7EF8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
