import 'package:flutter/material.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/services/config_service.dart';
import 'package:smenergy/services/device_provisioning_service.dart';
import 'package:smenergy/services/energy_data_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class SetupStepTwoPage extends StatefulWidget {
  const SetupStepTwoPage({
    super.key,
    DeviceProvisioningServiceBase? provisioningService,
    EnergyDataServiceBase? energyDataService,
    Future<void> Function(int status)? setConfigStatus,
    this.successPageBuilder,
  }) : provisioningService =
           provisioningService ??
           const _DefaultDeviceProvisioningServiceProxy(),
       energyDataService =
           energyDataService ?? const _DefaultEnergyDataServiceProxy(),
       setConfigStatus = setConfigStatus ?? ConfigService.setConfigStatus;

  final DeviceProvisioningServiceBase provisioningService;
  final EnergyDataServiceBase energyDataService;
  final Future<void> Function(int status) setConfigStatus;
  final WidgetBuilder? successPageBuilder;

  @override
  State<SetupStepTwoPage> createState() => _SetupStepTwoPageState();
}

class _SetupStepTwoPageState extends State<SetupStepTwoPage> {
  bool _isObscure = true;
  bool _isConnecting = false;
  bool _canContinueAfterProvisioning = false;
  String? _statusMessage;
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _finishSetup() async {
    await widget.setConfigStatus(1);
    if (!mounted) return;

    _showMessage('Equipamento ligado com sucesso.');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            widget.successPageBuilder ?? (context) => const DashboardPage(),
      ),
      (route) => false,
    );
  }

  Future<bool> _confirmPhoneHasInternetAgain() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ligar novamente a Internet'),
          content: const Text(
            'A configuracao foi enviada para o equipamento. Agora volta a ligar o telemovel ao Wi-Fi da casa ou aos dados moveis e depois toca em Continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _connectDevice() async {
    if (_isConnecting) return;

    final ssid = _ssidController.text.trim();
    final password = _passController.text;
    if (ssid.isEmpty) {
      _showMessage('Preenche o SSID da tua rede Wi-Fi.');
      return;
    }

    setState(() {
      _isConnecting = true;
      _canContinueAfterProvisioning = false;
      _statusMessage = 'A enviar configuracao para o equipamento...';
    });
    try {
      final result = await widget.provisioningService.provisionDevice(
        ssid: ssid,
        password: password,
      );
      if (!mounted) return;

      if (!result.success) {
        setState(() => _statusMessage = null);
        _showMessage(result.message);
        return;
      }

      setState(() {
        _statusMessage =
            'Configuracao enviada. O equipamento vai ligar-se a rede da casa.';
      });

      final canCheckFirestore = await _confirmPhoneHasInternetAgain();
      if (!mounted) return;
      if (!canCheckFirestore) {
        setState(() {
          _canContinueAfterProvisioning = true;
          _statusMessage =
              'Configuracao enviada. Liga o telemovel a Internet e toca em Continuar.';
        });
        return;
      }

      setState(() {
        _statusMessage =
            'A confirmar no Firebase se ja chegaram leituras do equipamento...';
      });

      final telemetryReady = await widget.energyDataService
          .waitForFirstTelemetry()
          .timeout(const Duration(seconds: 90), onTimeout: () => false);
      if (!mounted) return;

      if (!telemetryReady) {
        setState(() {
          _canContinueAfterProvisioning = true;
          _statusMessage =
              'O equipamento recebeu a configuracao, mas a app nao conseguiu confirmar as leituras automaticamente. Se ja ves leituras no Firebase ou no dashboard, podes continuar.';
        });
        return;
      }

      await _finishSetup();
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              '2/2',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Configuracao Equipamento',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              '5. De volta a app, configure a rede Wi-Fi da casa',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            CustomPopOutInput(
              controller: _ssidController,
              icon: Icons.wifi,
              hint: 'SSID',
              gradient: myGradient,
            ),
            const SizedBox(height: 20),
            CustomPopOutInput(
              controller: _passController,
              icon: Icons.wifi_lock_rounded,
              hint: 'Password',
              gradient: myGradient,
              isPassword: true,
              isObscure: _isObscure,
              onToggleVisibility: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
            const Spacer(),
            if (_statusMessage != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isConnecting) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            CustomGradientButton(
              text: _isConnecting ? 'A conectar...' : 'Conectar',
              gradient: myGradient,
              onPressed: _isConnecting ? null : _connectDevice,
            ),
            if (_canContinueAfterProvisioning) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isConnecting ? null : _finishSetup,
                child: const Text('Continuar para o dashboard'),
              ),
            ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _DefaultDeviceProvisioningServiceProxy
    implements DeviceProvisioningServiceBase {
  const _DefaultDeviceProvisioningServiceProxy();

  DeviceProvisioningService get _service => DeviceProvisioningService();

  @override
  Future<bool> isProvisioningDeviceReachable() =>
      _service.isProvisioningDeviceReachable();

  @override
  Future<DeviceProvisioningResult> provisionDevice({
    required String ssid,
    required String password,
  }) => _service.provisionDevice(ssid: ssid, password: password);
}

class _DefaultEnergyDataServiceProxy implements EnergyDataServiceBase {
  const _DefaultEnergyDataServiceProxy();

  EnergyDataService get _service => EnergyDataService();

  @override
  Future<GamificationProfile> addGamificationPoints(int rewardPoints) =>
      _service.addGamificationPoints(rewardPoints);

  @override
  Future<GamificationRewardResult> completeGamificationChallenge(
    EnergyActiveAlert alert,
  ) => _service.completeGamificationChallenge(alert);

  @override
  Future<List<GamificationChallengeHistory>> fetchGamificationHistory({
    int limit = 30,
  }) => _service.fetchGamificationHistory(limit: limit);

  @override
  Future<ElectricityCostProfile> fetchElectricityCostProfile() =>
      _service.fetchElectricityCostProfile();

  @override
  Future<GamificationProfile> fetchGamificationProfile() =>
      _service.fetchGamificationProfile();

  @override
  Future<EnergyHistoryData> fetchHistory({
    required String sensorId,
    required String measure,
    required DateTime startDate,
    required DateTime endDate,
  }) => _service.fetchHistory(
    sensorId: sensorId,
    measure: measure,
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<List<EnergySensorOption>> fetchSensors() => _service.fetchSensors();

  @override
  Future<List<EnergySensorSettings>> fetchSensorSettings() =>
      _service.fetchSensorSettings();

  @override
  Future<void> saveElectricityCostProfile(ElectricityCostProfile profile) =>
      _service.saveElectricityCostProfile(profile);

  @override
  Stream<EnergyAlertData> streamAlertData({
    Duration interval = const Duration(seconds: 15),
  }) => _service.streamAlertData(interval: interval);

  @override
  Stream<EnergyDashboardData> streamDashboardData({
    Duration interval = const Duration(seconds: 15),
  }) => _service.streamDashboardData(interval: interval);

  @override
  Future<void> unpairActiveDeviceAndRequestReset() =>
      _service.unpairActiveDeviceAndRequestReset();

  @override
  Future<void> updateSensorSettings(List<EnergySensorSettings> settings) =>
      _service.updateSensorSettings(settings);

  @override
  Future<bool> waitForFirstTelemetry({
    Duration timeout = const Duration(seconds: 75),
    Duration pollInterval = const Duration(seconds: 5),
  }) => _service.waitForFirstTelemetry(
    timeout: timeout,
    pollInterval: pollInterval,
  );
}
