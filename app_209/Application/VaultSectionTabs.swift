import SwiftUI

struct VaultSectionTabs: View {
    var body: some View {
        TabView {
            VaultLookupView()
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }

            NavigationStack { VaultShelfView() }
                .tabItem { Label("Shelf", systemImage: "books.vertical.fill") }

            NavigationStack { WeekVaultPlan() }
                .tabItem { Label("Weekly", systemImage: "calendar.badge.clock") }

            NavigationStack { VaultInsightsView() }
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            NavigationStack { VaultSettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(IceVault.Colors.primary)
    }
}
