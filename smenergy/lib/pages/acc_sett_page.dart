import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/change_pass_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/login_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/services/auth_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class AccSettPage extends StatefulWidget {
  const AccSettPage({super.key});

  @override
  State<AccSettPage> createState() => _AccSettPageState();
}

class _AccSettPageState extends State<AccSettPage> {
  int _selectedIndex = 3;
  final TextEditingController _nameController =
      TextEditingController(text: 'Sergio Dias');
  final AuthService _authService = AuthService();
  bool _isMfaLoading = false;
  bool _isDeleteLoading = false;
  bool _isNameLoading = false;
  String _initialName = '';
  bool _hasNameChanged = false;

  @override
  void initState() {
    super.initState();
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      _nameController.text = displayName.trim();
    }
    _initialName = _nameController.text.trim();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  Future<String?> _promptForInput({
    required String title,
    required String hint,
    TextInputType? keyboardType,
  }) async {
    String currentValue = '';
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            keyboardType: keyboardType,
            onChanged: (value) => currentValue = value,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final value = currentValue.trim();
                Navigator.pop(dialogContext, value.isEmpty ? null : value);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return result;
  }

  void _showMessage(String text, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _onNameChanged() {
    final changed = _nameController.text.trim() != _initialName;
    if (changed != _hasNameChanged) {
      setState(() => _hasNameChanged = changed);
    }
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar conta'),
          content: const Text('Tens a certeza? Esta acao e permanente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteAccount() async {
    if (_isDeleteLoading) return;

    final confirmed = await _confirmDelete();
    if (!confirmed) return;

    setState(() => _isDeleteLoading = true);

    try {
      await _authService.deleteAccountAndData();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          _showMessage(
            'Por seguranca, termina sessao e entra novamente para eliminar a conta.',
          );
          break;
        default:
          _showMessage('Erro ao eliminar conta.');
      }
    } catch (_) {
      _showMessage('Erro ao eliminar conta.');
    } finally {
      if (mounted) {
        setState(() => _isDeleteLoading = false);
      }
    }
  }

  Future<void> _saveName() async {
    if (_isNameLoading) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Indica um nome');
      return;
    }

    setState(() => _isNameLoading = true);

    try {
      await _authService.updateUserName(name: name);
      _initialName = name;
      if (mounted) {
        setState(() => _hasNameChanged = false);
      }
      _showMessage('Nome atualizado com sucesso', isError: false);
    } on StateError catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Erro ao atualizar nome.');
    } finally {
      if (mounted) {
        setState(() => _isNameLoading = false);
      }
    }
  }

  Future<void> _enableMfa() async {
    if (_isMfaLoading) return;

    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sessao invalida. Faz login novamente.');
      return;
    }

    final factors = await user.multiFactor.getEnrolledFactors();
    if (factors.isNotEmpty) {
      _showMessage('MFA ja esta ativo.', isError: false);
      return;
    }

    final phoneNumber = await _promptForInput(
      title: 'Numero de telemovel',
      hint: '+351 9xx xxx xxx',
      keyboardType: TextInputType.phone,
    );
    if (phoneNumber == null) return;

    setState(() => _isMfaLoading = true);

    try {
      await _authService.enrollPhoneMfa(
        phoneNumber: phoneNumber,
        getSmsCode: () => _promptForInput(
          title: 'Codigo SMS',
          hint: 'Ex: 123456',
          keyboardType: TextInputType.number,
        ),
      );
      _showMessage('MFA ativado com sucesso.', isError: false);
      if (user.email != null && !user.emailVerified) {
        _showMessage(
          'Foi enviado um email de verificacao. Confirma o email depois.',
          isError: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapMfaError(e));
    } on StateError catch (e) {
      if (e.message != 'CANCELLED') {
        _showMessage(e.message);
      }
    } catch (_) {
      _showMessage('Erro ao ativar MFA.');
    } finally {
      if (mounted) {
        setState(() => _isMfaLoading = false);
      }
    }
  }

  String _mapMfaError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Numero de telemovel invalido';
      case 'missing-phone-number':
        return 'Indica um numero de telemovel';
      case 'too-many-requests':
        return 'Muitos pedidos. Tenta mais tarde.';
      case 'requires-recent-login':
        return 'Por seguranca, termina sessao e entra novamente para ativar MFA.';
      default:
        return 'Falha ao ativar MFA. Tenta novamente.';
    }
  }

  bool _canChangePassword() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
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
          'Definicoes da conta',
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
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3DA5FA), width: 2),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF3DA5FA),
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _nameController,
              icon: Icons.person_outline,
              hint: 'Nome',
              gradient: myGradient,
            ),
            const SizedBox(height: 24),
            if (_hasNameChanged) ...[
              CustomGradientButton(
                text: _isNameLoading ? 'A guardar...' : 'Guardar Nome',
                gradient: myGradient,
                onPressed: _saveName,
              ),
              const SizedBox(height: 16),
            ],
            if (_canChangePassword()) ...[
              CustomGradientButton(
                text: 'Redefinir Password',
                gradient: myGradient,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePassPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            CustomGradientButton(
              text: _isMfaLoading ? 'A ativar MFA...' : 'Ativar MFA',
              gradient: myGradient,
              onPressed: _enableMfa,
            ),
            const SizedBox(height: 16),
            CustomGradientButton(
              text: _isDeleteLoading ? 'A eliminar...' : 'Eliminar Conta',
              gradient: myGradient,
              onPressed: _deleteAccount,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
            return;
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
            return;
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AlertPage()),
            );
            return;
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        items: [
          _navItem(Icons.grid_view_rounded, 'Dashboard', 0),
          _navItem(Icons.bar_chart_rounded, 'Historico', 1),
          _navItem(Icons.warning_amber_rounded, 'Alertas', 2),
          _navItem(Icons.person_outline, 'Perfil', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3DA5FA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      ),
      label: label,
    );
  }
}
