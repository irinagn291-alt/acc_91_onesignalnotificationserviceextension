import Combine
import Foundation
import SwiftData

@MainActor
final class VaultAppDependencies: ObservableObject {
    let preferences: VaultPreferencesRepository
    let library: VaultLibraryRepository
    let progress: VaultProgressRepository
    let moodLists: VaultMoodListsRepository
    let openLibrary: VaultOpenLibraryRepository
    let connectivity: VaultConnectivityMonitor

    init(modelContext: ModelContext) {
        let client = VaultAPIClient()
        self.preferences = SwiftDataVaultPreferencesRepository(context: modelContext)
        self.library = SwiftDataVaultLibraryRepository(context: modelContext)
        self.progress = SwiftDataVaultProgressRepository(context: modelContext)
        self.moodLists = SwiftDataVaultMoodListsRepository(context: modelContext)
        self.openLibrary = DefaultVaultOpenLibraryRepository(client: client)
        self.connectivity = VaultConnectivityMonitor()
        Task { @MainActor in
            self.connectivity.start()
            Self.configureURLCache()
        }
    }

    private static func configureURLCache() {
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
    }
}
