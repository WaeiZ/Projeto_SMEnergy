import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class ChangePassPage extends StatefulWidget {
  const ChangePassPage({super.key});

  @override
  State<ChangePassPage> createState() => _ChangePassPageState();
}

class _ChangePassPageState extends State<ChangePassPage> {
  final TextEditingController _currentPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final RegExp _hasUpper = RegExp(r'[A-Z]');
  final RegExp _hasLower = RegExp(r'[a-z]');
  final RegExp _hasDigit = RegExp(r'\d');
  final RegExp _hasSpecial =
      RegExp(r"[!@#$%^&*(),.?{}|<>_\-\\/\[\];'`~+=]");

  @override
  void dispose() {
    _currentPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_isLoading) return;

    final current = _currentPass.text;
    final next = _newPass.text;
    final confirm = _confirmPass.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showMessage('Preenche todos os campos');
      return;
    }

    if (next != confirm) {
      _showMessage('As passwords não coincidem');
      return;
    }

    final validationError = _validatePassword(next);
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showMessage('Sessão inválida. Faz login novamente.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(next);
      _showMessage('Password atualizada com sucesso', isError: false);
      _currentPass.clear();
      _newPass.clear();
      _confirmPass.clear();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _showMessage('Password atual incorreta');
          break;
        case 'requires-recent-login':
          _showMessage('Por segurança, faz login novamente e tenta outra vez.');
          break;
        default:
          _showMessage('Erro ao atualizar password');
      }
    } catch (_) {
      _showMessage('Erro ao atualizar password');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _showMessage(String text, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Redefinir Password',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _currentPass,
              icon: Icons.more_horiz,
              hint: 'Password atual',
              gradient: myGradient,
              isPassword: true,
              isObscure: _obscureCurrent,
              onToggleVisibility: () {
                setState(() => _obscureCurrent = !_obscureCurrent);
              },
            ),
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _newPass,
              icon: Icons.more_horiz,
              hint: 'Password',
              gradient: myGradient,
              isPassword: true,
              isObscure: _obscureNew,
              onToggleVisibility: () {
                setState(() => _obscureNew = !_obscureNew);
              },
            ),
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _confirmPass,
              icon: Icons.more_horiz,
              hint: 'Confirma a tua Password',
              gradient: myGradient,
              isPassword: true,
              isObscure: _obscureConfirm,
              onToggleVisibility: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
            ),
            const SizedBox(height: 24),
            CustomGradientButton(
              text: _isLoading ? 'A guardar...' : 'Confirmar',
              gradient: myGradient,
              onPressed: _changePassword,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
