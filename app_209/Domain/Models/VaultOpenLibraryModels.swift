import Foundation

struct BookSearchResult: Identifiable, Hashable, Sendable {
    var id: String { openLibraryId }
    var openLibraryId: String
    var workKey: String?
    var title: String
    var authors: [String]
    var coverID: Int?
    var year: Int?
    var subjects: [String]
    var pageCount: Int?
}

struct WorkDetail: Sendable {
    var workKey: String
    var title: String
    var authors: [String]
    var description: String?
    var subjects: [String]
    var year: Int?
    var coverID: Int?
    var pageCount: Int?
}

struct SubjectBookResult: Identifiable, Hashable, Sendable {
    var id: String { key }
    var key: String
    var title: String
    var authors: [String]
    var coverID: Int?
    var year: Int?
}

enum CoverURLBuilder {
    static func url(coverID: Int?, size: String = "M") -> String? {
        guard let coverID else { return nil }
        return "https://covers.openlibrary.org/b/id/\(coverID)-\(size).jpg"
    }
}
