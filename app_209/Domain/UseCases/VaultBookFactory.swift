import Foundation

enum VaultBookFactory {
    static func coverURLString(coverID: Int?, size: String = "M") -> String? {
        guard let coverID else { return nil }
        return "https://covers.openlibrary.org/b/id/\(coverID)-\(size).jpg"
    }

    static func newFromSearchResult(_ result: BookSearchResult, status: VaultReadingStatus) -> VaultBook {
        let now = Date.now
        return VaultBook(
            id: UUID(),
            workKey: result.workKey,
            openLibraryId: result.openLibraryId,
            title: result.title,
            authors: result.authors,
            coverID: result.coverID,
            coverURL: coverURLString(coverID: result.coverID),
            year: result.year,
            subjects: result.subjects,
            bookDescription: nil,
            isbn: nil,
            status: status,
            currentPage: 0,
            totalPages: result.pageCount,
            rating: nil,
            note: nil,
            noteCreatedAt: nil,
            noteUpdatedAt: nil,
            addedAt: now,
            startedAt: status == .reading ? now : nil,
            finishedAt: nil,
            updatedAt: now
        )
    }

    static func newFromWorkDetail(_ detail: WorkDetail, status: VaultReadingStatus) -> VaultBook {
        let now = Date.now
        let id = VaultOpenLibraryMapper.workId(fromKey: detail.workKey)
        return VaultBook(
            id: UUID(),
            workKey: detail.workKey,
            openLibraryId: id,
            title: detail.title,
            authors: detail.authors,
            coverID: detail.coverID,
            coverURL: coverURLString(coverID: detail.coverID),
            year: detail.year,
            subjects: detail.subjects,
            bookDescription: detail.description,
            isbn: nil,
            status: status,
            currentPage: 0,
            totalPages: detail.pageCount,
            rating: nil,
            note: nil,
            noteCreatedAt: nil,
            noteUpdatedAt: nil,
            addedAt: now,
            startedAt: status == .reading ? now : nil,
            finishedAt: nil,
            updatedAt: now
        )
    }

    static func mergedWork(into book: VaultBook, detail: WorkDetail) -> VaultBook {
        var b = book
        b.title = detail.title
        if !detail.authors.isEmpty { b.authors = detail.authors }
        if let c = detail.coverID { b.coverID = c; b.coverURL = coverURLString(coverID: c) }
        if let y = detail.year { b.year = y }
        if !detail.subjects.isEmpty { b.subjects = detail.subjects }
        if let desc = detail.description { b.bookDescription = desc }
        if b.totalPages == nil, let p = detail.pageCount { b.totalPages = p }
        b.updatedAt = .now
        return b
    }
}
