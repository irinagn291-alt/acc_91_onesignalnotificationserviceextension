import Alamofire
import SwiftUI

struct VaultSettingsView: View {
    private static let contactUsURL = "https://food-app-factologoi.pro/contact-us"

    @EnvironmentObject private var deps: VaultAppDependencies
    @State private var prefs = VaultPreferencesSnapshot(hasCompletedOnboarding: true, displayMode: .list)
    @State private var showClearConfirm = false
    @State private var showContactUs = false
    @State private var version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    @State private var build: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(spacing: IceVault.Space.lg) {
                appHeaderSection
                librarySection
                dataSection
                aboutSection
            }
            .padding(.horizontal, IceVault.Space.xl)
            .padding(.bottom, 40)
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .task { await load() }
        .alert("Clear all data?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { clearAll() }
        } message: {
            Text("All books, progress, and notes will be deleted. This cannot be undone.")
        }
        .sheet(isPresented: $showContactUs) {
            VaultContactUsSheet(url: Self.contactUsURL) {
                showContactUs = false
            }
        }
    }

    // MARK: - Sections

    private var appHeaderSection: some View {
        VStack(spacing: IceVault.Space.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(colors: [IceVault.Colors.primary, IceVault.Colors.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 88, height: 88)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)
            }
            Text("IceVault")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
            Text("Version \(version) (\(build))")
                .font(.caption)
                .foregroundStyle(IceVault.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, IceVault.Space.lg)
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.sm) {
            sectionLabel("Library Display")
            VStack(spacing: IceVault.Space.sm) {
                HStack {
                    Text("Layout")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(IceVault.Colors.text)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { prefs.displayMode },
                        set: { m in update { $0.displayMode = m } }
                    )) {
                        ForEach(VaultDisplayMode.allCases, id: \.self) { m in
                            Text(m.localizedTitle).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(IceVault.Colors.primary)
                }
                .padding(IceVault.Space.md)
                .iceVaultCard()
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.sm) {
            sectionLabel("Data")
            IVSettingsRow(icon: "trash", title: "Clear All Data", subtitle: "Remove books, progress, and notes", danger: true) {
                showClearConfirm = true
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.sm) {
            sectionLabel("About")

            IVSettingsRow(icon: "envelope", title: "Contact Us", subtitle: "Get in touch") {
                showContactUs = true
            }

            Link(destination: URL(string: "https://openlibrary.org")!) {
                IVInlineLinkRow(icon: "link", title: "Open Library", subtitle: "openlibrary.org")
            }
            .buttonStyle(.plain)

            Link(destination: URL(string: "https://openlibrary.org/privacy")!) {
                IVInlineLinkRow(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "Open Library")
            }
            .buttonStyle(.plain)

            Link(destination: URL(string: "https://openlibrary.org/developers/licensing")!) {
                IVInlineLinkRow(icon: "doc.text.fill", title: "Data Licensing", subtitle: "Open Library")
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(IceVault.Colors.textMuted)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.leading, 4)
    }

    // MARK: - Helpers

    private func load() async {
        do { prefs = try deps.preferences.load() } catch {}
    }

    private func update(_ change: (inout VaultPreferencesSnapshot) -> Void) {
        change(&prefs)
        do {
            try deps.preferences.save(prefs)
            NotificationCenter.default.post(name: .vaultPreferencesChanged, object: nil)
        } catch {}
    }

    private func clearAll() {
        try? deps.library.clearAll()
    }
}

// MARK: - Contact Us

private struct VaultContactUsSheet: View {
    let url: String
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                WebContentView(url: url)
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
    }
}
