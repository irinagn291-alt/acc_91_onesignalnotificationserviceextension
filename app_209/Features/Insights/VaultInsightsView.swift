import SwiftUI

struct VaultInsightsView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    @State private var books: [VaultBook] = []
    @State private var summary: VaultStatisticsCalculator.Summary = VaultStatisticsCalculator.compute(for: [])

    var body: some View {
        ScrollView {
            VStack(spacing: IceVault.Space.lg) {
                overviewTiles
                statusChart
                readingNow
                recentlyFinished
            }
            .padding(.horizontal, IceVault.Space.xl)
            .padding(.bottom, 40)
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
        .navigationTitle("Insights")
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Tiles

    private var overviewTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: IceVault.Space.md) {
            IVStatTile(title: "Total Books", value: "\(summary.totalBooks)", systemImage: "books.vertical")
            IVStatTile(title: "Reading", value: "\(summary.reading)", systemImage: "book.open")
            IVStatTile(title: "Finished", value: "\(summary.finished)", systemImage: "checkmark.seal.fill")
            IVStatTile(title: "Want to Read", value: "\(summary.wantToRead)", systemImage: "bookmark")
            if let avg = summary.averageRating {
                IVStatTile(title: "Avg Rating", value: String(format: "%.1f ★", avg), systemImage: "star.fill")
            }
            IVStatTile(title: "Pages Read", value: "\(summary.totalPagesRead)", systemImage: "doc.text")
        }
    }

    // MARK: - Status chart

    private var statusChart: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Library Breakdown")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)

            let data: [(String, Int, Color)] = [
                ("Reading", summary.reading, IceVault.Colors.primary),
                ("Finished", summary.finished, IceVault.Colors.success),
                ("Want", summary.wantToRead, IceVault.Colors.accent),
                ("Paused", summary.paused, IceVault.Colors.textMuted),
            ]
            let total = max(1, data.map(\.1).reduce(0, +))

            VStack(spacing: 10) {
                ForEach(data, id: \.0) { item in
                    if item.1 > 0 {
                        HStack(spacing: IceVault.Space.md) {
                            Text(item.0)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(IceVault.Colors.textMuted)
                                .frame(width: 70, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(IceVault.Colors.surfaceAlt)
                                    Capsule()
                                        .fill(item.2)
                                        .frame(width: max(8, geo.size.width * Double(item.1) / Double(total)))
                                }
                            }
                            .frame(height: 10)
                            Text("\(item.1)")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(IceVault.Colors.text)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    // MARK: - Reading now

    @ViewBuilder
    private var readingNow: some View {
        let reading = books.filter { $0.status == .reading }.prefix(5)
        if !reading.isEmpty {
            VStack(alignment: .leading, spacing: IceVault.Space.md) {
                Text("Currently Reading")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(IceVault.Colors.text)
                ForEach(Array(reading)) { b in
                    let frac = VaultProgressCalculator.progressFraction(currentPage: b.currentPage, totalPages: b.totalPages) ?? 0
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(b.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(IceVault.Colors.text)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(frac * 100))%")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(IceVault.Colors.accent)
                        }
                        IVProgressBar(value: frac)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(IceVault.Space.lg)
            .iceVaultCard()
        }
    }

    // MARK: - Recently finished

    @ViewBuilder
    private var recentlyFinished: some View {
        let finished = books.filter { $0.status == .finished }.prefix(5)
        if !finished.isEmpty {
            VStack(alignment: .leading, spacing: IceVault.Space.md) {
                Text("Recently Finished")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(IceVault.Colors.text)
                ForEach(Array(finished)) { b in
                    HStack(spacing: IceVault.Space.md) {
                        let url = b.coverURL.flatMap(URL.init(string:))
                        IVCoverView(url: url, title: b.title, author: b.authors.first, width: 44, height: 66)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(b.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(IceVault.Colors.text)
                                .lineLimit(1)
                            if let r = b.rating {
                                IVRatingBadge(rating: r)
                            }
                        }
                        Spacer()
                        if let d = b.finishedAt {
                            Text(d.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(IceVault.Colors.textMuted)
                        }
                    }
                }
            }
            .padding(IceVault.Space.lg)
            .iceVaultCard()
        }
    }

    // MARK: - Load

    private func load() async {
        do {
            books = try deps.library.allBooks().sorted { $0.updatedAt > $1.updatedAt }
            summary = VaultStatisticsCalculator.compute(for: books)
        } catch {
            books = []
        }
    }
}
