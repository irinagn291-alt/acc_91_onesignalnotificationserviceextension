import Foundation

struct VaultProgressEntry: Identifiable, Hashable, Sendable {
    var id: UUID
    var bookID: UUID
    var pageNumber: Int
    var totalPages: Int?
    var timestamp: Date
}
