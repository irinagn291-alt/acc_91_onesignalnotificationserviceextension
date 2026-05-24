import Foundation

struct VaultPreferencesSnapshot: Equatable, Sendable {
    var hasCompletedOnboarding: Bool
    var displayMode: VaultDisplayMode
}

@MainActor
protocol VaultPreferencesRepository {
    func load() throws -> VaultPreferencesSnapshot
    func save(_ snapshot: VaultPreferencesSnapshot) throws
}

@MainActor
protocol VaultLibraryRepository {
    func allBooks() throws -> [VaultBook]
    func book(id: UUID) throws -> VaultBook?
    func upsert(_ book: VaultBook) throws
    func delete(id: UUID) throws
    func clearAll() throws
}

@MainActor
protocol VaultProgressRepository {
    func logEntry(bookID: UUID, pageNumber: Int, totalPages: Int?) throws
    func entries(for bookID: UUID) throws -> [VaultProgressEntry]
    func allEntries() throws -> [VaultProgressEntry]
}

@MainActor
protocol VaultMoodListsRepository {
    func allLists() throws -> [VaultSavedMoodList]
    func saveList(name: String, subject: String, books: [BookSearchResult]) throws
    func deleteList(id: UUID) throws
}

@MainActor
protocol VaultOpenLibraryRepository {
    func search(title: String, limit: Int, offset: Int) async throws -> [BookSearchResult]
    func search(query: String, limit: Int, offset: Int) async throws -> [BookSearchResult]
    func workDetail(workKey: String, fallbackAuthors: [String]) async throws -> WorkDetail
    func subjectBooks(slug: String, limit: Int, offset: Int) async throws -> [SubjectBookResult]
}

struct VaultSavedMoodList: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var subject: String
    var savedAt: Date
    var bookCount: Int
}
