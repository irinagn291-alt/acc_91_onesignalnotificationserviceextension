import Alamofire
import OneSignalFramework
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let oneSignalAppID = "d6ea7bc0-2707-49fc-a64b-37cba86f5131"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppConfiguration.serverBaseURL = "https://food-app-factologoi.pro"

        OneSignal.initialize(Self.oneSignalAppID, withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: false)

        application.registerForRemoteNotifications()

        return true
    }
}
