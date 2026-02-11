import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smenergy/pages/add_equipment_page.dart';
import 'package:smenergy/pages/register_page.dart';
import 'package:smenergy/services/auth_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;
  bool _isResetLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final pass = _passController.text;

    if (email.isEmpty || pass.isEmpty) {
      _mostrarMensagem('Preencha email e password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: pass);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AddEquipmentPage(),
        ),
      );
    } on FirebaseAuthMultiFactorException catch (e) {
      try {
        await _authService.resolveSignInWithSmsMfa(
          exception: e,
          getSmsCode: _promptForSmsCode,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEquipmentPage(),
          ),
        );
      } on StateError catch (err) {
        if (err.message != 'CANCELLED') {
          _mostrarMensagem(err.message);
        }
      }
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_mapAuthError(e));
    } catch (_) {
      _mostrarMensagem('Erro ao entrar. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AddEquipmentPage(),
        ),
      );
    } on FirebaseAuthMultiFactorException catch (e) {
      try {
        await _authService.resolveSignInWithSmsMfa(
          exception: e,
          getSmsCode: _promptForSmsCode,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEquipmentPage(),
          ),
        );
      } on StateError catch (err) {
        if (err.message != 'CANCELLED') {
          _mostrarMensagem(err.message);
        }
      }
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_mapAuthError(e));
    } on StateError catch (e) {
      if (e.message != 'CANCELLED') {
        _mostrarMensagem(e.message);
      }
    } catch (_) {
      _mostrarMensagem('Erro ao entrar com Google.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_isResetLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _mostrarMensagem('Indica o teu email para recuperar a password');
      return;
    }

    setState(() => _isResetLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _mostrarMensagem(
        'Enviámos um email para redefinir a password',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          _mostrarMensagem('Email inválido');
          break;
        case 'user-not-found':
          _mostrarMensagem('Não existe conta com este email');
          break;
        default:
          _mostrarMensagem('Erro ao enviar email de recuperação');
      }
    } catch (_) {
      _mostrarMensagem('Erro ao enviar email de recuperação');
    } finally {
      if (mounted) {
        setState(() => _isResetLoading = false);
      }
    }
  }

  Future<String?> _promptForSmsCode() async {
    String currentValue = '';
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Código SMS'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) => currentValue = value,
            decoration: const InputDecoration(
              hintText: 'Ex: 123456',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final code = currentValue.trim();
                Navigator.pop(dialogContext, code.isEmpty ? null : code);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return result;
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email inválido';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou password incorretos';
      case 'user-disabled':
        return 'Conta desativada';
      default:
        return 'Falha no login. Tente novamente.';
    }
  }

  void _mostrarMensagem(String texto, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

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
                controller: _emailController,
                icon: Icons.mail_outline,
                hint: 'Email',
                gradient: myGradient,
              ),

              const SizedBox(height: 25),

              // PASSWORD
              CustomPopOutInput(
                controller: _passController,
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
                  onPressed: _isResetLoading ? null : _forgotPassword,
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
                text: _isLoading ? 'A entrar...' : 'Entrar',
                gradient: myGradient,
                onPressed: () {
                  _login();
                },
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
                  onPressed: _isLoading ? null : _loginWithGoogle,
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
