import Foundation

enum VaultStatisticsCalculator {
    struct NameCount: Hashable, Sendable {
        var name: String
        var count: Int
    }

    struct Summary: Equatable, Sendable {
        var totalBooks: Int
        var wantToRead: Int
        var reading: Int
        var finished: Int
        var paused: Int
        var averageRating: Double?
        var totalPagesRead: Int
        var averageProgressReading: Double?
    }

    static func compute(for books: [VaultBook]) -> Summary {
        var want = 0, reading = 0, finished = 0, paused = 0
        var ratingSum = 0.0, ratingCount = 0
        var totalPages = 0
        var progressSum = 0.0, progressCount = 0

        for b in books {
            switch b.status {
            case .wantToRead: want += 1
            case .reading: reading += 1
            case .finished: finished += 1
            case .paused: paused += 1
            }
            if let r = b.rating { ratingSum += r; ratingCount += 1 }
            if b.status == .finished, let t = b.totalPages { totalPages += t }
            else { totalPages += max(0, b.currentPage) }
            if b.status == .reading,
               let frac = VaultProgressCalculator.progressFraction(currentPage: b.currentPage, totalPages: b.totalPages) {
                progressSum += frac
                progressCount += 1
            }
        }

        return Summary(
            totalBooks: books.count,
            wantToRead: want,
            reading: reading,
            finished: finished,
            paused: paused,
            averageRating: ratingCount > 0 ? ratingSum / Double(ratingCount) : nil,
            totalPagesRead: totalPages,
            averageProgressReading: progressCount > 0 ? progressSum / Double(progressCount) : nil
        )
    }
}
