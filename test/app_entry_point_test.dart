import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smenergy/main.dart';

void main() {
  group('AppEntryPoint', () {
    testWidgets('mostra login quando nao existe sessao ativa', (tester) async {
      final session = FakeSessionStateService(isSignedIn: false);

      await tester.pumpWidget(
        MaterialApp(
          home: AppEntryPoint(
            sessionStateService: session,
            loginPageBuilder: (_) => const _PlaceholderPage('login'),
          ),
        ),
      );

      expect(find.text('login'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('reutiliza sessao ativa e abre dashboard', (tester) async {
      final session = FakeSessionStateService(
        isSignedIn: true,
        hasEquipment: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppEntryPoint(
            sessionStateService: session,
            loginPageBuilder: (_) => const _PlaceholderPage('login'),
            dashboardPageBuilder: (_) => const _PlaceholderPage('dashboard'),
            addEquipmentPageBuilder: (_) => const _PlaceholderPage('setup'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('dashboard'), findsOneWidget);
      expect(session.hasEquipmentChecks, 1);
    });

    testWidgets('reutiliza sessao ativa e abre setup quando falta equipamento', (
      tester,
    ) async {
      final session = FakeSessionStateService(
        isSignedIn: true,
        hasEquipment: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppEntryPoint(
            sessionStateService: session,
            loginPageBuilder: (_) => const _PlaceholderPage('login'),
            dashboardPageBuilder: (_) => const _PlaceholderPage('dashboard'),
            addEquipmentPageBuilder: (_) => const _PlaceholderPage('setup'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('setup'), findsOneWidget);
      expect(session.hasEquipmentChecks, 1);
    });
  });
}

class FakeSessionStateService implements SessionStateService {
  FakeSessionStateService({
    required this.isSignedIn,
    this.hasEquipment = false,
  });

  @override
  bool isSignedIn;

  final bool hasEquipment;
  int hasEquipmentChecks = 0;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> authChanges() => _controller.stream;

  @override
  Future<bool> hasEquipmentForCurrentUser() async {
    hasEquipmentChecks++;
    return hasEquipment;
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
