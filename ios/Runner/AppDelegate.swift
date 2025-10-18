import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configure Google Maps
    GMSServices.provideAPIKey("AIzaSyChRNxb69txX0gBgle_kzBecVDuFrm_5Y4")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
