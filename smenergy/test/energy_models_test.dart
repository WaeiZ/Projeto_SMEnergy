import 'package:flutter_test/flutter_test.dart';
import 'package:smenergy/services/energy_data_service.dart';

void main() {
  group('EnergySensorSnapshot', () {
    test('calcula progresso, alerta e excesso corretamente', () {
      const sensor = EnergySensorSnapshot(
        id: 'sensor-1',
        name: 'Sensor Teste',
        watts: 750,
        limitWatts: 600,
        dailyKwh: 3.2,
        isOnline: true,
        lastReadingAt: null,
      );

      expect(sensor.progress, 1.0);
      expect(sensor.isAlert, isTrue);
      expect(sensor.excessWatts, 150);
    });
  });

  group('ElectricityCostProfile', () {
    test('calcula custo estimado para tarifa simples', () {
      const profile = ElectricityCostProfile(
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
      );

      expect(profile.totalMonthlyConsumptionKwh, 210);
      expect(profile.estimatedCostEur, 39.9);
      expect(profile.isConfigured, isTrue);
    });

    test('reconstroi perfil a partir de mapa com strings', () {
      final profile = ElectricityCostProfile.fromMap({
        'contract_type': 'bi_hourly',
        'peak_consumption_kwh': '120,5',
        'off_peak_consumption_kwh': '79.5',
        'peak_tariff': '0.25',
        'off_peak_tariff': '0.15',
        'peak_schedule': '08:00-22:00',
        'off_peak_schedule': '22:00-08:00',
      });

      expect(profile.contractType, ElectricityContractType.biHourly);
      expect(profile.totalMonthlyConsumptionKwh, 200);
      expect(profile.estimatedCostEur, closeTo(42.05, 0.0001));
      expect(profile.isConfigured, isTrue);
    });
  });

  group('GamificationProfile', () {
    test('determina nivel seguinte e progresso corretamente', () {
      final profile = GamificationProfile(points: 1600);

      expect(profile.level, GamificationLevel.volt);
      expect(profile.nextLevel, GamificationLevel.zeus);
      expect(profile.pointsToNext, 1400);
      expect(profile.progress, closeTo(0.0666, 0.001));
      expect(profile.progressPercent, 7);
    });

    test('marca nivel maximo quando o utilizador chega a zeus', () {
      final profile = GamificationProfile(points: 3200);

      expect(profile.level, GamificationLevel.zeus);
      expect(profile.nextLevel, isNull);
      expect(profile.progress, 1);
      expect(profile.pointsToNext, 0);
    });
  });
}
