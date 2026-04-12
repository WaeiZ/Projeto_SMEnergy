import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smenergy/pages/add_equipment_page.dart';
import 'package:smenergy/pages/login_page.dart';
import 'package:smenergy/pages/register_page.dart';
import 'package:smenergy/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginPage', () {
    testWidgets('mostra erro quando email e password estao vazios', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(child: LoginPage(authService: _FakeAuthService())),
      );

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Preencha email e password'), findsOneWidget);
    });

    testWidgets('navega para adicionar equipamento apos login com sucesso', (
      tester,
    ) async {
      final authService = _FakeAuthService(hasEquipment: false);

      await tester.pumpWidget(
        _buildTestApp(child: LoginPage(authService: authService)),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'teste@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1!');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(authService.signInCalls, 1);
      expect(find.byType(AddEquipmentPage), findsOneWidget);
      expect(find.text('Adicionar Equipamento'), findsOneWidget);
    });

    testWidgets('envia email de recuperacao quando o email foi preenchido', (
      tester,
    ) async {
      final authService = _FakeAuthService();

      await tester.pumpWidget(
        _buildTestApp(child: LoginPage(authService: authService)),
      );

      await tester.enterText(find.byType(TextFormField).first, 'teste@sme.pt');
      await tester.tap(find.text('Esqueceu a sua password?'));
      await tester.pump();

      expect(authService.resetPasswordCalls, 1);
      expect(
        find.text('Enviámos um email para redefinir a password'),
        findsOneWidget,
      );
    });
  });

  group('RegisterPage', () {
    testWidgets('mostra erro quando a password nao cumpre os requisitos', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(child: RegisterPage(authService: _FakeAuthService())),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'novo@sme.pt');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Novo Utilizador',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'abc');
      await tester.enterText(find.byType(TextFormField).at(3), 'abc');
      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      expect(
        find.text('A password deve ter pelo menos 8 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('navega para adicionar equipamento apos registo valido', (
      tester,
    ) async {
      final authService = _FakeAuthService();

      await tester.pumpWidget(
        _buildTestApp(child: RegisterPage(authService: authService)),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'novo@sme.pt');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Novo Utilizador',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');
      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pumpAndSettle();

      expect(authService.signUpCalls, 1);
      expect(find.byType(AddEquipmentPage), findsOneWidget);
      expect(find.text('Adicionar Equipamento'), findsOneWidget);
    });
  });
}

Widget _buildTestApp({required Widget child}) {
  return DefaultAssetBundle(
    bundle: _TestAssetBundle(),
    child: MaterialApp(home: child),
  );
}

class _FakeAuthService implements AuthServiceBase {
  _FakeAuthService({this.hasEquipment = false});

  final bool hasEquipment;
  int signInCalls = 0;
  int signUpCalls = 0;
  int resetPasswordCalls = 0;

  @override
  Future<void> deleteAccountAndData() async {}

  @override
  Future<void> enrollPhoneMfa({
    required String phoneNumber,
    required Future<String?> Function() getSmsCode,
  }) async {}

  @override
  Future<List<MultiFactorInfo>> getEnrolledMfaFactors() async => const [];

  @override
  Future<bool> hasEquipmentForCurrentUser() async => hasEquipment;

  @override
  Future<void> resolveSignInWithSmsMfa({
    required FirebaseAuthMultiFactorException exception,
    required Future<String?> Function() getSmsCode,
  }) async {}

  @override
  Future<void> unenrollMfa({required String factorUid}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetPasswordCalls++;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
  }

  @override
  Future<void> updateUserName({required String name}) async {}
}

class _TestAssetBundle extends CachingAssetBundle {
  static final Uint8List _transparentImage = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WnM6t8AAAAASUVORK5CYII=',
  );

  static final ByteData _assetManifest = const StandardMessageCodec()
      .encodeMessage(<String, List<Map<String, Object?>>>{
        'assets/logo.png': [
          <String, Object?>{'asset': 'assets/logo.png', 'dpr': 1.0},
        ],
        'assets/google.png': [
          <String, Object?>{'asset': 'assets/google.png', 'dpr': 1.0},
        ],
      })!;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return _assetManifest;
    }
    if (key == 'AssetManifest.json') {
      final manifest = utf8.encode(
        '{"assets/logo.png":["assets/logo.png"],"assets/google.png":["assets/google.png"]}',
      );
      return ByteData.view(Uint8List.fromList(manifest).buffer);
    }
    if (key == 'assets/logo.png' || key == 'assets/google.png') {
      return ByteData.view(Uint8List.fromList(_transparentImage).buffer);
    }
    throw FlutterError('Asset not found in test bundle: $key');
  }
}
