import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ── Firebase ────────────────────────────────────────────────────────
    // Configured by `GoogleService-Info.plist` (drop it into
    // ios/Runner/ from the Firebase console). If the file is missing
    // we skip initialization so the app still boots.
    if let _ = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
      FirebaseApp.configure()

      // Push notifications
      UNUserNotificationCenter.current().delegate = self
      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound]
      ) { granted, _ in
        if granted { DispatchQueue.main.async { application.registerForRemoteNotifications() } }
      }
      Messaging.messaging().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    // Native Apple Wallet bridge (uses PKAddPassesViewController)
    if let registrar = self.registrar(forPlugin: "AppleWalletPlugin") {
      AppleWalletPlugin.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ── APNs → FCM bridge ───────────────────────────────────────────────
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNs registration failed: \(error)")
  }

  // Foreground push: still show the banner.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound, .badge])
  }

  // Tap on a push: forward the tracking number (if any) to Flutter.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let tracking = response.notification.request.content.userInfo["tracking"] as? String
    if let tracking = tracking,
       let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "shipnow/push",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onTrackingTap", arguments: tracking)
    }
    completionHandler()
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    NSLog("FCM token: \(fcmToken ?? "nil")")
    // In production: POST fcmToken to your backend so you can target
    // this device with topic or direct sends.
  }
}
