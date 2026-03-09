import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnergySensorSnapshot {
  const EnergySensorSnapshot({
    required this.id,
    required this.name,
    required this.watts,
    required this.limitWatts,
    required this.dailyKwh,
    required this.isOnline,
  });

  final String id;
  final String name;
  final double watts;
  final double limitWatts;
  final double dailyKwh;
  final bool isOnline;

  double get progress => (watts / limitWatts).clamp(0.0, 1.0).toDouble();
  bool get isAlert => watts > limitWatts;
  double get excessWatts => max(0, watts - limitWatts);
}

class EnergyChartPoint {
  const EnergyChartPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class EnergyDashboardData {
  const EnergyDashboardData({
    required this.sensors,
    required this.chartPoints,
    required this.totalDayKwh,
  });

  const EnergyDashboardData.empty()
    : sensors = const [],
      chartPoints = const [],
      totalDayKwh = 0;

  final List<EnergySensorSnapshot> sensors;
  final List<EnergyChartPoint> chartPoints;
  final double totalDayKwh;
}

class EnergySensorOption {
  const EnergySensorOption({required this.id, required this.name});

  final String id;
  final String name;
}

class EnergySensorSettings {
  const EnergySensorSettings({
    required this.id,
    required this.name,
    required this.limitWatts,
  });

  final String id;
  final String name;
  final double limitWatts;
}

enum ElectricityContractType {
  simple('simple', 'Simples'),
  biHourly('bi_hourly', 'Bi-horário'),
  triHourly('tri_hourly', 'Tri-horário');

  const ElectricityContractType(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static ElectricityContractType fromStorage(String? value) {
    for (final type in ElectricityContractType.values) {
      if (type.storageKey == value) {
        return type;
      }
    }
    return ElectricityContractType.simple;
  }
}

class ElectricityCostProfile {
  const ElectricityCostProfile({
    required this.contractType,
    required this.monthlyConsumptionKwh,
    required this.simpleTariff,
    required this.peakConsumptionKwh,
    required this.offPeakConsumptionKwh,
    required this.superOffPeakConsumptionKwh,
    required this.peakTariff,
    required this.offPeakTariff,
    required this.superOffPeakTariff,
    required this.peakSchedule,
    required this.offPeakSchedule,
    required this.superOffPeakSchedule,
  });

  const ElectricityCostProfile.empty()
    : contractType = ElectricityContractType.simple,
      monthlyConsumptionKwh = 0,
      simpleTariff = 0,
      peakConsumptionKwh = 0,
      offPeakConsumptionKwh = 0,
      superOffPeakConsumptionKwh = 0,
      peakTariff = 0,
      offPeakTariff = 0,
      superOffPeakTariff = 0,
      peakSchedule = '',
      offPeakSchedule = '',
      superOffPeakSchedule = '';

  final ElectricityContractType contractType;
  final double monthlyConsumptionKwh;
  final double simpleTariff;
  final double peakConsumptionKwh;
  final double offPeakConsumptionKwh;
  final double superOffPeakConsumptionKwh;
  final double peakTariff;
  final double offPeakTariff;
  final double superOffPeakTariff;
  final String peakSchedule;
  final String offPeakSchedule;
  final String superOffPeakSchedule;

  double get totalMonthlyConsumptionKwh {
    switch (contractType) {
      case ElectricityContractType.simple:
        return monthlyConsumptionKwh;
      case ElectricityContractType.biHourly:
        return peakConsumptionKwh + offPeakConsumptionKwh;
      case ElectricityContractType.triHourly:
        return peakConsumptionKwh +
            offPeakConsumptionKwh +
            superOffPeakConsumptionKwh;
    }
  }

  double get estimatedCostEur {
    switch (contractType) {
      case ElectricityContractType.simple:
        return monthlyConsumptionKwh * simpleTariff;
      case ElectricityContractType.biHourly:
        return (peakConsumptionKwh * peakTariff) +
            (offPeakConsumptionKwh * offPeakTariff);
      case ElectricityContractType.triHourly:
        return (peakConsumptionKwh * peakTariff) +
            (offPeakConsumptionKwh * offPeakTariff) +
            (superOffPeakConsumptionKwh * superOffPeakTariff);
    }
  }

  bool get isConfigured {
    switch (contractType) {
      case ElectricityContractType.simple:
        return monthlyConsumptionKwh > 0 && simpleTariff > 0;
      case ElectricityContractType.biHourly:
        return totalMonthlyConsumptionKwh > 0 &&
            peakTariff > 0 &&
            offPeakTariff > 0;
      case ElectricityContractType.triHourly:
        return totalMonthlyConsumptionKwh > 0 &&
            peakTariff > 0 &&
            offPeakTariff > 0 &&
            superOffPeakTariff > 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'contract_type': contractType.storageKey,
      'monthly_consumption_kwh': monthlyConsumptionKwh,
      'simple_tariff': simpleTariff,
      'peak_consumption_kwh': peakConsumptionKwh,
      'off_peak_consumption_kwh': offPeakConsumptionKwh,
      'super_off_peak_consumption_kwh': superOffPeakConsumptionKwh,
      'peak_tariff': peakTariff,
      'off_peak_tariff': offPeakTariff,
      'super_off_peak_tariff': superOffPeakTariff,
      'peak_schedule': peakSchedule.trim(),
      'off_peak_schedule': offPeakSchedule.trim(),
      'super_off_peak_schedule': superOffPeakSchedule.trim(),
      'total_consumption_kwh': totalMonthlyConsumptionKwh,
      'estimated_cost_eur': double.parse(estimatedCostEur.toStringAsFixed(2)),
    };
  }

  factory ElectricityCostProfile.fromMap(Map<String, dynamic> data) {
    return ElectricityCostProfile(
      contractType: ElectricityContractType.fromStorage(
        data['contract_type']?.toString(),
      ),
      monthlyConsumptionKwh: _readDouble(data['monthly_consumption_kwh']),
      simpleTariff: _readDouble(data['simple_tariff']),
      peakConsumptionKwh: _readDouble(data['peak_consumption_kwh']),
      offPeakConsumptionKwh: _readDouble(data['off_peak_consumption_kwh']),
      superOffPeakConsumptionKwh: _readDouble(
        data['super_off_peak_consumption_kwh'],
      ),
      peakTariff: _readDouble(data['peak_tariff']),
      offPeakTariff: _readDouble(data['off_peak_tariff']),
      superOffPeakTariff: _readDouble(data['super_off_peak_tariff']),
      peakSchedule: _readString(data['peak_schedule']),
      offPeakSchedule: _readString(data['off_peak_schedule']),
      superOffPeakSchedule: _readString(data['super_off_peak_schedule']),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}

class EnergyHistoryData {
  const EnergyHistoryData({
    required this.labels,
    required this.values,
    required this.averageWatts,
    required this.maxWatts,
    required this.minWatts,
    required this.totalKwh,
    required this.sampleCount,
    required this.estimatedCostEur,
    required this.costConfigured,
    required this.contractLabel,
  });

  const EnergyHistoryData.empty()
    : labels = const [],
      values = const [],
      averageWatts = 0,
      maxWatts = 0,
      minWatts = 0,
      totalKwh = 0,
      sampleCount = 0,
      estimatedCostEur = 0,
      costConfigured = false,
      contractLabel = '';

  final List<String> labels;
  final List<double> values;
  final double averageWatts;
  final double maxWatts;
  final double minWatts;
  final double totalKwh;
  final int sampleCount;
  final double estimatedCostEur;
  final bool costConfigured;
  final String contractLabel;
}

class EnergySensorStatus {
  const EnergySensorStatus({required this.sensorName, required this.isAlert});

  final String sensorName;
  final bool isAlert;

  String get statusLabel => isAlert ? 'Alerta' : 'OK';
}

class EnergyActiveAlert {
  const EnergyActiveAlert({
    required this.sensorName,
    required this.title,
    required this.description,
    required this.rewardPoints,
  });

  final String sensorName;
  final String title;
  final String description;
  final int rewardPoints;
}

class EnergyAlertData {
  const EnergyAlertData({required this.statuses, this.activeAlert});

  const EnergyAlertData.empty() : statuses = const [], activeAlert = null;

  final List<EnergySensorStatus> statuses;
  final EnergyActiveAlert? activeAlert;
}

class EnergyDataService {
  EnergyDataService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration _defaultPollInterval = Duration(seconds: 15);

  Stream<EnergyDashboardData> streamDashboardData({
    Duration interval = _defaultPollInterval,
  }) async* {
    while (true) {
      yield await fetchDashboardData();
      await Future<void>.delayed(interval);
    }
  }

  Future<EnergyDashboardData> fetchDashboardData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const EnergyDashboardData.empty();
    }

    final deviceRef = await _resolveActiveDeviceRef(uid);
    if (deviceRef == null) {
      return const EnergyDashboardData.empty();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    const bucketHours = <int>[0, 3, 6, 9, 12, 15, 18, 21];
    const fallbackMultiplier = <double>[
      0.52,
      0.46,
      0.5,
      0.63,
      0.78,
      0.9,
      1.0,
      0.84,
    ];
    final bucketKwTotals = List<double>.filled(bucketHours.length, 0);

    final sensorDocs = await deviceRef.collection('sensors').get();
    final sensors = <EnergySensorSnapshot>[];

    for (final sensorDoc in sensorDocs.docs) {
      if (!_isDataDocument(sensorDoc)) continue;
      final data = sensorDoc.data();
      final name = _sensorName(data, fallback: sensorDoc.id);
      final limitWatts = _asDouble(
        data['limit_watts'] ?? data['limitWatts'],
        fallback: 600,
      );

      final dayReadings = await _fetchReadingsRange(
        sensorDoc.reference,
        start: startOfDay,
        end: now,
      );
      final latest = dayReadings.isNotEmpty
          ? dayReadings.last
          : await _fetchLatestReading(sensorDoc.reference);

      final currentWatts =
          latest?.watts ??
          _asDouble(
            data['current_watts'] ?? data['watts'] ?? data['value'],
            fallback: 0,
          );

      final lastReadingAt =
          latest?.timestamp ??
          _asDateTime(data['last_reading_at'] ?? data['updated_at']);
      final explicitOnline = data['is_online'];
      final isOnline = explicitOnline is bool
          ? explicitOnline
          : (lastReadingAt != null &&
                now.difference(lastReadingAt) <= const Duration(minutes: 15));

      final hoursToday = max(1.0, now.difference(startOfDay).inMinutes / 60);
      final avgWattsToday = dayReadings.isEmpty
          ? currentWatts
          : dayReadings.fold<double>(0, (acc, r) => acc + r.watts) /
                dayReadings.length;
      final dailyKwh = (avgWattsToday / 1000) * hoursToday;

      final sensorBucket = List<_BucketAccumulator>.generate(
        bucketHours.length,
        (_) => _BucketAccumulator(),
      );
      for (final reading in dayReadings) {
        final index = min(7, reading.timestamp.hour ~/ 3);
        sensorBucket[index].add(reading.watts);
      }
      for (int i = 0; i < bucketKwTotals.length; i++) {
        final bucketKw = sensorBucket[i].count == 0
            ? (currentWatts / 1000) * fallbackMultiplier[i]
            : (sensorBucket[i].average / 1000);
        bucketKwTotals[i] += bucketKw;
      }

      sensors.add(
        EnergySensorSnapshot(
          id: sensorDoc.id,
          name: name,
          watts: currentWatts,
          limitWatts: limitWatts,
          dailyKwh: double.parse(dailyKwh.toStringAsFixed(1)),
          isOnline: isOnline,
        ),
      );
    }

    sensors.sort((a, b) => a.name.compareTo(b.name));
    final chartPoints = List.generate(
      bucketHours.length,
      (i) => EnergyChartPoint(
        x: bucketHours[i].toDouble(),
        y: double.parse(bucketKwTotals[i].toStringAsFixed(2)),
      ),
    );
    final totalDayKwh = sensors.fold<double>(
      0,
      (acc, sensor) => acc + sensor.dailyKwh,
    );

    return EnergyDashboardData(
      sensors: sensors,
      chartPoints: chartPoints,
      totalDayKwh: double.parse(totalDayKwh.toStringAsFixed(1)),
    );
  }

  Future<List<EnergySensorOption>> fetchSensors() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const [];
    }

    final deviceRef = await _resolveActiveDeviceRef(uid);
    if (deviceRef == null) {
      return const [];
    }

    final snapshot = await deviceRef.collection('sensors').get();
    final sensors = snapshot.docs
        .where(_isDataDocument)
        .map(
          (doc) => EnergySensorOption(
            id: doc.id,
            name: _sensorName(doc.data(), fallback: doc.id),
          ),
        )
        .toList(growable: false);

    sensors.sort((a, b) => a.name.compareTo(b.name));
    return sensors;
  }

  Future<ElectricityCostProfile> fetchElectricityCostProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const ElectricityCostProfile.empty();
    }

    final snapshot = await _db.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return const ElectricityCostProfile.empty();
    }

    final raw = data['electricity_profile'];
    if (raw is Map<String, dynamic>) {
      return ElectricityCostProfile.fromMap(raw);
    }
    if (raw is Map) {
      return ElectricityCostProfile.fromMap(raw.cast<String, dynamic>());
    }
    return const ElectricityCostProfile.empty();
  }

  Future<void> saveElectricityCostProfile(
    ElectricityCostProfile profile,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilizador não autenticado.');
    }

    final data = profile.toMap();
    data['updated_at'] = FieldValue.serverTimestamp();

    await _db.collection('users').doc(uid).set({
      'electricity_profile': data,
    }, SetOptions(merge: true));
  }

  Future<List<EnergySensorSettings>> fetchSensorSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const [];
    }

    final deviceRef = await _resolveActiveDeviceRef(uid);
    if (deviceRef == null) {
      return const [];
    }

    final snapshot = await deviceRef.collection('sensors').get();
    final sensors = snapshot.docs
        .where(_isDataDocument)
        .map(
          (doc) => EnergySensorSettings(
            id: doc.id,
            name: _sensorName(doc.data(), fallback: doc.id),
            limitWatts: _asDouble(
              doc.data()['limit_watts'] ?? doc.data()['limitWatts'],
              fallback: 600,
            ),
          ),
        )
        .toList(growable: false);

    sensors.sort((a, b) => a.name.compareTo(b.name));
    return sensors;
  }

  Future<void> updateSensorSettings(List<EnergySensorSettings> updates) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilizador não autenticado.');
    }

    final deviceRef = await _resolveActiveDeviceRef(uid);
    if (deviceRef == null) {
      throw StateError('Dispositivo não encontrado.');
    }

    final batch = _db.batch();
    for (final sensor in updates) {
      final cleanName = sensor.name.trim().isEmpty
          ? sensor.id
          : sensor.name.trim();
      final safeLimit = sensor.limitWatts <= 0 ? 1.0 : sensor.limitWatts;
      final sensorRef = deviceRef.collection('sensors').doc(sensor.id);
      batch.set(sensorRef, {
        'name': cleanName,
        'sensor_name': cleanName,
        'limit_watts': safeLimit,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> unpairActiveDeviceAndRequestReset() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilizador não autenticado.');
    }

    final deviceRef = await _resolveActiveDeviceRef(uid);
    if (deviceRef == null) {
      throw StateError('Dispositivo não encontrado.');
    }

    await deviceRef.set({
      'command': 'reset',
      'placeholder': true,
      'is_online': false,
      'unpaired_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<EnergyHistoryData> fetchHistory({
    required String sensorId,
    required String measure,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const EnergyHistoryData.empty();
    }

    final deviceRef = await _resolveActiveDeviceRef(uid);
    if (deviceRef == null) {
      return const EnergyHistoryData.empty();
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final readings = await _fetchReadingsRange(
      deviceRef.collection('sensors').doc(sensorId),
      start: start,
      end: end,
    );
    final profile = await fetchElectricityCostProfile();

    final samples = readings
        .map((reading) => reading.watts)
        .toList(growable: false);
    final sampleCount = samples.length;
    final averageWatts = sampleCount == 0
        ? 0.0
        : samples.fold<double>(0, (acc, value) => acc + value) / sampleCount;
    final maxWatts = sampleCount == 0 ? 0.0 : samples.reduce(max);
    final minWatts = sampleCount == 0 ? 0.0 : samples.reduce(min);
    final tariffBreakdown = _estimateTariffEnergyBreakdown(
      readings,
      start: start,
      end: end,
      profile: profile,
    );
    final totalKwh = tariffBreakdown.totalKwh;
    final costConfigured = profile.isConfigured;
    final estimatedCostEur = costConfigured
        ? _estimateCostFromBreakdown(tariffBreakdown, profile)
        : 0.0;

    final byDay = <DateTime, List<_ReadingSample>>{};
    for (final reading in readings) {
      final day = DateTime(
        reading.timestamp.year,
        reading.timestamp.month,
        reading.timestamp.day,
      );
      byDay.putIfAbsent(day, () => <_ReadingSample>[]).add(reading);
    }

    final labels = <String>[];
    final values = <double>[];
    DateTime cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(endDay)) {
      final dayStart = cursor;
      final dayEnd = _endOfDay(cursor);
      final samples = byDay[cursor] ?? const <_ReadingSample>[];
      labels.add(_formatDayLabel(cursor));
      values.add(
        _applyHistoryMeasure(
          samples,
          measure: measure,
          start: dayStart,
          end: dayEnd,
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    if (labels.length > 8) {
      final compactData = _aggregateHistoryByBuckets(
        byDay,
        start: start,
        end: endDay,
        measure: measure,
      );
      return EnergyHistoryData(
        labels: compactData.labels,
        values: compactData.values,
        averageWatts: double.parse(averageWatts.toStringAsFixed(1)),
        maxWatts: double.parse(maxWatts.toStringAsFixed(1)),
        minWatts: double.parse(minWatts.toStringAsFixed(1)),
        totalKwh: double.parse(totalKwh.toStringAsFixed(2)),
        sampleCount: sampleCount,
        estimatedCostEur: double.parse(estimatedCostEur.toStringAsFixed(2)),
        costConfigured: costConfigured,
        contractLabel: profile.contractType.label,
      );
    }

    return EnergyHistoryData(
      labels: labels,
      values: values,
      averageWatts: double.parse(averageWatts.toStringAsFixed(1)),
      maxWatts: double.parse(maxWatts.toStringAsFixed(1)),
      minWatts: double.parse(minWatts.toStringAsFixed(1)),
      totalKwh: double.parse(totalKwh.toStringAsFixed(2)),
      sampleCount: sampleCount,
      estimatedCostEur: double.parse(estimatedCostEur.toStringAsFixed(2)),
      costConfigured: costConfigured,
      contractLabel: profile.contractType.label,
    );
  }

  Stream<EnergyAlertData> streamAlertData({
    Duration interval = _defaultPollInterval,
  }) async* {
    await for (final dashboard in streamDashboardData(interval: interval)) {
      yield _buildAlertData(dashboard.sensors);
    }
  }

  _HistorySeriesData _aggregateHistoryByBuckets(
    Map<DateTime, List<_ReadingSample>> byDay, {
    required DateTime start,
    required DateTime end,
    required String measure,
    int maxPoints = 7,
  }) {
    final totalDays = end.difference(start).inDays + 1;
    final bucketSize = max(1, (totalDays / maxPoints).ceil());
    final labels = <String>[];
    final values = <double>[];

    DateTime bucketStart = start;
    while (!bucketStart.isAfter(end)) {
      final bucketEndCandidate = bucketStart.add(
        Duration(days: bucketSize - 1),
      );
      final bucketEnd = bucketEndCandidate.isAfter(end)
          ? end
          : bucketEndCandidate;

      final bucketSamples = <_ReadingSample>[];
      DateTime day = bucketStart;
      while (!day.isAfter(bucketEnd)) {
        bucketSamples.addAll(byDay[day] ?? const <_ReadingSample>[]);
        day = day.add(const Duration(days: 1));
      }

      labels.add(_formatBucketLabel(bucketStart, bucketEnd));
      values.add(
        _applyHistoryMeasure(
          bucketSamples,
          measure: measure,
          start: bucketStart,
          end: _endOfDay(bucketEnd),
        ),
      );
      bucketStart = bucketEnd.add(const Duration(days: 1));
    }

    return _HistorySeriesData(labels: labels, values: values);
  }

  String _formatBucketLabel(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return _formatDayLabel(start);
    }

    if (start.year == end.year && start.month == end.month) {
      final startDay = start.day.toString().padLeft(2, '0');
      final endDay = end.day.toString().padLeft(2, '0');
      final month = start.month.toString().padLeft(2, '0');
      return '$startDay-$endDay/$month';
    }

    return '${_formatDayLabel(start)}-${_formatDayLabel(end)}';
  }

  EnergyAlertData _buildAlertData(List<EnergySensorSnapshot> sensors) {
    final statuses = sensors
        .map(
          (sensor) => EnergySensorStatus(
            sensorName: sensor.name,
            isAlert: sensor.isAlert,
          ),
        )
        .toList(growable: false);

    EnergySensorSnapshot? worst;
    for (final sensor in sensors) {
      if (!sensor.isAlert) continue;
      if (worst == null || sensor.excessWatts > worst.excessWatts) {
        worst = sensor;
      }
    }

    if (worst == null) {
      return EnergyAlertData(statuses: statuses, activeAlert: null);
    }

    final excess = worst.excessWatts.round();
    return EnergyAlertData(
      statuses: statuses,
      activeAlert: EnergyActiveAlert(
        sensorName: worst.name,
        title: '${worst.name}: Consumo anómalo',
        description:
            '${worst.name} está com $excess W acima do limite configurado.',
        rewardPoints: 30 + (excess ~/ 10),
      ),
    );
  }

  Future<DocumentReference<Map<String, dynamic>>?> _resolveActiveDeviceRef(
    String uid,
  ) async {
    final devicesRef = _db.collection('users').doc(uid).collection('devices');
    final snapshot = await devicesRef.get();
    for (final doc in snapshot.docs) {
      if (_isDataDocument(doc)) {
        return doc.reference;
      }
    }
    return null;
  }

  bool _isDataDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final placeholder = data['placeholder'] == true;
    return doc.id != '_meta' && !placeholder;
  }

  String _sensorName(Map<String, dynamic> data, {required String fallback}) {
    final raw = (data['name'] ?? data['sensor_name'])?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    return raw;
  }

  Future<_ReadingSample?> _fetchLatestReading(
    DocumentReference<Map<String, dynamic>> sensorRef,
  ) async {
    try {
      final snapshot = await sensorRef
          .collection('readings')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      for (final doc in snapshot.docs) {
        final reading = _toReadingSample(doc.data());
        if (reading != null) return reading;
      }
    } catch (_) {
      // fallback below
    }

    try {
      final snapshot = await sensorRef
          .collection('readings')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();
      for (final doc in snapshot.docs) {
        final reading = _toReadingSample(doc.data());
        if (reading != null) return reading;
      }
    } catch (_) {
      // keep null
    }

    return null;
  }

  Future<List<_ReadingSample>> _fetchReadingsRange(
    DocumentReference<Map<String, dynamic>> sensorRef, {
    required DateTime start,
    required DateTime end,
  }) async {
    final query = await sensorRef
        .collection('readings')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp')
        .get();

    final readings = <_ReadingSample>[];
    for (final doc in query.docs) {
      final reading = _toReadingSample(doc.data());
      if (reading != null) {
        readings.add(reading);
      }
    }
    return readings;
  }

  _ReadingSample? _toReadingSample(Map<String, dynamic> data) {
    final timestamp = _asDateTime(
      data['timestamp'] ?? data['created_at'] ?? data['time'],
    );
    if (timestamp == null) return null;

    final watts = _asDouble(
      data['watts'] ??
          data['power_w'] ??
          data['power'] ??
          data['value'] ??
          data['current_watts'],
      fallback: 0,
    );
    return _ReadingSample(timestamp: timestamp, watts: watts);
  }

  double _applyHistoryMeasure(
    List<_ReadingSample> readings, {
    required String measure,
    required DateTime start,
    required DateTime end,
  }) {
    if (readings.isEmpty) return 0;

    if (measure == 'Energia gasta (kWh)') {
      return _estimateEnergyKwh(readings, start: start, end: end);
    }

    final samples = readings.map((reading) => reading.watts).toList();
    return _applyMeasure(samples, measure);
  }

  double _applyMeasure(List<double> samples, String measure) {
    if (samples.isEmpty) return 0;

    switch (measure) {
      case 'Máximo (W)':
        return samples.reduce(max);
      case 'Mínimo (W)':
        return samples.reduce(min);
      case 'Média (W)':
      default:
        final avg =
            samples.fold<double>(0, (acc, value) => acc + value) /
            samples.length;
        return avg;
    }
  }

  DateTime _endOfDay(DateTime day) {
    return DateTime(day.year, day.month, day.day, 23, 59, 59);
  }

  _TariffEnergyBreakdown _estimateTariffEnergyBreakdown(
    List<_ReadingSample> readings, {
    required DateTime start,
    required DateTime end,
    required ElectricityCostProfile profile,
  }) {
    if (readings.isEmpty || !end.isAfter(start)) {
      return const _TariffEnergyBreakdown();
    }

    switch (profile.contractType) {
      case ElectricityContractType.simple:
        return _TariffEnergyBreakdown(
          offPeakKwh: _estimateEnergyKwh(readings, start: start, end: end),
        );
      case ElectricityContractType.biHourly:
        final peakWindows = _parseTimeWindows(profile.peakSchedule);
        final offPeakWindows = _parseTimeWindows(profile.offPeakSchedule);
        if (peakWindows.isEmpty && offPeakWindows.isEmpty) {
          return _estimateBreakdownFromConfiguredRatios(
            totalKwh: _estimateEnergyKwh(readings, start: start, end: end),
            peakKwh: profile.peakConsumptionKwh,
            offPeakKwh: profile.offPeakConsumptionKwh,
          );
        }
        return _estimateBreakdownFromSegments(
          readings,
          start: start,
          end: end,
          classify: (timestamp) {
            if (_matchesAnyWindow(timestamp, peakWindows)) {
              return _TariffPeriod.peak;
            }
            if (_matchesAnyWindow(timestamp, offPeakWindows)) {
              return _TariffPeriod.offPeak;
            }
            return _TariffPeriod.offPeak;
          },
        );
      case ElectricityContractType.triHourly:
        final peakWindows = _parseTimeWindows(profile.peakSchedule);
        final offPeakWindows = _parseTimeWindows(profile.offPeakSchedule);
        final superOffPeakWindows = _parseTimeWindows(
          profile.superOffPeakSchedule,
        );
        if (peakWindows.isEmpty &&
            offPeakWindows.isEmpty &&
            superOffPeakWindows.isEmpty) {
          return _estimateBreakdownFromConfiguredRatios(
            totalKwh: _estimateEnergyKwh(readings, start: start, end: end),
            peakKwh: profile.peakConsumptionKwh,
            offPeakKwh: profile.offPeakConsumptionKwh,
            superOffPeakKwh: profile.superOffPeakConsumptionKwh,
          );
        }
        return _estimateBreakdownFromSegments(
          readings,
          start: start,
          end: end,
          classify: (timestamp) {
            if (_matchesAnyWindow(timestamp, peakWindows)) {
              return _TariffPeriod.peak;
            }
            if (_matchesAnyWindow(timestamp, superOffPeakWindows)) {
              return _TariffPeriod.superOffPeak;
            }
            if (_matchesAnyWindow(timestamp, offPeakWindows)) {
              return _TariffPeriod.offPeak;
            }
            return _TariffPeriod.offPeak;
          },
        );
    }
  }

  _TariffEnergyBreakdown _estimateBreakdownFromConfiguredRatios({
    required double totalKwh,
    required double peakKwh,
    required double offPeakKwh,
    double superOffPeakKwh = 0,
  }) {
    final configuredTotal = peakKwh + offPeakKwh + superOffPeakKwh;
    if (configuredTotal <= 0) {
      return _TariffEnergyBreakdown(offPeakKwh: totalKwh);
    }

    return _TariffEnergyBreakdown(
      peakKwh: totalKwh * (peakKwh / configuredTotal),
      offPeakKwh: totalKwh * (offPeakKwh / configuredTotal),
      superOffPeakKwh: totalKwh * (superOffPeakKwh / configuredTotal),
    );
  }

  _TariffEnergyBreakdown _estimateBreakdownFromSegments(
    List<_ReadingSample> readings, {
    required DateTime start,
    required DateTime end,
    required _TariffPeriod Function(DateTime timestamp) classify,
  }) {
    if (readings.isEmpty || !end.isAfter(start)) {
      return const _TariffEnergyBreakdown();
    }

    double peakKwh = 0;
    double offPeakKwh = 0;
    double superOffPeakKwh = 0;

    for (int i = 0; i < readings.length; i++) {
      final current = readings[i];
      final segmentStart = i == 0 ? start : readings[i].timestamp;
      final rawSegmentEnd = i + 1 < readings.length
          ? readings[i + 1].timestamp
          : end;
      final segmentEnd = rawSegmentEnd.isAfter(end) ? end : rawSegmentEnd;
      if (!segmentEnd.isAfter(segmentStart)) continue;

      final hours = segmentEnd.difference(segmentStart).inMinutes / 60;
      final kwh = (current.watts / 1000) * hours;
      switch (classify(current.timestamp)) {
        case _TariffPeriod.peak:
          peakKwh += kwh;
          break;
        case _TariffPeriod.offPeak:
          offPeakKwh += kwh;
          break;
        case _TariffPeriod.superOffPeak:
          superOffPeakKwh += kwh;
          break;
      }
    }

    return _TariffEnergyBreakdown(
      peakKwh: peakKwh,
      offPeakKwh: offPeakKwh,
      superOffPeakKwh: superOffPeakKwh,
    );
  }

  double _estimateEnergyKwh(
    List<_ReadingSample> readings, {
    required DateTime start,
    required DateTime end,
  }) {
    return _estimateBreakdownFromSegments(
      readings,
      start: start,
      end: end,
      classify: (_) => _TariffPeriod.offPeak,
    ).totalKwh;
  }

  double _estimateCostFromBreakdown(
    _TariffEnergyBreakdown breakdown,
    ElectricityCostProfile profile,
  ) {
    switch (profile.contractType) {
      case ElectricityContractType.simple:
        return breakdown.totalKwh * profile.simpleTariff;
      case ElectricityContractType.biHourly:
        return (breakdown.peakKwh * profile.peakTariff) +
            (breakdown.offPeakKwh * profile.offPeakTariff);
      case ElectricityContractType.triHourly:
        return (breakdown.peakKwh * profile.peakTariff) +
            (breakdown.offPeakKwh * profile.offPeakTariff) +
            (breakdown.superOffPeakKwh * profile.superOffPeakTariff);
    }
  }

  List<_TimeWindow> _parseTimeWindows(String schedule) {
    final normalized = schedule.replaceAll(';', ',');
    final parts = normalized
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);

    final windows = <_TimeWindow>[];
    for (final part in parts) {
      final separatorIndex = part.indexOf('-');
      if (separatorIndex <= 0 || separatorIndex >= part.length - 1) {
        continue;
      }

      final startMinutes = _parseClockToMinutes(
        part.substring(0, separatorIndex).trim(),
      );
      final endMinutes = _parseClockToMinutes(
        part.substring(separatorIndex + 1).trim(),
      );
      if (startMinutes == null || endMinutes == null) {
        continue;
      }

      windows.add(
        _TimeWindow(startMinutes: startMinutes, endMinutes: endMinutes),
      );
    }
    return windows;
  }

  int? _parseClockToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour * 60) + minute;
  }

  bool _matchesAnyWindow(DateTime timestamp, List<_TimeWindow> windows) {
    final minutes = (timestamp.hour * 60) + timestamp.minute;
    for (final window in windows) {
      if (window.contains(minutes)) {
        return true;
      }
    }
    return false;
  }

  String _formatDayLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _ReadingSample {
  const _ReadingSample({required this.timestamp, required this.watts});

  final DateTime timestamp;
  final double watts;
}

class _HistorySeriesData {
  const _HistorySeriesData({required this.labels, required this.values});

  final List<String> labels;
  final List<double> values;
}

enum _TariffPeriod { peak, offPeak, superOffPeak }

class _TariffEnergyBreakdown {
  const _TariffEnergyBreakdown({
    this.peakKwh = 0,
    this.offPeakKwh = 0,
    this.superOffPeakKwh = 0,
  });

  final double peakKwh;
  final double offPeakKwh;
  final double superOffPeakKwh;

  double get totalKwh => peakKwh + offPeakKwh + superOffPeakKwh;
}

class _TimeWindow {
  const _TimeWindow({required this.startMinutes, required this.endMinutes});

  final int startMinutes;
  final int endMinutes;

  bool contains(int minutes) {
    if (startMinutes == endMinutes) {
      return true;
    }
    if (startMinutes < endMinutes) {
      return minutes >= startMinutes && minutes < endMinutes;
    }
    return minutes >= startMinutes || minutes < endMinutes;
  }
}

class _BucketAccumulator {
  double total = 0;
  int count = 0;

  void add(double value) {
    total += value;
    count++;
  }

  double get average => count == 0 ? 0 : total / count;
}
