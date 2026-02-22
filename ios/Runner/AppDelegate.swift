import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.bradymd.my_holidays/share"
  private var initialFilePath: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "getInitialFile" {
        result(self?.initialFilePath)
        self?.initialFilePath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      initialFilePath = url.path
      return true
    }

    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.invokeMethod("openFile", arguments: url.path)
    return true
  }
}
