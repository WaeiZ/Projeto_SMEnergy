import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smenergy/services/auth_service.dart';
import 'package:smenergy/services/device_provisioning_service.dart';
import 'package:smenergy/services/energy_data_service.dart';
import 'package:smenergy/services/wifi_settings_service.dart';

Widget buildTestApp(Widget child) {
  return DefaultAssetBundle(
    bundle: TestAssetBundle(),
    child: MaterialApp(home: child),
  );
}

class TestAssetBundle extends CachingAssetBundle {
  static final Uint8List _transparentImage = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WnM6t8AAAAASUVORK5CYII=',
  );

  static const List<String> _assets = [
    'assets/logo.png',
    'assets/google.png',
    'assets/icons/pulse_icon.png',
    'assets/icons/volt_icon.png',
    'assets/icons/zeus_icon.png',
  ];

  static final ByteData _assetManifest = const StandardMessageCodec()
      .encodeMessage(<String, List<Map<String, Object?>>>{
        'assets/logo.png': [
          <String, Object?>{'asset': 'assets/logo.png', 'dpr': 1.0},
        ],
        'assets/google.png': [
          <String, Object?>{'asset': 'assets/google.png', 'dpr': 1.0},
        ],
        'assets/icons/pulse_icon.png': [
          <String, Object?>{'asset': 'assets/icons/pulse_icon.png', 'dpr': 1.0},
        ],
        'assets/icons/volt_icon.png': [
          <String, Object?>{'asset': 'assets/icons/volt_icon.png', 'dpr': 1.0},
        ],
        'assets/icons/zeus_icon.png': [
          <String, Object?>{'asset': 'assets/icons/zeus_icon.png', 'dpr': 1.0},
        ],
      })!;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return _assetManifest;
    }
    if (key == 'AssetManifest.json') {
      final entries = _assets.map((asset) => '"$asset":["$asset"]').join(',');
      final manifest = utf8.encode('{$entries}');
      return ByteData.view(Uint8List.fromList(manifest).buffer);
    }
    if (_assets.contains(key)) {
      return ByteData.view(Uint8List.fromList(_transparentImage).buffer);
    }
    throw FlutterError('Asset not found in test bundle: $key');
  }
}

class FakeAuthService implements AuthServiceBase {
  FakeAuthService({
    this.hasEquipment = false,
    this.signInError,
    this.signUpError,
    this.googleError,
    this.resetPasswordError,
    this.signInCompleter,
  });

  bool hasEquipment;
  Object? signInError;
  Object? signUpError;
  Object? googleError;
  Object? resetPasswordError;
  Completer<void>? signInCompleter;

  int signInCalls = 0;
  int signUpCalls = 0;
  int resetPasswordCalls = 0;
  int googleCalls = 0;
  int signOutCalls = 0;

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
    if (resetPasswordError != null) throw resetPasswordError!;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    if (signInCompleter != null) {
      await signInCompleter!.future;
    }
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    if (googleError != null) throw googleError!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    if (signUpError != null) throw signUpError!;
  }

  @override
  Future<void> updateUserName({required String name}) async {}
}

class FakeEnergyDataService implements EnergyDataServiceBase {
  FakeEnergyDataService({
    Stream<EnergyDashboardData>? dashboardStream,
    Stream<EnergyAlertData>? alertStream,
    this.historyData = const EnergyHistoryData.empty(),
    this.sensors = const [],
    this.gamificationProfile = const GamificationProfile.empty(),
    this.gamificationHistory = const [],
    this.electricityProfile = const ElectricityCostProfile.empty(),
    this.sensorSettings = const [],
    this.waitForTelemetryResult = true,
    this.saveElectricityError,
  }) : _dashboardStream =
           dashboardStream ??
           Stream<EnergyDashboardData>.value(const EnergyDashboardData.empty()),
       _alertStream =
           alertStream ??
           Stream<EnergyAlertData>.value(const EnergyAlertData.empty());

  final Stream<EnergyDashboardData> _dashboardStream;
  final Stream<EnergyAlertData> _alertStream;
  EnergyHistoryData historyData;
  List<EnergySensorOption> sensors;
  GamificationProfile gamificationProfile;
  List<GamificationChallengeHistory> gamificationHistory;
  ElectricityCostProfile electricityProfile;
  List<EnergySensorSettings> sensorSettings;
  bool waitForTelemetryResult;
  Object? saveElectricityError;

  int addPointsCalls = 0;
  int saveElectricityCalls = 0;

  @override
  Future<GamificationProfile> addGamificationPoints(int rewardPoints) async {
    addPointsCalls++;
    gamificationProfile = GamificationProfile(
      points: gamificationProfile.points + rewardPoints,
    );
    return gamificationProfile;
  }

  @override
  Future<GamificationRewardResult> completeGamificationChallenge(
    EnergyActiveAlert alert,
  ) async {
    final profile = await addGamificationPoints(alert.rewardPoints);
    return GamificationRewardResult(
      profile: profile,
      status: GamificationRewardStatus.awarded,
    );
  }

  @override
  Future<List<GamificationChallengeHistory>> fetchGamificationHistory({
    int limit = 30,
  }) async => gamificationHistory.take(limit).toList(growable: false);

  @override
  Future<ElectricityCostProfile> fetchElectricityCostProfile() async =>
      electricityProfile;

  @override
  Future<GamificationProfile> fetchGamificationProfile() async =>
      gamificationProfile;

  @override
  Future<EnergyHistoryData> fetchHistory({
    required String sensorId,
    required String measure,
    required DateTime startDate,
    required DateTime endDate,
  }) async => historyData;

  @override
  Future<List<EnergySensorOption>> fetchSensors() async => sensors;

  @override
  Future<List<EnergySensorSettings>> fetchSensorSettings() async =>
      sensorSettings;

  @override
  Future<void> saveElectricityCostProfile(
    ElectricityCostProfile profile,
  ) async {
    saveElectricityCalls++;
    if (saveElectricityError != null) throw saveElectricityError!;
    electricityProfile = profile;
  }

  @override
  Stream<EnergyAlertData> streamAlertData({
    Duration interval = const Duration(seconds: 15),
  }) => _alertStream;

  @override
  Stream<EnergyDashboardData> streamDashboardData({
    Duration interval = const Duration(seconds: 15),
  }) => _dashboardStream;

  @override
  Future<void> unpairActiveDeviceAndRequestReset() async {}

  @override
  Future<void> updateSensorSettings(List<EnergySensorSettings> settings) async {
    sensorSettings = settings;
  }

  @override
  Future<bool> waitForFirstTelemetry({
    Duration timeout = const Duration(seconds: 75),
    Duration pollInterval = const Duration(seconds: 5),
  }) async => waitForTelemetryResult;
}

class FakeWifiSettingsService implements WifiSettingsServiceBase {
  FakeWifiSettingsService({this.result = true});

  bool result;
  int calls = 0;

  @override
  Future<bool> openWifiSettings() async {
    calls++;
    return result;
  }
}

class FakeDeviceProvisioningService implements DeviceProvisioningServiceBase {
  FakeDeviceProvisioningService({
    this.isReachable = true,
    this.result = const DeviceProvisioningResult(success: true, message: 'ok'),
  });

  bool isReachable;
  DeviceProvisioningResult result;
  int reachableCalls = 0;
  int provisionCalls = 0;

  @override
  Future<bool> isProvisioningDeviceReachable() async {
    reachableCalls++;
    return isReachable;
  }

  @override
  Future<DeviceProvisioningResult> provisionDevice({
    required String ssid,
    required String password,
  }) async {
    provisionCalls++;
    return result;
  }
}
