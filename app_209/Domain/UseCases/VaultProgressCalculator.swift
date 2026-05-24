import Foundation

enum VaultProgressCalculator {
    static func clampedPage(_ current: Int, totalPages: Int?) -> Int {
        guard let total = totalPages, total > 0 else { return max(0, current) }
        return min(max(0, current), total)
    }

    static func progressFraction(currentPage: Int, totalPages: Int?) -> Double? {
        guard let total = totalPages, total > 0 else { return nil }
        return min(1.0, max(0.0, Double(currentPage) / Double(total)))
    }
}
