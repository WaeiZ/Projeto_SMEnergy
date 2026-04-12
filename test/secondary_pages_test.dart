import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/add_equipment_page.dart';
import 'package:smenergy/pages/add_equipment_page_2.dart';
import 'package:smenergy/pages/add_equipment_page_3.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/electricity_settings_page.dart';
import 'package:smenergy/pages/login_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/services/device_provisioning_service.dart';
import 'package:smenergy/services/energy_data_service.dart';

import 'test_support.dart';

void main() {
  group('Paginas principais', () {
    testWidgets('HistoryPage mostra estado vazio sem sensores', (tester) async {
      final energy = FakeEnergyDataService(sensors: const []);

      await tester.pumpWidget(
        buildTestApp(HistoryPage(energyDataService: energy)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sem sensores'), findsOneWidget);
    });

    testWidgets('AlertPage mostra alerta ativo e permite verificar', (
      tester,
    ) async {
      final energy = FakeEnergyDataService(
        alertStream: Stream<EnergyAlertData>.value(
          const EnergyAlertData(
            statuses: [
              EnergySensorStatus(sensorName: 'Sensor Sala', isAlert: true),
            ],
            activeAlert: EnergyActiveAlert(
              sensorName: 'Sensor Sala',
              title: 'Sensor Sala: Consumo anómalo',
              description:
                  'Sensor Sala está com 120 W acima do limite configurado.',
              rewardPoints: 42,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(AlertPage(energyDataService: energy)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('necessária'), findsOneWidget);
      expect(find.text('Sensor Sala'), findsWidgets);

      await tester.ensureVisible(find.text('Verificar'));
      await tester.tap(find.text('Verificar'));
      await tester.pump();

      expect(find.textContaining('42'), findsWidgets);
    });

    testWidgets('ProfilePage abre sem crash e faz logout', (tester) async {
      final auth = FakeAuthService();
      final energy = FakeEnergyDataService(
        gamificationProfile: GamificationProfile(points: 1600),
        electricityProfile: const ElectricityCostProfile(
          contractType: ElectricityContractType.simple,
          monthlyConsumptionKwh: 210,
          simpleTariff: 0.19,
          peakConsumptionKwh: 0,
          offPeakConsumptionKwh: 0,
          superOffPeakConsumptionKwh: 0,
          peakTariff: 0,
          offPeakTariff: 0,
          superOffPeakTariff: 0,
          peakSchedule: '',
          offPeakSchedule: '',
          superOffPeakSchedule: '',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(ProfilePage(authService: auth, energyDataService: energy)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perfil'), findsWidgets);
      expect(find.text('Volt'), findsOneWidget);

      await tester.ensureVisible(find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(auth.signOutCalls, 1);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('ElectricitySettingsPage valida campos obrigatorios', (
      tester,
    ) async {
      final energy = FakeEnergyDataService();

      await tester.pumpWidget(
        buildTestApp(ElectricitySettingsPage(energyDataService: energy)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('Guardar'));
      await tester.tap(find.textContaining('Guardar'));
      await tester.pump();

      expect(find.textContaining('consumo mensal'), findsOneWidget);
    });

    testWidgets('ElectricitySettingsPage guarda configuracao simples', (
      tester,
    ) async {
      final energy = FakeEnergyDataService();

      await tester.pumpWidget(
        buildTestApp(ElectricitySettingsPage(energyDataService: energy)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '250');
      await tester.enterText(find.byType(TextField).at(1), '0,21');
      await tester.ensureVisible(find.textContaining('Guardar'));
      await tester.tap(find.textContaining('Guardar'));
      await tester.pumpAndSettle();

      expect(energy.saveElectricityCalls, 1);
    });
  });

  group('Onboarding equipamento', () {
    testWidgets('AddEquipmentPage navega para o passo 1', (tester) async {
      await tester.pumpWidget(buildTestApp(const AddEquipmentPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(SetupStepOnePage), findsOneWidget);
    });

    testWidgets('SetupStepOnePage mostra erro quando nao abre wifi settings', (
      tester,
    ) async {
      final wifi = FakeWifiSettingsService(result: false);
      final provisioning = FakeDeviceProvisioningService();

      await tester.pumpWidget(
        buildTestApp(
          SetupStepOnePage(
            wifiSettingsService: wifi,
            provisioningService: provisioning,
          ),
        ),
      );

      await tester.tap(find.text('SMEnergy_AP'));
      await tester.pump();

      expect(
        find.text(
          'Não foi possível abrir as definições de Wi-Fi automaticamente.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'SetupStepOnePage navega para passo 2 quando dispositivo responde',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(900, 1200));

        final wifi = FakeWifiSettingsService(result: true);
        final provisioning = FakeDeviceProvisioningService(isReachable: true);

        await tester.pumpWidget(
          buildTestApp(
            SetupStepOnePage(
              wifiSettingsService: wifi,
              provisioningService: provisioning,
            ),
          ),
        );

        await tester.tap(find.textContaining('continuar'));
        await tester.pumpAndSettle();

        expect(find.byType(SetupStepTwoPage), findsOneWidget);
      },
    );

    testWidgets('SetupStepTwoPage valida ssid vazio', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 1200));

      await tester.pumpWidget(
        buildTestApp(
          SetupStepTwoPage(
            provisioningService: FakeDeviceProvisioningService(),
            energyDataService: FakeEnergyDataService(),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Conectar'));
      await tester.tap(find.text('Conectar'));
      await tester.pump();

      expect(find.text('Preenche o SSID da tua rede Wi-Fi.'), findsOneWidget);
    });

    testWidgets('SetupStepTwoPage conclui configuracao com sucesso', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 1200));

      final provisioning = FakeDeviceProvisioningService(
        result: const DeviceProvisioningResult(
          success: true,
          message: 'Configuração enviada',
        ),
      );
      final energy = FakeEnergyDataService(waitForTelemetryResult: true);
      int? configuredStatus;

      await tester.pumpWidget(
        buildTestApp(
          SetupStepTwoPage(
            provisioningService: provisioning,
            energyDataService: energy,
            setConfigStatus: (status) async => configuredStatus = status,
            successPageBuilder: (_) =>
                const Scaffold(body: Text('Dashboard onboarding')),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'CasaWifi');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1!');
      await tester.ensureVisible(find.text('Conectar'));
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();

      expect(find.text('Continuar'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(configuredStatus, 1);
      expect(find.text('Dashboard onboarding'), findsOneWidget);
    });
  });
}
