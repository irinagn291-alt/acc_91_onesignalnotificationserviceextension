import SwiftUI

struct VaultShelfDetailView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    let bookID: UUID

    @State private var book: VaultBook?
    @State private var currentPageText: String = ""
    @State private var totalPagesText: String = ""
    @State private var rating: Double = 0
    @State private var note: String = ""
    @State private var debounce: Task<Void, Never>?

    var body: some View {
        ScrollView {
            if let book {
                VStack(spacing: IceVault.Space.lg) {
                    heroBanner(book)
                    statusEditor(book)
                    ratingEditor
                    progressEditor(book)
                    noteEditor
                    navigationLinks(book)
                }
                .padding(.horizontal, IceVault.Space.xl)
                .padding(.bottom, 40)
            } else {
                ProgressView().tint(IceVault.Colors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
            }
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBook() }
        .onChange(of: currentPageText) { _, _ in debounceSave() }
        .onChange(of: totalPagesText) { _, _ in debounceSave() }
    }

    // MARK: - Sections

    private func heroBanner(_ b: VaultBook) -> some View {
        let url = b.coverURL.flatMap(URL.init(string:))
        return VStack(spacing: IceVault.Space.md) {
            IVCoverView(url: url, title: b.title, author: b.authors.first, width: 120, height: 180)
            Text(b.title)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
                .multilineTextAlignment(.center)
            Text(b.authors.isEmpty ? "Unknown author" : b.authors.joined(separator: ", "))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(IceVault.Colors.textMuted)
            HStack(spacing: IceVault.Space.sm) {
                if let r = b.rating { IVRatingBadge(rating: r) }
                IVStatusChip(status: b.status)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(IceVault.Space.xl)
        .iceVaultCard()
    }

    private func statusEditor(_ b: VaultBook) -> some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Reading Status")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
            Picker("Status", selection: Binding(
                get: { book?.status ?? .wantToRead },
                set: { v in
                    guard var m = book else { return }
                    m.status = v
                    m.updatedAt = .now
                    if v == .reading && m.startedAt == nil { m.startedAt = .now }
                    if v == .finished && m.finishedAt == nil { m.finishedAt = .now }
                    saveBook(m)
                }
            )) {
                ForEach(VaultReadingStatus.allCases, id: \.self) { s in
                    Label(s.localizedTitle, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private var ratingEditor: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Rating")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
            IVRatingStars(rating: $rating)
                .onChange(of: rating) { _, v in
                    guard var m = book else { return }
                    m.rating = v
                    m.updatedAt = .now
                    saveBook(m)
                }
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private func progressEditor(_ b: VaultBook) -> some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Reading Progress")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)

            HStack(spacing: IceVault.Space.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current page").font(.caption).foregroundStyle(IceVault.Colors.textMuted)
                    TextField("0", text: $currentPageText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .bold))
                        .padding(IceVault.Space.sm)
                        .background(RoundedRectangle(cornerRadius: 8).fill(IceVault.Colors.surfaceAlt))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total pages").font(.caption).foregroundStyle(IceVault.Colors.textMuted)
                    TextField("?", text: $totalPagesText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .bold))
                        .padding(IceVault.Space.sm)
                        .background(RoundedRectangle(cornerRadius: 8).fill(IceVault.Colors.surfaceAlt))
                }
            }

            if let current = Int(currentPageText), let total = Int(totalPagesText), total > 0 {
                let frac = VaultProgressCalculator.progressFraction(currentPage: current, totalPages: total) ?? 0
                IVProgressBar(value: frac)
                Text("\(current) of \(total) pages — \(Int(frac * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IceVault.Colors.textMuted)
            }

            Button("Log Progress") {
                logProgress()
            }
            .buttonStyle(IceVaultSecondaryButton())
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Note")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
            TextEditor(text: $note)
                .frame(minHeight: 100)
                .font(.system(size: 14))
                .foregroundStyle(IceVault.Colors.text)
                .scrollContentBackground(.hidden)
                .background(IceVault.Colors.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: note) { _, _ in debounceSave() }
            Button("Save Note") { saveNote() }
                .buttonStyle(IceVaultPrimaryButton())
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private func navigationLinks(_ b: VaultBook) -> some View {
        VStack(spacing: IceVault.Space.md) {
            NavigationLink {
                VaultProgressView(bookID: b.id)
            } label: {
                IVInlineLinkRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Log",
                    subtitle: "View full reading history"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                VaultNotesView(bookID: b.id)
            } label: {
                IVInlineLinkRow(
                    icon: "star.bubble",
                    title: "Rating & Notes",
                    subtitle: b.rating != nil ? String(format: "%.0f stars", b.rating!) : "No rating yet"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func loadBook() async {
        do {
            book = try deps.library.book(id: bookID)
            if let b = book {
                currentPageText = String(b.currentPage)
                totalPagesText = b.totalPages.map(String.init) ?? ""
                rating = b.rating ?? 0
                note = b.note ?? ""
            }
        } catch { book = nil }
    }

    private func debounceSave() {
        debounce?.cancel()
        debounce = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { saveProgress() }
        }
    }

    private func saveProgress() {
        guard var b = book else { return }
        let newTotal = Int(totalPagesText).flatMap { $0 > 0 ? $0 : nil }
        let rawCurrent = Int(currentPageText) ?? b.currentPage
        let newCurrent = VaultProgressCalculator.clampedPage(rawCurrent, totalPages: newTotal)
        b.currentPage = newCurrent
        b.totalPages = newTotal
        b.updatedAt = .now
        saveBook(b)
    }

    private func logProgress() {
        guard var b = book else { return }
        let newTotal = Int(totalPagesText).flatMap { $0 > 0 ? $0 : nil }
        let rawCurrent = Int(currentPageText) ?? b.currentPage
        let newCurrent = VaultProgressCalculator.clampedPage(rawCurrent, totalPages: newTotal)
        b.currentPage = newCurrent
        b.totalPages = newTotal
        b.updatedAt = .now
        do {
            try deps.library.upsert(b)
            try deps.progress.logEntry(bookID: b.id, pageNumber: newCurrent, totalPages: newTotal)
            book = b
        } catch {}
    }

    private func saveNote() {
        guard var b = book else { return }
        let now = Date.now
        if b.note == nil || (b.note ?? "").isEmpty { b.noteCreatedAt = now }
        b.noteUpdatedAt = now
        b.note = note
        b.updatedAt = now
        saveBook(b)
    }

    private func saveBook(_ b: VaultBook) {
        do {
            try deps.library.upsert(b)
            book = b
        } catch {}
    }
}
