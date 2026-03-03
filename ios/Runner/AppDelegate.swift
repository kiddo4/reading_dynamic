import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "reading_dynamic/live_activity"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        guard #available(iOS 16.2, *) else {
          result(FlutterError(
            code: "UNAVAILABLE",
            message: "Live Activities require iOS 16.2+",
            details: nil
          ))
          return
        }

        switch call.method {
        case "start":
          guard
            let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let chapter = args["chapter"] as? String,
            let progress = args["progress"] as? Double
          else {
            result(FlutterError(
              code: "BAD_ARGS",
              message: "Expected title, chapter and progress",
              details: nil
            ))
            return
          }

          Task {
            let ok = await LiveActivityManager.shared.start(
              bookTitle: title,
              chapter: chapter,
              progress: progress
            )
            result(ok)
          }
        case "update":
          guard
            let args = call.arguments as? [String: Any],
            let chapter = args["chapter"] as? String,
            let progress = args["progress"] as? Double
          else {
            result(FlutterError(
              code: "BAD_ARGS",
              message: "Expected chapter and progress",
              details: nil
            ))
            return
          }

          Task {
            let ok = await LiveActivityManager.shared.update(
              chapter: chapter,
              progress: progress
            )
            result(ok)
          }
        case "end":
          Task {
            await LiveActivityManager.shared.end()
            result(true)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
