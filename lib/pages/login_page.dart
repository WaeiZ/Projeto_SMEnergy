import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smenergy/pages/add_equipment_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/register_page.dart';
import 'package:smenergy/services/auth_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    AuthServiceBase? authService,
    this.dashboardPageBuilder,
    this.addEquipmentPageBuilder,
  }) : authService = authService ?? const _DefaultAuthServiceProxy();

  final AuthServiceBase authService;
  final WidgetBuilder? dashboardPageBuilder;
  final WidgetBuilder? addEquipmentPageBuilder;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      await widget.authService.signIn(email: email, password: pass);
      if (!mounted) return;
      await _navigateAfterLogin();
    } on FirebaseAuthMultiFactorException catch (e) {
      try {
        await widget.authService.resolveSignInWithSmsMfa(
          exception: e,
          getSmsCode: _promptForSmsCode,
        );
        if (!mounted) return;
        await _navigateAfterLogin();
      } on StateError catch (err) {
        if (err.message != 'CANCELLED') {
          _mostrarMensagem(err.message);
        }
      } on FirebaseAuthException catch (err) {
        _mostrarMensagem(_mapAuthError(err));
      } catch (_) {
        _mostrarMensagem('Não foi possível confirmar o segundo fator.');
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
      await widget.authService.signInWithGoogle();
      if (!mounted) return;
      await _navigateAfterLogin();
    } on FirebaseAuthMultiFactorException catch (e) {
      try {
        await widget.authService.resolveSignInWithSmsMfa(
          exception: e,
          getSmsCode: _promptForSmsCode,
        );
        if (!mounted) return;
        await _navigateAfterLogin();
      } on StateError catch (err) {
        if (err.message != 'CANCELLED') {
          _mostrarMensagem(err.message);
        }
      } on FirebaseAuthException catch (err) {
        _mostrarMensagem(_mapAuthError(err));
      } catch (_) {
        _mostrarMensagem('Não foi possível confirmar o segundo fator.');
      }
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_mapAuthError(e));
    } on StateError catch (e) {
      if (e.message != 'CANCELLED') {
        _mostrarMensagem(e.message);
      }
    } on PlatformException catch (e) {
      final message = (e.message ?? '').trim();
      final suffix = message.isEmpty ? '' : ': $message';
      _mostrarMensagem('Google Sign-In falhou (${e.code})$suffix');
    } catch (e) {
      _mostrarMensagem('Erro ao entrar com Google: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateAfterLogin() async {
    bool hasEquipment = false;
    try {
      hasEquipment = await widget.authService.hasEquipmentForCurrentUser();
    } catch (_) {
      hasEquipment = false;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: hasEquipment
            ? (widget.dashboardPageBuilder ??
                  (context) => const DashboardPage())
            : (widget.addEquipmentPageBuilder ??
                  (context) => const AddEquipmentPage()),
      ),
    );
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
      await widget.authService.sendPasswordResetEmail(email: email);
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
            decoration: const InputDecoration(hintText: 'Ex: 123456'),
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
      case 'app-not-authorized':
        return 'Esta instalação Android não está autorizada no Firebase. Verifique o package name e os SHA-1/SHA-256 na consola Firebase.';
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
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 52),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 185,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              CustomPopOutInput(
                controller: _emailController,
                icon: Icons.mail_outline,
                hint: 'Email',
                gradient: myGradient,
              ),
              const SizedBox(height: 22),
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
                      color: Color(0xFF1D7EF8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomGradientButton(
                text: _isLoading ? 'A entrar...' : 'Entrar',
                gradient: myGradient,
                onPressed: _login,
              ),
              const SizedBox(height: 28),
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 22),
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

class _DefaultAuthServiceProxy implements AuthServiceBase {
  const _DefaultAuthServiceProxy();

  AuthService get _service => AuthService();

  @override
  Future<void> deleteAccountAndData() => _service.deleteAccountAndData();

  @override
  Future<void> enrollPhoneMfa({
    required String phoneNumber,
    required Future<String?> Function() getSmsCode,
  }) =>
      _service.enrollPhoneMfa(phoneNumber: phoneNumber, getSmsCode: getSmsCode);

  @override
  Future<List<MultiFactorInfo>> getEnrolledMfaFactors() =>
      _service.getEnrolledMfaFactors();

  @override
  Future<bool> hasEquipmentForCurrentUser() =>
      _service.hasEquipmentForCurrentUser();

  @override
  Future<void> resolveSignInWithSmsMfa({
    required FirebaseAuthMultiFactorException exception,
    required Future<String?> Function() getSmsCode,
  }) => _service.resolveSignInWithSmsMfa(
    exception: exception,
    getSmsCode: getSmsCode,
  );

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _service.sendPasswordResetEmail(email: email);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  @override
  Future<void> signInWithGoogle() => _service.signInWithGoogle();

  @override
  Future<void> signOut() => _service.signOut();

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => _service.signUp(name: name, email: email, password: password);

  @override
  Future<void> updateUserName({required String name}) =>
      _service.updateUserName(name: name);

  @override
  Future<void> unenrollMfa({required String factorUid}) =>
      _service.unenrollMfa(factorUid: factorUid);
}
