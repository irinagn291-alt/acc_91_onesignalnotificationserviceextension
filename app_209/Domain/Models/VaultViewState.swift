import Foundation

enum VaultViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
    case offline

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
