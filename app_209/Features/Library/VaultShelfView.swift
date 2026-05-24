import SwiftUI

enum VaultShelfSort: String, CaseIterable {
    case dateAdded = "Date Added"
    case title = "Title"
    case rating = "Rating"
}

struct VaultShelfView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    @State private var allBooks: [VaultBook] = []
    @State private var statusFilter: VaultReadingStatus? = nil
    @State private var query: String = ""
    @State private var sortBy: VaultShelfSort = .dateAdded
    @State private var displayMode: VaultDisplayMode = .list
    @State private var path = NavigationPath()

    private var filtered: [VaultBook] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var books = allBooks.filter { b in
            let statusOK = statusFilter == nil || b.status == statusFilter
            let textOK = q.isEmpty || b.title.lowercased().contains(q) || b.authors.joined(separator: " ").lowercased().contains(q)
            return statusOK && textOK
        }
        switch sortBy {
        case .dateAdded:
            books.sort { $0.addedAt > $1.addedAt }
        case .title:
            books.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .rating:
            books.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
        return books
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                searchBarSection
                filterChipsSection
                booksSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(IceVault.Colors.background)
            .navigationTitle("My Vault")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        displayMode = displayMode == .list ? .grid : .list
                    } label: {
                        Image(systemName: displayMode == .list ? "square.grid.2x2" : "list.bullet")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Sort") {
                        ForEach(VaultShelfSort.allCases, id: \.self) { s in
                            Button(s.rawValue) { sortBy = s }
                        }
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                VaultShelfDetailView(bookID: id)
            }
            .onAppear { Task { await refresh() } }
            .refreshable { await refresh() }
        }
    }

    // MARK: - Sections

    private var searchBarSection: some View {
        Section {
            HStack(spacing: IceVault.Space.md) {
                Image(systemName: "magnifyingglass").foregroundStyle(IceVault.Colors.textMuted)
                TextField("Search your shelf", text: $query).foregroundStyle(IceVault.Colors.text)
            }
            .padding(.horizontal, IceVault.Space.md)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous)
                    .fill(IceVault.Colors.surface)
                    .overlay(RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous).stroke(IceVault.Colors.border, lineWidth: 1))
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
        }
    }

    private var filterChipsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IceVault.Space.sm) {
                    filterChip("All", statusFilter == nil) { statusFilter = nil }
                    ForEach(VaultReadingStatus.allCases, id: \.self) { s in
                        filterChip(s.localizedTitle, statusFilter == s) { statusFilter = s }
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
        }
    }

    @ViewBuilder
    private var booksSection: some View {
        if filtered.isEmpty {
            Section {
                IVEmptyState(
                    title: "Vault is empty",
                    message: "Search for books and add them to your personal vault.",
                    systemImage: "lock.shield"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
        } else if displayMode == .list {
            Section {
                ForEach(filtered) { b in
                    let url = b.coverURL.flatMap(URL.init(string:))
                    NavigationLink(value: b.id) {
                        SecuredBookCell(
                            title: b.title,
                            authorsLine: b.authors.joined(separator: ", "),
                            coverURL: url,
                            year: b.year,
                            status: b.status,
                            rating: b.rating,
                            compact: false
                        )
                    }
                    .buttonStyle(IceVaultScalePressButton())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onDelete(perform: deleteBooks)
            }
        } else {
            Section {
                let cols = [GridItem(.adaptive(minimum: 130), spacing: 12)]
                LazyVGrid(columns: cols, spacing: 16) {
                    ForEach(filtered) { b in
                        let url = b.coverURL.flatMap(URL.init(string:))
                        NavigationLink(value: b.id) {
                            SecuredBookGridCell(
                                title: b.title,
                                authorsLine: b.authors.joined(separator: ", "),
                                coverURL: url,
                                year: b.year,
                                status: b.status
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
    }

    // MARK: - Helpers

    private func filterChip(_ title: String, _ selected: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(selected ? .white : IceVault.Colors.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? IceVault.Colors.primary : IceVault.Colors.surface).overlay(Capsule().stroke(IceVault.Colors.border, lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func refresh() async {
        do {
            allBooks = try deps.library.allBooks()
        } catch {
            allBooks = []
        }
    }

    private func deleteBooks(at offsets: IndexSet) {
        for i in offsets {
            let book = filtered[i]
            try? deps.library.delete(id: book.id)
        }
        Task { await refresh() }
    }
}
