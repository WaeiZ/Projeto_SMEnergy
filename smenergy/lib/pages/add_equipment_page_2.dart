import 'package:flutter/material.dart';
import 'package:smenergy/pages/add_equipment_page_3.dart';
import 'package:smenergy/services/device_provisioning_service.dart';
import 'package:smenergy/services/wifi_settings_service.dart';

class SetupStepOnePage extends StatefulWidget {
  const SetupStepOnePage({super.key});

  @override
  State<SetupStepOnePage> createState() => _SetupStepOnePageState();
}

class _SetupStepOnePageState extends State<SetupStepOnePage>
    with WidgetsBindingObserver {
  final WifiSettingsService _wifiSettingsService = WifiSettingsService();
  final DeviceProvisioningService _provisioningService =
      DeviceProvisioningService();

  bool _waitingReturnFromSettings = false;
  bool _checkingDevice = false;
  bool _navigated = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingReturnFromSettings) {
      _checkDeviceAndContinue();
    }
  }

  Future<void> _openWifiSettings() async {
    final opened = await _wifiSettingsService.openWifiSettings();
    if (!mounted) return;

    if (!opened) {
      setState(() {
        _statusMessage =
            'Não foi possível abrir as definições de Wi-Fi automaticamente.';
      });
      return;
    }

    setState(() {
      _waitingReturnFromSettings = true;
      _statusMessage =
          'Liga-te ao SMEnergy_AP nas definições e depois volta à app.';
    });
  }

  Future<void> _checkDeviceAndContinue() async {
    if (_checkingDevice || _navigated) return;

    setState(() => _checkingDevice = true);
    final reachable = await _provisioningService
        .isProvisioningDeviceReachable();
    if (!mounted) return;

    setState(() {
      _checkingDevice = false;
      if (!reachable) {
        _statusMessage =
            'Ainda não detetámos o equipamento. Liga-te ao SMEnergy_AP e volta à app.';
      }
    });

    if (!reachable || _navigated) {
      return;
    }

    _navigated = true;
    _waitingReturnFromSettings = false;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetupStepTwoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              '1/2',
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
              '1. Ligar equipamento à tomada\n'
              '2. Ligar Wi-Fi 2.4 GHz no telemóvel\n'
              '3. Tocar em SMEnergy_AP para abrir Wi-Fi\n'
              '4. Ligar ao SMEnergy_AP e voltar à app',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 40),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.blue.shade400, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'WiFi',
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'SMEnergy_AP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text('Toca para abrir as definições Wi-Fi'),
                    trailing: const Icon(
                      Icons.settings,
                      color: Colors.black,
                      size: 20,
                    ),
                    onTap: _openWifiSettings,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (_checkingDevice)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A verificar ligação ao equipamento...',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),

            if (!_checkingDevice && _statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: _waitingReturnFromSettings
                      ? Colors.blue.shade700
                      : Colors.orange.shade800,
                ),
              ),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _checkingDevice ? null : _checkDeviceAndContinue,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Já voltei à app, continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
