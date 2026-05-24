import Foundation
import SwiftData

// MARK: - JSON helpers

private let _jsonEncoder = JSONEncoder()
private let _jsonDecoder = JSONDecoder()

private func encodeStrings(_ value: [String]) -> String {
    (try? String(data: _jsonEncoder.encode(value), encoding: .utf8)) ?? "[]"
}

private func decodeStrings(_ json: String) -> [String] {
    (try? _jsonDecoder.decode([String].self, from: Data(json.utf8))) ?? []
}

// MARK: - Book mapper

private enum VaultBookMapper {
    static func toDomain(_ m: SDLibraryBook) -> VaultBook {
        VaultBook(
            id: m.id,
            workKey: m.workKey,
            openLibraryId: m.openLibraryId,
            title: m.title,
            authors: decodeStrings(m.authorsJSON),
            coverID: m.coverID,
            coverURL: m.coverURL,
            year: m.year,
            subjects: decodeStrings(m.subjectsJSON),
            bookDescription: nil,
            isbn: nil,
            status: VaultReadingStatus(rawValue: m.statusRaw) ?? .wantToRead,
            currentPage: m.currentPage,
            totalPages: m.totalPages,
            rating: m.rating,
            note: m.note,
            noteCreatedAt: m.noteCreatedAt,
            noteUpdatedAt: m.noteUpdatedAt,
            addedAt: m.addedAt,
            startedAt: m.startedAt,
            finishedAt: m.finishedAt,
            updatedAt: m.updatedAt
        )
    }

    static func apply(_ book: VaultBook, to m: SDLibraryBook) {
        m.openLibraryId = book.openLibraryId
        m.workKey = book.workKey
        m.title = book.title
        m.authorsJSON = encodeStrings(book.authors)
        m.coverID = book.coverID
        m.coverURL = book.coverURL
        m.year = book.year
        m.subjectsJSON = encodeStrings(book.subjects)
        m.statusRaw = book.status.rawValue
        m.currentPage = book.currentPage
        m.totalPages = book.totalPages
        m.rating = book.rating
        m.note = book.note
        m.noteCreatedAt = book.noteCreatedAt
        m.noteUpdatedAt = book.noteUpdatedAt
        m.addedAt = book.addedAt
        m.startedAt = book.startedAt
        m.finishedAt = book.finishedAt
        m.updatedAt = book.updatedAt
    }

    static func newModel(from book: VaultBook) -> SDLibraryBook {
        SDLibraryBook(
            id: book.id,
            openLibraryId: book.openLibraryId,
            workKey: book.workKey,
            title: book.title,
            authorsJSON: encodeStrings(book.authors),
            coverID: book.coverID,
            coverURL: book.coverURL,
            year: book.year,
            subjectsJSON: encodeStrings(book.subjects),
            statusRaw: book.status.rawValue,
            currentPage: book.currentPage,
            totalPages: book.totalPages,
            rating: book.rating,
            note: book.note,
            noteCreatedAt: book.noteCreatedAt,
            noteUpdatedAt: book.noteUpdatedAt,
            addedAt: book.addedAt,
            startedAt: book.startedAt,
            finishedAt: book.finishedAt,
            updatedAt: book.updatedAt
        )
    }
}

// MARK: - Preferences

@MainActor
final class SwiftDataVaultPreferencesRepository: VaultPreferencesRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func load() throws -> VaultPreferencesSnapshot {
        let fd = FetchDescriptor<SDVaultPreferences>()
        if let existing = try context.fetch(fd).first {
            return map(existing)
        }
        let fresh = SDVaultPreferences()
        context.insert(fresh)
        try context.save()
        return map(fresh)
    }

    func save(_ snapshot: VaultPreferencesSnapshot) throws {
        let fd = FetchDescriptor<SDVaultPreferences>()
        let entity = try context.fetch(fd).first ?? {
            let n = SDVaultPreferences()
            context.insert(n)
            return n
        }()
        entity.hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        entity.displayModeRaw = snapshot.displayMode.rawValue
        try context.save()
    }

    private func map(_ e: SDVaultPreferences) -> VaultPreferencesSnapshot {
        VaultPreferencesSnapshot(
            hasCompletedOnboarding: e.hasCompletedOnboarding,
            displayMode: VaultDisplayMode(rawValue: e.displayModeRaw) ?? .list
        )
    }
}

// MARK: - Library

@MainActor
final class SwiftDataVaultLibraryRepository: VaultLibraryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allBooks() throws -> [VaultBook] {
        let fd = FetchDescriptor<SDLibraryBook>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try context.fetch(fd).map(VaultBookMapper.toDomain)
    }

    func book(id: UUID) throws -> VaultBook? {
        let fd = FetchDescriptor<SDLibraryBook>(predicate: #Predicate { $0.id == id })
        return try context.fetch(fd).first.map(VaultBookMapper.toDomain)
    }

    func upsert(_ book: VaultBook) throws {
        let bookId = book.id
        let fd = FetchDescriptor<SDLibraryBook>(predicate: #Predicate { $0.id == bookId })
        if let existing = try context.fetch(fd).first {
            VaultBookMapper.apply(book, to: existing)
        } else {
            context.insert(VaultBookMapper.newModel(from: book))
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        let fd = FetchDescriptor<SDLibraryBook>(predicate: #Predicate { $0.id == id })
        for obj in try context.fetch(fd) {
            context.delete(obj)
        }
        try context.save()
    }

    func clearAll() throws {
        let fd = FetchDescriptor<SDLibraryBook>()
        for obj in try context.fetch(fd) {
            context.delete(obj)
        }
        try context.save()
    }
}

// MARK: - Progress

@MainActor
final class SwiftDataVaultProgressRepository: VaultProgressRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func logEntry(bookID: UUID, pageNumber: Int, totalPages: Int?) throws {
        context.insert(SDProgressEvent(bookID: bookID, pageNumber: pageNumber, totalPages: totalPages))
        try context.save()
    }

    func entries(for bookID: UUID) throws -> [VaultProgressEntry] {
        let fd = FetchDescriptor<SDProgressEvent>(
            predicate: #Predicate { $0.bookID == bookID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(fd).map {
            VaultProgressEntry(id: $0.id, bookID: $0.bookID, pageNumber: $0.pageNumber, totalPages: $0.totalPages, timestamp: $0.timestamp)
        }
    }

    func allEntries() throws -> [VaultProgressEntry] {
        let fd = FetchDescriptor<SDProgressEvent>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try context.fetch(fd).map {
            VaultProgressEntry(id: $0.id, bookID: $0.bookID, pageNumber: $0.pageNumber, totalPages: $0.totalPages, timestamp: $0.timestamp)
        }
    }
}

// MARK: - Mood Lists

@MainActor
final class SwiftDataVaultMoodListsRepository: VaultMoodListsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allLists() throws -> [VaultSavedMoodList] {
        let fd = FetchDescriptor<SDMoodList>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        return try context.fetch(fd).map {
            VaultSavedMoodList(id: $0.id, name: $0.name, subject: $0.subject, savedAt: $0.savedAt, bookCount: $0.bookCount)
        }
    }

    func saveList(name: String, subject: String, books: [BookSearchResult]) throws {
        let list = SDMoodList(name: name, subject: subject, bookCount: books.count)
        context.insert(list)
        try context.save()
    }

    func deleteList(id: UUID) throws {
        let fd = FetchDescriptor<SDMoodList>(predicate: #Predicate { $0.id == id })
        for obj in try context.fetch(fd) {
            context.delete(obj)
        }
        try context.save()
    }
}
