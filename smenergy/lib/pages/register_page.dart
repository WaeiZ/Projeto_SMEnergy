import 'package:flutter/material.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isObscure = true;
  bool _isObscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _validarRegisto() {
    final email = _emailController.text.trim();
    final nome = _nomeController.text.trim();
    final pass = _passController.text;
    final confirmPass = _confirmPassController.text;

    if (email.isEmpty || nome.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      _mostrarMensagem("Preencha todos os campos");
      return;
    }

    if (pass != confirmPass) {
      _mostrarMensagem("As passwords não coincidem");
      return;
    }

    print('Sucesso: $email');
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Registo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 25),
              CustomPopOutInput(
                controller: _emailController,
                icon: Icons.mail_outline,
                hint: 'Email',
                gradient: myGradient,
              ),
              const SizedBox(height: 20),
              CustomPopOutInput(
                controller: _nomeController,
                icon: Icons.person_outline,
                hint: 'Nome',
                gradient: myGradient,
              ),
              const SizedBox(height: 20),
              CustomPopOutInput(
                controller: _passController,
                icon: Icons.more_horiz,
                hint: 'Password',
                gradient: myGradient,
                isPassword: true,
                isObscure: _isObscure,
                onToggleVisibility: () {
                  setState(() => _isObscure = !_isObscure);
                },
              ),
              const SizedBox(height: 20),
              CustomPopOutInput(
                controller: _confirmPassController,
                icon: Icons.more_horiz,
                hint: 'Confirma a tua Password',
                gradient: myGradient,
                isPassword: true,
                isObscure: _isObscureConfirm,
                onToggleVisibility: () {
                  setState(() => _isObscureConfirm = !_isObscureConfirm);
                },
              ),
              const SizedBox(height: 40),
              CustomGradientButton(
                text: 'Criar Conta',
                gradient: myGradient,
                onPressed: _validarRegisto,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}