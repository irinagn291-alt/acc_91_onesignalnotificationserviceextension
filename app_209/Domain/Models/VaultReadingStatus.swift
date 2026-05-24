import Foundation

enum VaultReadingStatus: String, Codable, CaseIterable, Sendable {
    case wantToRead
    case reading
    case finished
    case paused

    var localizedTitle: String {
        switch self {
        case .wantToRead: "Want to Read"
        case .reading: "Reading"
        case .finished: "Finished"
        case .paused: "Paused"
        }
    }

    var icon: String {
        switch self {
        case .wantToRead: "bookmark"
        case .reading: "book.open"
        case .finished: "checkmark.seal.fill"
        case .paused: "pause.circle"
        }
    }
}
