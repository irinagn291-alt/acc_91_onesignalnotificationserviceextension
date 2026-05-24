import SwiftUI
import SwiftData

private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

struct WeekVaultPlan: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    @Environment(\.modelContext) private var context

    @State private var planEntries: [SDWeekPlanEntry] = []
    @State private var showAddSheet = false
    @State private var addingForDay: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: IceVault.Space.lg) {
                headerSection
                weekGrid
            }
            .padding(.horizontal, IceVault.Space.xl)
            .padding(.bottom, 40)
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
        .navigationTitle("Weekly Plan")
        .task { await load() }
        .sheet(isPresented: $showAddSheet) {
            AddBookToDaySheet { book in
                addBookToDay(book, dayIndex: addingForDay)
                showAddSheet = false
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.sm) {
            Text("Reading Schedule")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
            Text("Plan what to read each day this week.")
                .font(.system(size: 14))
                .foregroundStyle(IceVault.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, IceVault.Space.md)
    }

    private var weekGrid: some View {
        VStack(spacing: IceVault.Space.md) {
            ForEach(0..<7, id: \.self) { dayIndex in
                dayColumn(dayIndex)
            }
        }
    }

    private func dayColumn(_ dayIndex: Int) -> some View {
        let entries = planEntries.filter { $0.dayIndex == dayIndex }
        return VStack(alignment: .leading, spacing: IceVault.Space.sm) {
            HStack {
                Text(dayNames[dayIndex])
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(IceVault.Colors.primary)
                Spacer()
                Button {
                    addingForDay = dayIndex
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(IceVault.Colors.accent)
                }
                .buttonStyle(.plain)
            }

            if entries.isEmpty {
                Text("No books scheduled")
                    .font(.caption)
                    .foregroundStyle(IceVault.Colors.textMuted)
                    .padding(.vertical, 4)
            } else {
                ForEach(entries) { entry in
                    let url = entry.coverID.map { VaultOpenLibraryEndpoint.cover(id: $0) }
                    HStack(spacing: IceVault.Space.sm) {
                        if let url {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                        .frame(width: 36, height: 52)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(IceVault.Colors.primarySoft)
                                        .frame(width: 36, height: 52)
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(IceVault.Colors.primarySoft)
                                .frame(width: 36, height: 52)
                        }
                        Text(entry.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(IceVault.Colors.text)
                            .lineLimit(2)
                        Spacer()
                        Button {
                            removeEntry(entry)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(IceVault.Colors.danger)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(IceVault.Space.sm)
                    .background(IceVault.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(IceVault.Colors.border, lineWidth: 1))
                }
            }
        }
        .padding(IceVault.Space.md)
        .iceVaultCard()
    }

    // MARK: - Helpers

    private func load() async {
        let fd = FetchDescriptor<SDWeekPlanEntry>(sortBy: [SortDescriptor(\.addedAt)])
        planEntries = (try? context.fetch(fd)) ?? []
    }

    private func addBookToDay(_ book: VaultBook, dayIndex: Int) {
        let entry = SDWeekPlanEntry(
            dayIndex: dayIndex,
            bookID: book.id.uuidString,
            title: book.title,
            coverID: book.coverID
        )
        context.insert(entry)
        try? context.save()
        Task { await load() }
    }

    private func removeEntry(_ entry: SDWeekPlanEntry) {
        context.delete(entry)
        try? context.save()
        Task { await load() }
    }
}

// MARK: - Add Book Sheet

private struct AddBookToDaySheet: View {
    let onSelect: (VaultBook) -> Void

    @EnvironmentObject private var deps: VaultAppDependencies
    @Environment(\.dismiss) private var dismiss

    @State private var libraryBooks: [VaultBook] = []
    @State private var query: String = ""
    @State private var searchState: VaultViewState<[BookSearchResult]> = .idle
    @State private var searchTask: Task<Void, Never>?
    @State private var searchEpoch = 0

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var localMatches: [VaultBook] {
        let q = trimmedQuery.lowercased()
        if q.isEmpty { return libraryBooks }
        return libraryBooks.filter {
            $0.title.lowercased().contains(q) || $0.authors.joined(separator: " ").lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                searchBarSection
                if !deps.connectivity.isOnline, !trimmedQuery.isEmpty {
                    offlineBanner
                }
                librarySection
                remoteSearchSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(IceVault.Colors.background)
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await loadLibrary() }
        }
    }

    private var searchBarSection: some View {
        Section {
            HStack(spacing: IceVault.Space.sm) {
                Image(systemName: "magnifyingglass").foregroundStyle(IceVault.Colors.textMuted)
                TextField("Search shelf or Open Library", text: $query)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(IceVault.Colors.text)
                    .onChange(of: query) { _, newValue in
                        scheduleSearch(newValue)
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                        searchState = .idle
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(IceVault.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, IceVault.Space.sm)
            .frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 10).fill(IceVault.Colors.surfaceAlt))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var offlineBanner: some View {
        Section {
            HStack(spacing: IceVault.Space.sm) {
                Image(systemName: "wifi.slash")
                Text("Offline — only your shelf is searchable")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(IceVault.Colors.textMuted)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var librarySection: some View {
        if trimmedQuery.isEmpty {
            if libraryBooks.isEmpty {
                Section {
                    Text("Search Open Library or add books to your shelf first.")
                        .foregroundStyle(IceVault.Colors.textMuted)
                        .listRowBackground(Color.clear)
                }
            } else {
                Section("Your Shelf") {
                    ForEach(libraryBooks) { book in
                        libraryRow(book)
                    }
                }
            }
        } else if !localMatches.isEmpty {
            Section("Your Shelf") {
                ForEach(localMatches) { book in
                    libraryRow(book)
                }
            }
        }
    }

    @ViewBuilder
    private var remoteSearchSection: some View {
        if !trimmedQuery.isEmpty {
            switch searchState {
            case .idle, .offline:
                if localMatches.isEmpty, libraryBooks.isEmpty {
                    Section {
                        Text("Type a title, author, or ISBN to search Open Library.")
                            .foregroundStyle(IceVault.Colors.textMuted)
                            .listRowBackground(Color.clear)
                    }
                } else if localMatches.isEmpty {
                    Section {
                        Text("No shelf matches — try a different query.")
                            .foregroundStyle(IceVault.Colors.textMuted)
                            .listRowBackground(Color.clear)
                    }
                }

            case .loading:
                Section {
                    HStack(spacing: IceVault.Space.md) {
                        ProgressView().tint(IceVault.Colors.accent)
                        Text("Searching Open Library…")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(IceVault.Colors.textMuted)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

            case .loaded(let results):
                Section("Open Library") {
                    ForEach(results) { result in
                        Button {
                            onSelect(VaultBookFactory.newFromSearchResult(result, status: .wantToRead))
                        } label: {
                            SecuredBookCell(
                                title: result.title,
                                authorsLine: result.authors.joined(separator: ", "),
                                coverURL: CoverURLBuilder.url(coverID: result.coverID).flatMap(URL.init(string:)),
                                year: result.year,
                                compact: true
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

            case .error(let msg):
                Section {
                    Text(msg)
                        .foregroundStyle(IceVault.Colors.textMuted)
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    private func libraryRow(_ book: VaultBook) -> some View {
        Button {
            onSelect(book)
        } label: {
            SecuredBookCell(
                title: book.title,
                authorsLine: book.authors.joined(separator: ", "),
                coverURL: book.coverURL.flatMap(URL.init(string:)),
                compact: true
            )
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    private func loadLibrary() async {
        libraryBooks = (try? deps.library.allBooks()) ?? []
    }

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchEpoch += 1
            searchState = .idle
            return
        }
        searchEpoch += 1
        let epoch = searchEpoch
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 380_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(trimmed, epoch: epoch)
        }
    }

    @MainActor
    private func runSearch(_ text: String, epoch: Int) async {
        guard epoch == searchEpoch else { return }
        if !deps.connectivity.isOnline {
            searchState = .offline
            return
        }
        searchState = .loading
        do {
            let results: [BookSearchResult]
            if VaultISBNNormalizer.looksLikeISBN(text) {
                let q = VaultISBNNormalizer.canonicalDigits(text)
                results = try await deps.openLibrary.search(query: q, limit: 30, offset: 0)
            } else {
                results = try await deps.openLibrary.search(title: text, limit: 30, offset: 0)
            }
            guard epoch == searchEpoch else { return }
            if results.isEmpty {
                searchState = .error("No books matched \"\(text)\" on Open Library.")
            } else {
                searchState = .loaded(results)
            }
        } catch {
            guard epoch == searchEpoch else { return }
            if error is CancellationError { return }
            let msg = (error as? LocalizedError)?.errorDescription ?? "Couldn't reach Open Library."
            searchState = .error(msg)
        }
    }
}
