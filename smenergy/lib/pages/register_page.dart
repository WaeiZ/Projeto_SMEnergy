import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smenergy/pages/add_equipment_page.dart';
import 'package:smenergy/services/auth_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, AuthServiceBase? authService})
    : authService = authService ?? const _DefaultAuthServiceProxy();

  final AuthServiceBase authService;

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
  bool _isLoading = false;
  final RegExp _hasUpper = RegExp(r'[A-Z]');
  final RegExp _hasLower = RegExp(r'[a-z]');
  final RegExp _hasDigit = RegExp(r'\d');
  final RegExp _hasSpecial = RegExp(r"[!@#$%^&*(),.?{}|<>_\-\\/\[\];'`~+=]");

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _validarRegisto() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final nome = _nomeController.text.trim();
    final pass = _passController.text;
    final confirmPass = _confirmPassController.text;

    if (email.isEmpty || nome.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      _mostrarMensagem('Preencha todos os campos');
      return;
    }

    final passwordError = _validatePassword(pass);
    if (passwordError != null) {
      _mostrarMensagem(passwordError);
      return;
    }

    if (pass != confirmPass) {
      _mostrarMensagem('As passwords não coincidem');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.authService.signUp(name: nome, email: email, password: pass);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AddEquipmentPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_mapAuthError(e));
    } catch (_) {
      _mostrarMensagem('Erro ao criar conta. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: Colors.redAccent),
    );
  }

  String? _validatePassword(String pass) {
    if (pass.length < 8) {
      return 'A password deve ter pelo menos 8 caracteres';
    }
    if (!_hasUpper.hasMatch(pass)) {
      return 'A password deve ter pelo menos 1 letra maiúscula';
    }
    if (!_hasLower.hasMatch(pass)) {
      return 'A password deve ter pelo menos 1 letra minúscula';
    }
    if (!_hasDigit.hasMatch(pass)) {
      return 'A password deve ter pelo menos 1 número';
    }
    if (!_hasSpecial.hasMatch(pass)) {
      return 'A password deve ter pelo menos 1 carácter especial';
    }
    return null;
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este email já está registado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'A password é demasiado fraca';
      default:
        return 'Falha no registo. Tente novamente.';
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
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
                text: _isLoading ? 'A criar...' : 'Criar Conta',
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
