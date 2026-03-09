import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DeviceProvisioningResult {
  const DeviceProvisioningResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class DeviceProvisioningService {
  static const String _deviceHost = '192.168.4.1';
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const Duration _statusTimeout = Duration(seconds: 4);

  Future<bool> isProvisioningDeviceReachable() async {
    final uri = Uri.parse('http://$_deviceHost/status');
    try {
      final response = await http.get(uri).timeout(_statusTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<DeviceProvisioningResult> provisionDevice({
    required String ssid,
    required String password,
  }) async {
    final cleanSsid = ssid.trim();
    if (cleanSsid.isEmpty) {
      return const DeviceProvisioningResult(
        success: false,
        message: 'Indica o nome da rede Wi-Fi (SSID).',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final ownerUid = user?.uid.trim() ?? '';
    if (ownerUid.isEmpty) {
      return const DeviceProvisioningResult(
        success: false,
        message: 'Sessão inválida. Faz login novamente.',
      );
    }

    final uri = Uri.parse('http://$_deviceHost/provision');

    try {
      final response = await http
          .post(
            uri,
            body: {
              'ssid': cleanSsid,
              'password': password,
              'owner_uid': ownerUid,
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const DeviceProvisioningResult(
          success: true,
          message:
              'Configuração enviada para o dispositivo. Aguarda alguns segundos.',
        );
      }

      return DeviceProvisioningResult(
        success: false,
        message:
            'Falha ao configurar o dispositivo (HTTP ${response.statusCode}).',
      );
    } on TimeoutException {
      return const DeviceProvisioningResult(
        success: false,
        message:
            'Sem resposta do equipamento. Verifica se estás ligado ao Wi-Fi SMEnergy_AP.',
      );
    } on SocketException {
      return const DeviceProvisioningResult(
        success: false,
        message:
            'Não foi possível contactar o equipamento. Liga o telemóvel ao Wi-Fi SMEnergy_AP e tenta novamente.',
      );
    } catch (_) {
      return const DeviceProvisioningResult(
        success: false,
        message: 'Erro inesperado ao configurar o equipamento.',
      );
    }
  }
}
