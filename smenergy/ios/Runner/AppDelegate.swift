import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let wifiChannelName = "smenergy/wifi_settings"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: wifiChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let strongSelf = self else {
          result(false)
          return
        }

        switch call.method {
        case "openWifiSettings":
          strongSelf.openWifiSettings(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func openWifiSettings(result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else {
      result(false)
      return
    }

    UIApplication.shared.open(url, options: [:]) { success in
      result(success)
    }
  }
}
