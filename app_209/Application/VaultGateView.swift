import SwiftUI

struct VaultGateView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    @State private var prefs: VaultPreferencesSnapshot?

    var body: some View {
        Group {
            if let prefs {
                if prefs.hasCompletedOnboarding {
                    VaultSectionTabs()
                        .transition(.opacity)
                } else {
                    SecureIceIntro {
                        completeOnboarding()
                    }
                    .transition(.opacity)
                }
            } else {
                ZStack {
                    IceVault.Colors.background.ignoresSafeArea()
                    ProgressView()
                        .tint(IceVault.Colors.accent)
                }
                .task(priority: .userInitiated) {
                    await loadPreferences()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: prefs?.hasCompletedOnboarding)
        .onReceive(NotificationCenter.default.publisher(for: .vaultPreferencesChanged)) { _ in
            Task { await loadPreferences() }
        }
    }

    private func loadPreferences() async {
        do {
            prefs = try deps.preferences.load()
        } catch {
            prefs = VaultPreferencesSnapshot(hasCompletedOnboarding: false, displayMode: .list)
        }
    }

    private func completeOnboarding() {
        var snap = prefs ?? VaultPreferencesSnapshot(hasCompletedOnboarding: false, displayMode: .list)
        snap.hasCompletedOnboarding = true
        do {
            try deps.preferences.save(snap)
            withAnimation { prefs = snap }
        } catch {
            withAnimation { prefs = snap }
        }
    }
}

extension Notification.Name {
    static let vaultPreferencesChanged = Notification.Name("icevault.preferencesChanged")
}
