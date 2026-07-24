import Flutter
import UIKit
import flutter_local_notifications
import ActivityKit

struct SunbathingWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
    }
    var totalDurationSeconds: Int
    var isFrontSide: Bool
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  var currentActivity: Any?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.velibilir.yolkut/live_activity",
                                       binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if #available(iOS 16.1, *) {
            if call.method == "start" {
                guard let args = call.arguments as? [String: Any],
                      let total = args["totalDurationSeconds"] as? Int,
                      let front = args["isFrontSide"] as? Bool else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                
                let attributes = SunbathingWidgetAttributes(totalDurationSeconds: total, isFrontSide: front)
                let contentState = SunbathingWidgetAttributes.ContentState(remainingSeconds: total)
                
                do {
                    if #available(iOS 16.2, *) {
                        let content = ActivityContent(state: contentState, staleDate: nil)
                        self?.currentActivity = try Activity.request(attributes: attributes, content: content)
                    } else {
                        self?.currentActivity = try Activity.request(attributes: attributes, contentState: contentState)
                    }
                    result(true)
                } catch {
                    result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
                }
                
            } else if call.method == "update" {
                guard let args = call.arguments as? [String: Any],
                      let remaining = args["remainingSeconds"] as? Int else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                
                let contentState = SunbathingWidgetAttributes.ContentState(remainingSeconds: remaining)
                
                Task {
                    guard let activity = self?.currentActivity as? Activity<SunbathingWidgetAttributes> else { return }
                    if #available(iOS 16.2, *) {
                        let content = ActivityContent(state: contentState, staleDate: nil)
                        await activity.update(content)
                    } else {
                        await activity.update(using: contentState)
                    }
                    result(true)
                }
                
            } else if call.method == "stop" {
                Task {
                    if let activity = self?.currentActivity as? Activity<SunbathingWidgetAttributes> {
                        await activity.end(dismissalPolicy: .immediate)
                        self?.currentActivity = nil
                    }
                    result(true)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "Live Activities require iOS 16.1+", details: nil))
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
