import 'package:flutter/material.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/services/config_service.dart';
import 'package:smenergy/services/device_provisioning_service.dart';
import 'package:smenergy/services/energy_data_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class SetupStepTwoPage extends StatefulWidget {
  const SetupStepTwoPage({super.key});

  @override
  State<SetupStepTwoPage> createState() => _SetupStepTwoPageState();
}

class _SetupStepTwoPageState extends State<SetupStepTwoPage> {
  bool _isObscure = true;
  bool _isConnecting = false;
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final DeviceProvisioningService _provisioningService =
      DeviceProvisioningService();
  final EnergyDataService _energyDataService = EnergyDataService();

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _connectDevice() async {
    if (_isConnecting) return;

    final ssid = _ssidController.text.trim();
    final password = _passController.text;
    if (ssid.isEmpty) {
      _showMessage('Preenche o SSID da tua rede Wi-Fi.');
      return;
    }

    setState(() => _isConnecting = true);
    try {
      final result = await _provisioningService.provisionDevice(
        ssid: ssid,
        password: password,
      );
      if (!mounted) return;

      if (!result.success) {
        _showMessage(result.message);
        return;
      }

      _showMessage(
        'Configuração enviada. À espera da primeira leitura do equipamento...',
      );

      final telemetryReady = await _energyDataService.waitForFirstTelemetry();
      if (!mounted) return;

      if (!telemetryReady) {
        _showMessage(
          'O equipamento recebeu a configuração, mas ainda não enviou leituras. Confirma o Wi-Fi 2.4 GHz, a alimentação e tenta novamente dentro de instantes.',
        );
        return;
      }

      await ConfigService.setConfigStatus(1);
      if (!mounted) return;

      _showMessage('Equipamento ligado com sucesso e a enviar dados.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
        (route) => false,
      );
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
              "2/2",
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
              'Configuração Equipamento',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              '5. De volta à app, configure a rede Wi-Fi da casa',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            // INPUT SSID
            CustomPopOutInput(
              controller:
                  _ssidController, // Passando o controller para capturar o texto
              icon: Icons.wifi,
              hint: 'SSID',
              gradient: myGradient,
            ),

            const SizedBox(height: 20),

            // INPUT PASSWORD
            CustomPopOutInput(
              controller: _passController, // Passando o controller
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

            const SizedBox(height: 420),

            CustomGradientButton(
              text: _isConnecting ? 'A conectar...' : 'Conectar',
              gradient: myGradient,
              onPressed: _isConnecting ? null : _connectDevice,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
