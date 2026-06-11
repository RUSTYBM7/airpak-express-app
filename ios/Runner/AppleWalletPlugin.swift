import Flutter
import UIKit
import PassKit

/// Native Apple Wallet bridge for the ShipNow Flutter app.
///
/// Channel: `shipnow/wallet`
/// Methods:
///   - `isAvailable`     -> Bool
///   - `isPassInstalled` -> Bool (args: { "serial": String })
///   - `addPass`         -> Bool (args: { "pkpassBase64": String, "serial": String })
///
/// When the user finishes (or cancels) the add-to-Wallet sheet the
/// promise is resolved with the result.
public class AppleWalletPlugin: NSObject, FlutterPlugin, PKAddPassesViewControllerDelegate {
  private var pendingResult: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "shipnow/wallet",
      binaryMessenger: registrar.messenger()
    )
    let instance = AppleWalletPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(PKPassLibrary.isPassLibraryAvailable())

    case "isPassInstalled":
      let args = (call.arguments as? [String: Any]) ?? [:]
      let serial = (args["serial"] as? String) ?? ""
      if !PKPassLibrary.isPassLibraryAvailable() {
        result(false)
        return
      }
      result(PKPassLibrary().containsPass(withSerialNumber: serial))

    case "addPass":
      let args = (call.arguments as? [String: Any]) ?? [:]
      guard
        let b64 = args["pkpassBase64"] as? String,
        let data = Data(base64Encoded: b64)
      else {
        result(FlutterError(
          code: "bad_args",
          message: "Missing or invalid pkpassBase64",
          details: nil))
        return
      }
      guard let pass = try? PKPass(data: data) else {
        result(FlutterError(
          code: "invalid_pkpass",
          message: "Failed to parse pkpass data (is it signed by Apple?)",
          details: nil))
        return
      }
      guard let vc = PKAddPassesViewController(pass: pass) else {
        result(FlutterError(
          code: "no_view_controller",
          message: "Could not create PKAddPassesViewController",
          details: nil))
        return
      }
      guard let root = topViewController() else {
        result(FlutterError(
          code: "no_root_vc",
          message: "Could not find a view controller to present from",
          details: nil))
        return
      }
      pendingResult = result
      vc.delegate = self
      root.present(vc, animated: true, completion: nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - PKAddPassesViewControllerDelegate

  public func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
    controller.dismiss(animated: true) { [weak self] in
      guard let self = self, let r = self.pendingResult else { return }
      self.pendingResult = nil
      r(true)
    }
  }

  // MARK: - Helpers

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    let windows = scenes.flatMap { $0.windows }
      .filter { $0.isKeyWindow }
    guard var top = windows.first?.rootViewController else { return nil }
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
