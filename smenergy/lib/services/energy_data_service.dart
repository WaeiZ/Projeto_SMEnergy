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

class EnergyHistoryData {
  const EnergyHistoryData({required this.labels, required this.values});

  const EnergyHistoryData.empty() : labels = const [], values = const [];

  final List<String> labels;
  final List<double> values;
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
  static const String _demoDeviceId = 'device_demo';

  Future<bool> seedDemoDataIfEmpty() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    final deviceRef = await _resolveOrCreateDeviceRef(uid);
    final sensorsRef = deviceRef.collection('sensors');
    final sensorsSnapshot = await sensorsRef.get();
    final hasSensors = sensorsSnapshot.docs.any(_isDataDocument);
    if (hasSensors) {
      return false;
    }

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 14));
    final profiles = const <_DemoSensorProfile>[
      _DemoSensorProfile(
        id: 'sensor_1',
        name: 'Sensor 1',
        baseWatts: 360,
        amplitudeWatts: 220,
        limitWatts: 620,
      ),
      _DemoSensorProfile(
        id: 'sensor_2',
        name: 'Sensor 2',
        baseWatts: 280,
        amplitudeWatts: 160,
        limitWatts: 520,
      ),
      _DemoSensorProfile(
        id: 'sensor_3',
        name: 'Sensor 3',
        baseWatts: 430,
        amplitudeWatts: 250,
        limitWatts: 760,
      ),
    ];

    WriteBatch batch = _db.batch();
    int batchOps = 0;
    Future<void> commitBatch() async {
      if (batchOps == 0) return;
      await batch.commit();
      batch = _db.batch();
      batchOps = 0;
    }

    for (int i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      final sensorRef = sensorsRef.doc(profile.id);
      final lastWatts = _demoWatts(profile, now, i);

      batch.set(sensorRef, {
        'name': profile.name,
        'limit_watts': profile.limitWatts,
        'current_watts': lastWatts,
        'last_reading_at': Timestamp.fromDate(now),
        'source': 'demo',
        'placeholder': false,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batchOps++;

      DateTime cursor = start;
      while (!cursor.isAfter(now)) {
        final watts = _demoWatts(profile, cursor, i);
        final readingRef = sensorRef.collection('readings').doc();
        batch.set(readingRef, {
          'timestamp': Timestamp.fromDate(cursor),
          'watts': watts,
          'source': 'demo',
        });
        batchOps++;

        if (batchOps >= 450) {
          await commitBatch();
        }
        cursor = cursor.add(const Duration(hours: 2));
      }
    }

    await commitBatch();
    return true;
  }

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

    final byDay = <DateTime, List<double>>{};
    for (final reading in readings) {
      final day = DateTime(
        reading.timestamp.year,
        reading.timestamp.month,
        reading.timestamp.day,
      );
      byDay.putIfAbsent(day, () => <double>[]).add(reading.watts);
    }

    final labels = <String>[];
    final values = <double>[];
    DateTime cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(endDay)) {
      final samples = byDay[cursor] ?? const <double>[];
      labels.add(_formatDayLabel(cursor));
      values.add(_applyMeasure(samples, measure));
      cursor = cursor.add(const Duration(days: 1));
    }

    if (labels.length > 8) {
      final step = (labels.length / 8).ceil();
      final compactLabels = <String>[];
      final compactValues = <double>[];
      for (int i = 0; i < labels.length; i += step) {
        compactLabels.add(labels[i]);
        compactValues.add(values[i]);
      }
      if (compactLabels.last != labels.last) {
        compactLabels.add(labels.last);
        compactValues.add(values.last);
      }
      return EnergyHistoryData(labels: compactLabels, values: compactValues);
    }

    return EnergyHistoryData(labels: labels, values: values);
  }

  Stream<EnergyAlertData> streamAlertData({
    Duration interval = _defaultPollInterval,
  }) async* {
    await for (final dashboard in streamDashboardData(interval: interval)) {
      yield _buildAlertData(dashboard.sensors);
    }
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

  Future<DocumentReference<Map<String, dynamic>>> _resolveOrCreateDeviceRef(
    String uid,
  ) async {
    final existing = await _resolveActiveDeviceRef(uid);
    if (existing != null) {
      return existing;
    }

    final deviceRef = _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(_demoDeviceId);
    await deviceRef.set({
      'name': 'SMEnergy Demo',
      'source': 'demo',
      'placeholder': false,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return deviceRef;
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

  double _applyMeasure(List<double> samples, String measure) {
    if (samples.isEmpty) return 0;

    switch (measure) {
      case 'Máximo':
        return samples.reduce(max);
      case 'Mínimo':
        return samples.reduce(min);
      case 'Média':
      default:
        final avg =
            samples.fold<double>(0, (acc, value) => acc + value) /
            samples.length;
        return avg;
    }
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

  double _demoWatts(_DemoSensorProfile profile, DateTime timestamp, int index) {
    final hourPhase = ((timestamp.hour + timestamp.minute / 60) / 24) * 2 * pi;
    final dayPhase =
        (timestamp.difference(DateTime(timestamp.year, 1, 1)).inDays / 365) *
        2 *
        pi;
    final wave = sin(hourPhase + (index * 0.8)) + (0.3 * sin(dayPhase + index));
    final noise = (((timestamp.hour * 7) + (index * 13)) % 23) - 11;
    final watts =
        profile.baseWatts +
        (profile.amplitudeWatts * (0.6 + wave * 0.4)) +
        noise;
    return max(80, watts);
  }
}

class _DemoSensorProfile {
  const _DemoSensorProfile({
    required this.id,
    required this.name,
    required this.baseWatts,
    required this.amplitudeWatts,
    required this.limitWatts,
  });

  final String id;
  final String name;
  final double baseWatts;
  final double amplitudeWatts;
  final double limitWatts;
}

class _ReadingSample {
  const _ReadingSample({required this.timestamp, required this.watts});

  final DateTime timestamp;
  final double watts;
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
