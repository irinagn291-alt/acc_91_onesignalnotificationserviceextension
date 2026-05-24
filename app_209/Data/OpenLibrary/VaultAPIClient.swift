import Foundation

enum VaultNetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .invalidResponse: "Invalid server response"
        case .httpStatus(let code): "Network error (code \(code))"
        case .decoding: "Could not parse response data"
        case .noData: "No data returned"
        }
    }
}

protocol VaultHTTPClient: Sendable {
    func searchByTitle(_ title: String, limit: Int, offset: Int) async throws -> IVSearchResponseDTO
    func searchByQuery(_ query: String, limit: Int, offset: Int) async throws -> IVSearchResponseDTO
    func fetchWork(workKey: String) async throws -> IVWorkDTO
    func fetchSubject(slug: String, limit: Int, offset: Int) async throws -> IVSubjectResponseDTO
}

final class VaultAPIClient: VaultHTTPClient, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func get<T: Decodable>(_ url: URL?, type: T.Type) async throws -> T {
        guard let url else { throw VaultNetworkError.invalidURL }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw VaultNetworkError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw VaultNetworkError.httpStatus(http.statusCode) }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw VaultNetworkError.decoding(error)
        }
    }

    func searchByTitle(_ title: String, limit: Int, offset: Int) async throws -> IVSearchResponseDTO {
        try await get(VaultOpenLibraryEndpoint.searchTitle(title, limit: limit, offset: offset), type: IVSearchResponseDTO.self)
    }

    func searchByQuery(_ query: String, limit: Int, offset: Int) async throws -> IVSearchResponseDTO {
        try await get(VaultOpenLibraryEndpoint.searchQuery(query, limit: limit, offset: offset), type: IVSearchResponseDTO.self)
    }

    func fetchWork(workKey: String) async throws -> IVWorkDTO {
        try await get(VaultOpenLibraryEndpoint.work(workKey), type: IVWorkDTO.self)
    }

    func fetchSubject(slug: String, limit: Int, offset: Int) async throws -> IVSubjectResponseDTO {
        try await get(VaultOpenLibraryEndpoint.subject(slug, limit: limit, offset: offset), type: IVSubjectResponseDTO.self)
    }
}
