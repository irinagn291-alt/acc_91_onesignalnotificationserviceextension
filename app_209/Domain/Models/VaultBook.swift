import Foundation

struct VaultBook: Identifiable, Hashable, Sendable {
    var id: UUID
    var workKey: String?
    var openLibraryId: String
    var title: String
    var authors: [String]
    var coverID: Int?
    var coverURL: String?
    var year: Int?
    var subjects: [String]
    var bookDescription: String?
    var isbn: String?
    var status: VaultReadingStatus
    var currentPage: Int
    var totalPages: Int?
    var rating: Double?
    var note: String?
    var noteCreatedAt: Date?
    var noteUpdatedAt: Date?
    var addedAt: Date
    var startedAt: Date?
    var finishedAt: Date?
    var updatedAt: Date
}
