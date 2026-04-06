import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/services/energy_data_service.dart';

import 'test_support.dart';

void main() {
  group('DashboardPage', () {
    testWidgets('mostra estado vazio quando nao existem leituras', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          DashboardPage(
            energyDataService: FakeEnergyDataService(
              dashboardStream: Stream<EnergyDashboardData>.value(
                const EnergyDashboardData.empty(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dashboard sem leituras'), findsOneWidget);
      expect(find.text('Conectividade'), findsOneWidget);
      expect(find.text('Sem dados'), findsOneWidget);
      expect(find.text('0.0 kWh'), findsOneWidget);
    });

    testWidgets('mostra metricas agregadas quando existem sensores', (
      tester,
    ) async {
      const data = EnergyDashboardData(
        sensors: [
          EnergySensorSnapshot(
            id: 's1',
            name: 'Sensor Sala',
            watts: 720,
            limitWatts: 600,
            dailyKwh: 4.2,
            isOnline: true,
            lastReadingAt: null,
          ),
          EnergySensorSnapshot(
            id: 's2',
            name: 'Sensor Cozinha',
            watts: 180,
            limitWatts: 500,
            dailyKwh: 1.3,
            isOnline: false,
            lastReadingAt: null,
          ),
        ],
        chartPoints: [
          EnergyChartPoint(x: 0, y: 0.4),
          EnergyChartPoint(x: 3, y: 0.6),
          EnergyChartPoint(x: 6, y: 0.8),
        ],
        totalDayKwh: 5.5,
      );

      await tester.pumpWidget(
        buildTestApp(
          DashboardPage(
            energyDataService: FakeEnergyDataService(
              dashboardStream: Stream<EnergyDashboardData>.value(data),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sensor Sala'), findsOneWidget);
      expect(find.text('720 W'), findsOneWidget);
      expect(find.text('Consumo ao longo do dia'), findsOneWidget);
      expect(find.text('5.5 kWh'), findsOneWidget);
      expect(find.text('Parcial'), findsOneWidget);
      expect(find.text('1/2 sensores online'), findsOneWidget);
    });
  });
}
