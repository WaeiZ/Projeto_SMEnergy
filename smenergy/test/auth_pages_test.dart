import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smenergy/pages/login_page.dart';
import 'package:smenergy/pages/register_page.dart';

import 'test_support.dart';

void main() {
  group('LoginPage adicionais', () {
    testWidgets('mostra erro de credenciais invalidas', (tester) async {
      final auth = FakeAuthService(
        signInError: FirebaseAuthException(code: 'wrong-password'),
      );

      await tester.pumpWidget(buildTestApp(LoginPage(authService: auth)));

      await tester.enterText(find.byType(TextFormField).at(0), 'teste@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Email ou password incorretos'), findsOneWidget);
    });

    testWidgets('ativa estado loading durante autenticacao', (tester) async {
      final completer = Completer<void>();
      final auth = FakeAuthService(signInCompleter: completer);

      await tester.pumpWidget(buildTestApp(LoginPage(authService: auth)));

      await tester.enterText(find.byType(TextFormField).at(0), 'teste@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1!');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('A entrar...'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('navega para dashboard quando utilizador ja tem equipamento', (
      tester,
    ) async {
      final auth = FakeAuthService(hasEquipment: true);

      await tester.pumpWidget(
        buildTestApp(
          LoginPage(
            authService: auth,
            dashboardPageBuilder: (_) =>
                const Scaffold(body: Text('Dashboard destino')),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'teste@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1!');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard destino'), findsOneWidget);
    });

    testWidgets('executa login com google', (tester) async {
      final auth = FakeAuthService(hasEquipment: false);

      await tester.pumpWidget(buildTestApp(LoginPage(authService: auth)));
      await tester.tap(find.text('Gmail'));
      await tester.pumpAndSettle();

      expect(auth.googleCalls, 1);
    });

    testWidgets('mostra erro do google sign in por plataforma', (tester) async {
      final auth = FakeAuthService(
        googleError: PlatformException(
          code: 'sign_in_failed',
          message: 'Utilizador cancelou',
        ),
      );

      await tester.pumpWidget(buildTestApp(LoginPage(authService: auth)));
      await tester.tap(find.text('Gmail'));
      await tester.pump();

      expect(
        find.text(
          'Google Sign-In falhou (sign_in_failed): Utilizador cancelou',
        ),
        findsOneWidget,
      );
    });
  });

  group('RegisterPage adicionais', () {
    testWidgets('mostra erro quando ha campos vazios', (tester) async {
      await tester.pumpWidget(
        buildTestApp(RegisterPage(authService: FakeAuthService())),
      );

      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      expect(find.text('Preencha todos os campos'), findsOneWidget);
    });

    testWidgets('mostra erro quando passwords nao coincidem', (tester) async {
      await tester.pumpWidget(
        buildTestApp(RegisterPage(authService: FakeAuthService())),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'novo@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), 'Novo');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password2!');
      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      expect(find.text('As passwords não coincidem'), findsOneWidget);
    });

    testWidgets('valida ausencia de maiuscula', (tester) async {
      await tester.pumpWidget(
        buildTestApp(RegisterPage(authService: FakeAuthService())),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'novo@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), 'Novo');
      await tester.enterText(find.byType(TextFormField).at(2), 'password1!');
      await tester.enterText(find.byType(TextFormField).at(3), 'password1!');
      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      expect(
        find.text('A password deve ter pelo menos 1 letra maiúscula'),
        findsOneWidget,
      );
    });

    testWidgets('valida ausencia de numero', (tester) async {
      await tester.pumpWidget(
        buildTestApp(RegisterPage(authService: FakeAuthService())),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'novo@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), 'Novo');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password!');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password!');
      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      expect(
        find.text('A password deve ter pelo menos 1 número'),
        findsOneWidget,
      );
    });

    testWidgets('mostra erro de email ja registado', (tester) async {
      final auth = FakeAuthService(
        signUpError: FirebaseAuthException(code: 'email-already-in-use'),
      );

      await tester.pumpWidget(buildTestApp(RegisterPage(authService: auth)));

      await tester.enterText(find.byType(TextFormField).at(0), 'novo@sme.pt');
      await tester.enterText(find.byType(TextFormField).at(1), 'Novo');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');
      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      expect(find.text('Este email já está registado'), findsOneWidget);
    });
  });
}
