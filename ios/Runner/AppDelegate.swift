import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.bradymd.my_holidays/share"
  private var initialFilePath: String?
  /// Set to true once Dart calls getInitialFile, meaning the Dart side is ready.
  private var flutterReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Check for file URL in launch options (cold start via "Open in")
    if let url = launchOptions?[.url] as? URL {
      initialFilePath = url.path
    }

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "getInitialFile" {
        self?.flutterReady = true
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
    let path = url.path

    if flutterReady, let controller = window?.rootViewController as? FlutterViewController {
      // Dart is running — send the file path immediately
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("openFile", arguments: path)
    } else {
      // Dart isn't ready yet (cold start) — store for getInitialFile
      initialFilePath = path
    }

    return true
  }
}
