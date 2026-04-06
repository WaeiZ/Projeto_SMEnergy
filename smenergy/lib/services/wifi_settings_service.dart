import 'package:flutter/services.dart';

abstract class WifiSettingsServiceBase {
  Future<bool> openWifiSettings();
}

class WifiSettingsService implements WifiSettingsServiceBase {
  static const MethodChannel _channel = MethodChannel('smenergy/wifi_settings');

  @override
  Future<bool> openWifiSettings() async {
    try {
      final opened = await _channel.invokeMethod<bool>('openWifiSettings');
      return opened ?? false;
    } on PlatformException {
      return false;
    }
  }
}
