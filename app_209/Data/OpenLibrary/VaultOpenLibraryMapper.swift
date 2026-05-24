import Foundation

enum VaultOpenLibraryMapper {
    private static let unknownTitle = "Untitled"
    private static let unknownAuthor = "Unknown author"

    static func workId(fromKey key: String?) -> String {
        guard let key else { return UUID().uuidString }
        return key.hasPrefix("/works/") ? String(key.dropFirst("/works/".count)) : key
    }

    static func normalizedWorkKey(_ key: String?) -> String? {
        guard let key, !key.isEmpty else { return nil }
        return key.hasPrefix("/works/") ? key : "/works/\(key)"
    }

    static func searchResults(from dto: IVSearchResponseDTO) -> [BookSearchResult] {
        (dto.docs ?? []).compactMap { doc in
            guard let key = doc.key else { return nil }
            return BookSearchResult(
                openLibraryId: workId(fromKey: key),
                workKey: normalizedWorkKey(key),
                title: doc.title ?? unknownTitle,
                authors: doc.authorName ?? [],
                coverID: doc.coverI,
                year: doc.firstPublishYear,
                subjects: Array((doc.subject ?? []).prefix(12)),
                pageCount: doc.numberOfPagesMedian
            )
        }
    }

    static func workDetail(from dto: IVWorkDTO, fallbackAuthors: [String]) -> WorkDetail? {
        guard let key = dto.key else { return nil }
        let year = dto.firstPublishDate.flatMap { Int($0.prefix(4)) }
        let coverID = dto.covers?.first
        let authors: [String] = {
            if !fallbackAuthors.isEmpty { return fallbackAuthors }
            let fromKeys = (dto.authors ?? []).compactMap { $0.author?.key?.split(separator: "/").last.map(String.init) }
            return fromKeys.isEmpty ? [unknownAuthor] : fromKeys
        }()
        return WorkDetail(
            workKey: key.hasPrefix("/works/") ? key : "/works/\(key)",
            title: dto.title ?? unknownTitle,
            authors: authors,
            description: dto.description?.plainText,
            subjects: dto.subjects ?? [],
            year: year,
            coverID: coverID,
            pageCount: nil
        )
    }

    static func subjectBooks(from dto: IVSubjectResponseDTO) -> [SubjectBookResult] {
        (dto.works ?? []).compactMap { w in
            guard let key = w.key else { return nil }
            let authors = (w.authors ?? []).compactMap(\.name)
            return SubjectBookResult(
                key: key,
                title: w.title ?? unknownTitle,
                authors: authors.isEmpty ? [unknownAuthor] : authors,
                coverID: w.coverId,
                year: w.firstPublishYear
            )
        }
    }
}
