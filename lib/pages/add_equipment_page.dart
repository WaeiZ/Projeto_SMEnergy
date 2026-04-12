import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smenergy/pages/login_page.dart';
import 'package:smenergy/pages/add_equipment_page_2.dart';
import 'package:smenergy/services/auth_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class AddEquipmentPage extends StatelessWidget {
  const AddEquipmentPage({
    super.key,
    AuthServiceBase? authService,
    this.loginPageBuilder,
  }) : authService = authService ?? const _DefaultAuthServiceProxy();

  final AuthServiceBase authService;
  final WidgetBuilder? loginPageBuilder;

  Future<void> _goBackToLogin(BuildContext context) async {
    await authService.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: loginPageBuilder ?? (context) => const LoginPage(),
      ),
      (route) => false,
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => _goBackToLogin(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO
              Image.asset('assets/logo.png', height: 180, fit: BoxFit.contain),

              const SizedBox(height: 60),

              // TEXTO
              const Text(
                'Adicionar Equipamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              // BOTÃO CIRCULAR "+"
              GestureDetector(
                onTap: () {
                  // Navega para o Passo 1/2
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetupStepOnePage(),
                    ),
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF3DA5FA),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => myGradient.createShader(bounds),
                    child: const Icon(
                      Icons.add_circle_outline,
                      size: 50,
                      color: Colors.white, // O ShaderMask vai pintar o ícone
                    ),
                  ),
                ),
              ),

              // Espaço extra no fundo para equilibrar o centro visual
              const SizedBox(height: 100),
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
