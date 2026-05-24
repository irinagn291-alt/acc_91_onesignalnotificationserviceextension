import Foundation

enum VaultOpenLibraryEndpoint {
    static let base = URL(string: "https://openlibrary.org")!
    static let coversBase = URL(string: "https://covers.openlibrary.org/b/id/")!

    static func searchTitle(_ title: String, limit: Int, offset: Int) -> URL? {
        var c = URLComponents(url: base.appendingPathComponent("search.json"), resolvingAgainstBaseURL: false)
        c?.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        return c?.url
    }

    static func searchQuery(_ query: String, limit: Int, offset: Int) -> URL? {
        var c = URLComponents(url: base.appendingPathComponent("search.json"), resolvingAgainstBaseURL: false)
        c?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        return c?.url
    }

    static func subject(_ slug: String, limit: Int, offset: Int) -> URL? {
        var c = URLComponents(url: base.appendingPathComponent("subjects/\(slug).json"), resolvingAgainstBaseURL: false)
        c?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        return c?.url
    }

    static func work(_ workKey: String) -> URL? {
        let trimmed = workKey.hasPrefix("/works/") ? String(workKey.dropFirst("/works/".count)) : workKey
        return base.appendingPathComponent("works/\(trimmed).json")
    }

    static func cover(id: Int, size: String = "M") -> URL {
        URL(string: "https://covers.openlibrary.org/b/id/\(id)-\(size).jpg")!
    }
}
