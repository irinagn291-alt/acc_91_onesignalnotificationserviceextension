import Alamofire
import OneSignalFramework
import SwiftData
import SwiftUI

@main
struct app_209App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var deps: VaultAppDependencies
    @State private var isInitializing = true
    @State private var displayMode: DisplayMode = .loading
    @State private var webContentURL: String?

    private let container: ModelContainer

    init() {
        let schema = Schema([
            SDVaultPreferences.self,
            SDLibraryBook.self,
            SDProgressEvent.self,
            SDMoodList.self,
            SDWeekPlanEntry.self
        ])
        let container = try! ModelContainer(for: schema)
        self.container = container
        _deps = StateObject(wrappedValue: VaultAppDependencies(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
        .modelContainer(container)
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                loadingView
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                VaultGateView()
                    .environmentObject(deps)
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            IceVault.Colors.background.ignoresSafeArea()
            ProgressView()
                .tint(IceVault.Colors.accent)
        }
    }

    private func performRegistration() {
        let pushToken = OneSignal.User.pushSubscription.token ?? ""
        NetworkService.shared.performRegistration(pushToken: pushToken) { mode, url in
            DispatchQueue.main.async {
                displayMode = mode
                webContentURL = url
                isInitializing = false
            }
        }
    }
}
