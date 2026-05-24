import Foundation

enum VaultDisplayMode: String, Codable, CaseIterable, Sendable {
    case list
    case grid

    var localizedTitle: String {
        switch self {
        case .list: "List"
        case .grid: "Grid"
        }
    }
}
