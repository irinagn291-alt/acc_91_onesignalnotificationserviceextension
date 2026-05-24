import SwiftUI

enum VaultDiscoverRoute: Hashable {
    case searchResult(BookSearchResult)
    case workDetail(workKey: String, fallbackAuthors: [String])
}

struct VaultLookupView: View {
    @EnvironmentObject private var deps: VaultAppDependencies

    @State private var query: String = ""
    @State private var state: VaultViewState<[BookSearchResult]> = .idle
    @State private var searchTask: Task<Void, Never>?
    @State private var searchEpoch = 0
    @State private var showScanner = false
    @State private var showSimulatorAlert = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                searchBarSection
                offlineBanner
                contentSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 1)
            .background(IceVault.Colors.background)
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        #if targetEnvironment(simulator)
                        showSimulatorAlert = true
                        #else
                        showScanner = true
                        #endif
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18))
                    }
                    .accessibilityLabel("Scan ISBN barcode")
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                VaultISBNScannerLock(
                    onCode: { code in
                        showScanner = false
                        query = code
                        scheduleSearch(code)
                    },
                    onDismiss: { showScanner = false }
                )
                .ignoresSafeArea()
            }
            .alert("Camera unavailable", isPresented: $showSimulatorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("ISBN scanning requires a physical device with a camera.")
            }
            .navigationDestination(for: VaultDiscoverRoute.self) { route in
                switch route {
                case .searchResult(let result):
                    VaultBookDetailView(route: .searchResult(result))
                case .workDetail(let key, let authors):
                    VaultBookDetailView(route: .workDetail(key: key, authors: authors))
                }
            }
        }
    }

    // MARK: - Sections

    private var searchBarSection: some View {
        Section {
            HStack(spacing: IceVault.Space.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(IceVault.Colors.textMuted)
                TextField("Search title, author, or ISBN", text: $query)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(IceVault.Colors.text)
                    .onChange(of: query) { _, newValue in
                        scheduleSearch(newValue)
                    }
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(IceVault.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, IceVault.Space.md)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous)
                    .fill(IceVault.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous)
                            .stroke(IceVault.Colors.border, lineWidth: 1)
                    )
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    @ViewBuilder
    private var offlineBanner: some View {
        if !deps.connectivity.isOnline {
            Section {
                HStack(spacing: IceVault.Space.sm) {
                    Image(systemName: "wifi.slash")
                    Text("You're offline — search results unavailable")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(IceVault.Colors.textMuted)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch state {
        case .idle:
            Section {
                SubjectPicksView { result in
                    path.append(VaultDiscoverRoute.searchResult(result))
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }

        case .loading:
            Section {
                HStack(spacing: IceVault.Space.md) {
                    ProgressView().tint(IceVault.Colors.accent)
                    Text("Searching vault…")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(IceVault.Colors.textMuted)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

        case .loaded(let results):
            Section {
                ForEach(results) { result in
                    let url = CoverURLBuilder.url(coverID: result.coverID).flatMap(URL.init(string:))
                    Button {
                        path.append(VaultDiscoverRoute.searchResult(result))
                    } label: {
                        SecuredBookCell(
                            title: result.title,
                            authorsLine: result.authors.joined(separator: ", "),
                            coverURL: url,
                            year: result.year,
                            compact: true
                        )
                    }
                    .buttonStyle(.borderless)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            } header: {
                Text("Results")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(IceVault.Colors.text)
                    .textCase(nil)
            }

        case .error(let msg):
            Section {
                IVEmptyState(
                    title: "Search unavailable",
                    message: msg,
                    systemImage: "wifi.exclamationmark",
                    actionTitle: "Retry"
                ) { scheduleSearch(query) }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

        case .offline:
            Section {
                IVEmptyState(
                    title: "You're offline",
                    message: "Connect to the internet to search the Open Library catalogue.",
                    systemImage: "wifi.slash"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    // MARK: - Search logic

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchEpoch += 1
            state = .idle
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
            state = .offline
            return
        }
        state = .loading
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
                state = .error("No books matched \"\(text)\". Try another query.")
            } else {
                state = .loaded(results)
            }
        } catch {
            guard epoch == searchEpoch else { return }
            if error is CancellationError { return }
            let msg = (error as? LocalizedError)?.errorDescription ?? "Couldn't reach Open Library."
            state = .error(msg)
        }
    }
}
