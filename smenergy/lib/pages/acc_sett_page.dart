import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isMfaEnabled = false;
  String? _mfaFactorUid;
  String? _mfaPhoneLabel;
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
    _loadMfaState();
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

  Future<String?> _promptForPortuguesePhoneNumber() async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Numero de telemovel'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'O codigo de pais esta fixo para Portugal.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FBFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: errorText == null
                            ? const Color(0xFFD9E9FF)
                            : Colors.redAccent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Color(0xFFD9E9FF)),
                            ),
                          ),
                          child: const Text(
                            '+351',
                            style: TextStyle(
                              color: Color(0xFF1D7EF8),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            onChanged: (_) {
                              if (errorText != null) {
                                setDialogState(() => errorText = null);
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: '912345678',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final digits = controller.text.trim();
                    if (digits.length != 9) {
                      setDialogState(() {
                        errorText = 'Indica os 9 digitos do telemovel.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, '+351$digits');
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  String _formatPortuguesePhoneLabel(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'Numero nao definido';
    }

    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final nationalDigits = digits.startsWith('351') && digits.length >= 12
        ? digits.substring(3)
        : digits;

    if (nationalDigits.length == 9) {
      return '+351 ${nationalDigits.substring(0, 3)} ${nationalDigits.substring(3, 6)} ${nationalDigits.substring(6)}';
    }

    return phoneNumber;
  }

  Widget _buildMfaStatusCard(LinearGradient gradient) {
    final isEnabled = _isMfaEnabled;
    final accentColor = isEnabled
        ? const Color(0xFF1D7EF8)
        : const Color(0xFF6C86A2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isEnabled ? const Color(0xFFB9D9FF) : const Color(0xFFDCEBFF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: isEnabled ? gradient : null,
              color: isEnabled ? null : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: isEnabled
                  ? null
                  : Border.all(color: const Color(0xFFDCEBFF)),
            ),
            child: Icon(
              isEnabled ? Icons.verified_user_rounded : Icons.shield_outlined,
              color: isEnabled ? Colors.white : accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isEnabled
                          ? const Color(0xFFCAE2FF)
                          : const Color(0xFFDCEBFF),
                    ),
                  ),
                  child: Text(
                    isEnabled ? 'MFA ativo' : 'MFA inativo',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isEnabled
                      ? 'Codigo enviado para ${_formatPortuguesePhoneLabel(_mfaPhoneLabel)}.'
                      : 'Adiciona um segundo fator para proteger melhor a tua conta.',
                  style: const TextStyle(
                    color: Color(0xFF2F3443),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Future<void> _loadMfaState() async {
    try {
      final factors = await _authService.getEnrolledMfaFactors();
      if (!mounted) return;

      String? factorUid;
      String? phoneLabel;
      for (final factor in factors) {
        if (factor is PhoneMultiFactorInfo) {
          factorUid = factor.uid;
          phoneLabel = factor.phoneNumber;
          break;
        }
      }

      setState(() {
        _isMfaEnabled = factorUid != null;
        _mfaFactorUid = factorUid;
        _mfaPhoneLabel = phoneLabel;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isMfaEnabled = false;
        _mfaFactorUid = null;
        _mfaPhoneLabel = null;
      });
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

    if (_isMfaEnabled) {
      _showMessage('MFA ja esta ativo.', isError: false);
      return;
    }

    final phoneNumber = await _promptForPortuguesePhoneNumber();
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
      await _loadMfaState();
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

  Future<void> _disableMfa() async {
    if (_isMfaLoading) return;

    final factorUid = _mfaFactorUid;
    if (factorUid == null) {
      _showMessage('Nao existe MFA ativo nesta conta.');
      return;
    }

    setState(() => _isMfaLoading = true);

    try {
      await _authService.unenrollMfa(factorUid: factorUid);
      await _loadMfaState();
      _showMessage('MFA desativado com sucesso.', isError: false);
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapMfaError(e, disabling: true));
    } on StateError catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Erro ao desativar MFA.');
    } finally {
      if (mounted) {
        setState(() => _isMfaLoading = false);
      }
    }
  }

  String _mapMfaError(FirebaseAuthException e, {bool disabling = false}) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Numero de telemovel invalido';
      case 'missing-phone-number':
        return 'Indica um numero de telemovel';
      case 'too-many-requests':
        return 'Muitos pedidos. Tenta mais tarde.';
      case 'invalid-verification-code':
        return 'Codigo SMS invalido.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'A verificacao expirou. Tenta novamente.';
      case 'quota-exceeded':
        return 'Limite de SMS atingido. Tenta mais tarde.';
      case 'second-factor-already-in-use':
        return 'Este numero ja esta associado a outro fator.';
      case 'requires-recent-login':
        return disabling
            ? 'Por seguranca, termina sessao e entra novamente para desativar MFA.'
            : 'Por seguranca, termina sessao e entra novamente para ativar MFA.';
      case 'multi-factor-info-not-found':
        return 'Nao foi encontrado um fator MFA para esta conta.';
      default:
        return disabling
            ? 'Falha ao desativar MFA. Tenta novamente.'
            : 'Falha ao ativar MFA. Tenta novamente.';
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
              text: _isMfaLoading
                  ? (_isMfaEnabled ? 'A desativar MFA...' : 'A ativar MFA...')
                  : (_isMfaEnabled ? 'Desativar MFA' : 'Ativar MFA'),
              gradient: myGradient,
              onPressed: _isMfaEnabled ? _disableMfa : _enableMfa,
            ),
            const SizedBox(height: 16),
            _buildMfaStatusCard(myGradient),
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
