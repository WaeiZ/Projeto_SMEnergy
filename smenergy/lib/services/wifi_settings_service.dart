import 'package:flutter/services.dart';

class WifiSettingsService {
  static const MethodChannel _channel = MethodChannel('smenergy/wifi_settings');

  Future<bool> openWifiSettings() async {
    try {
      final opened = await _channel.invokeMethod<bool>('openWifiSettings');
      return opened ?? false;
    } on PlatformException {
      return false;
    }
  }
}
