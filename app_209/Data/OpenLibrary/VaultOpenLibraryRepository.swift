import Foundation

@MainActor
final class DefaultVaultOpenLibraryRepository: VaultOpenLibraryRepository {
    private let client: VaultHTTPClient

    init(client: VaultHTTPClient) {
        self.client = client
    }

    func search(title: String, limit: Int, offset: Int) async throws -> [BookSearchResult] {
        let dto = try await client.searchByTitle(title, limit: limit, offset: offset)
        return VaultOpenLibraryMapper.searchResults(from: dto)
    }

    func search(query: String, limit: Int, offset: Int) async throws -> [BookSearchResult] {
        let dto = try await client.searchByQuery(query, limit: limit, offset: offset)
        return VaultOpenLibraryMapper.searchResults(from: dto)
    }

    func workDetail(workKey: String, fallbackAuthors: [String]) async throws -> WorkDetail {
        let dto = try await client.fetchWork(workKey: workKey)
        guard let detail = VaultOpenLibraryMapper.workDetail(from: dto, fallbackAuthors: fallbackAuthors) else {
            throw VaultNetworkError.noData
        }
        return detail
    }

    func subjectBooks(slug: String, limit: Int, offset: Int) async throws -> [SubjectBookResult] {
        let dto = try await client.fetchSubject(slug: slug, limit: limit, offset: offset)
        return VaultOpenLibraryMapper.subjectBooks(from: dto)
    }
}
