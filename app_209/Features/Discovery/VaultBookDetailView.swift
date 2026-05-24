import SwiftUI

enum VaultDetailRoute: Hashable {
    case searchResult(BookSearchResult)
    case workDetail(key: String, authors: [String])
    case localBook(UUID)
}

struct VaultBookDetailView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    let route: VaultDetailRoute

    @State private var workState: VaultViewState<WorkDetail> = .idle
    @State private var localBook: VaultBook?
    @State private var showAddSheet = false
    @State private var pendingStatus: VaultReadingStatus = .wantToRead

    private var isDiscovery: Bool {
        switch route {
        case .localBook: return false
        default: return true
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IceVault.Space.lg) {
                heroSection
                if isDiscovery { detailSection }
            }
            .padding(.horizontal, IceVault.Space.xl)
            .padding(.bottom, 40)
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
        .navigationTitle("Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isDiscovery {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add to Vault") { showAddSheet = true }
                        .fontWeight(.bold)
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showAddSheet) {
            addToVaultSheet
        }
    }

    // MARK: - Add Sheet

    private var addToVaultSheet: some View {
        NavigationStack {
            VStack(spacing: IceVault.Space.xl) {
                Text("Add to Vault")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(IceVault.Colors.text)

                Picker("Status", selection: $pendingStatus) {
                    ForEach(VaultReadingStatus.allCases, id: \.self) { s in
                        Label(s.localizedTitle, systemImage: s.icon).tag(s)
                    }
                }
                .pickerStyle(.menu)
                .tint(IceVault.Colors.primary)

                Button("Save to Vault") { addToLibrary() }
                    .buttonStyle(IceVaultPrimaryButton())
            }
            .padding(IceVault.Space.xl)
            .background(IceVault.Colors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showAddSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        switch route {
        case .localBook:
            if let b = localBook {
                localHero(b)
            } else {
                ProgressView().tint(IceVault.Colors.accent).frame(maxWidth: .infinity)
            }
        case .searchResult(let r):
            if case .loaded(let d) = workState {
                remoteHero(title: d.title, authors: d.authors, coverID: d.coverID, year: d.year, subjects: d.subjects)
            } else {
                previewHero(title: r.title, authors: r.authors, coverID: r.coverID, year: r.year)
            }
        case .workDetail(_, let authors):
            if case .loaded(let d) = workState {
                remoteHero(title: d.title, authors: d.authors, coverID: d.coverID, year: d.year, subjects: d.subjects)
            } else {
                VStack(spacing: 12) {
                    ProgressView().tint(IceVault.Colors.accent)
                    Text(authors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(IceVault.Colors.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func previewHero(title: String, authors: [String], coverID: Int?, year: Int?) -> some View {
        let url = CoverURLBuilder.url(coverID: coverID).flatMap(URL.init(string:))
        return VStack(spacing: IceVault.Space.md) {
            IVCoverView(url: url, title: title, author: authors.first, width: 140, height: 210)
            Text(title)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
                .multilineTextAlignment(.center)
            Text(authors.isEmpty ? "Unknown author" : authors.joined(separator: ", "))
                .foregroundStyle(IceVault.Colors.textMuted)
            if let y = year {
                Text(String(y)).font(.caption.weight(.semibold)).foregroundStyle(IceVault.Colors.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(IceVault.Space.xl)
        .iceVaultCard()
    }

    private func remoteHero(title: String, authors: [String], coverID: Int?, year: Int?, subjects: [String]) -> some View {
        let url = CoverURLBuilder.url(coverID: coverID).flatMap(URL.init(string:))
        return VStack(spacing: IceVault.Space.md) {
            IVCoverView(url: url, title: title, author: authors.first, width: 140, height: 210)
            Text(title)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
                .multilineTextAlignment(.center)
            Text(authors.joined(separator: ", "))
                .foregroundStyle(IceVault.Colors.textMuted)
            if let y = year {
                Text(String(y)).font(.caption.weight(.semibold)).foregroundStyle(IceVault.Colors.textMuted)
            }
            if !subjects.isEmpty {
                subjectStrip(Array(subjects.prefix(8)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(IceVault.Space.xl)
        .iceVaultCard()
    }

    private func localHero(_ b: VaultBook) -> some View {
        let url = b.coverURL.flatMap(URL.init(string:))
        return VStack(spacing: IceVault.Space.md) {
            IVCoverView(url: url, title: b.title, author: b.authors.first, width: 140, height: 210)
            Text(b.title)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
                .multilineTextAlignment(.center)
            Text(b.authors.isEmpty ? "Unknown author" : b.authors.joined(separator: ", "))
                .foregroundStyle(IceVault.Colors.textMuted)
            HStack(spacing: IceVault.Space.sm) {
                if let r = b.rating { IVRatingBadge(rating: r) }
                IVStatusChip(status: b.status)
            }
            if !b.subjects.isEmpty {
                subjectStrip(Array(b.subjects.prefix(8)))
            }

            Picker("Status", selection: Binding(
                get: { localBook?.status ?? .wantToRead },
                set: { v in
                    guard var m = localBook else { return }
                    m.status = v
                    m.updatedAt = .now
                    persistLocal(m)
                }
            )) {
                ForEach(VaultReadingStatus.allCases, id: \.self) { s in
                    Text(s.localizedTitle).tag(s)
                }
            }
            .pickerStyle(.menu)
            .tint(IceVault.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(IceVault.Space.xl)
        .iceVaultCard()
    }

    private func subjectStrip(_ subjects: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(subjects, id: \.self) { s in
                    Text(s)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(IceVault.Colors.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(IceVault.Colors.surfaceAlt).overlay(Capsule().stroke(IceVault.Colors.border, lineWidth: 1)))
                }
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailSection: some View {
        switch workState {
        case .idle, .loading:
            ProgressView().tint(IceVault.Colors.accent).padding().frame(maxWidth: .infinity)
        case .offline:
            IVEmptyState(title: "You're offline", message: "Connect to load full book details.", systemImage: "wifi.slash")
        case .error(let msg):
            IVEmptyState(title: "Couldn't load details", message: msg, systemImage: "wifi.exclamationmark", actionTitle: "Retry") {
                Task { await loadRemote() }
            }
        case .loaded(let d):
            if let desc = d.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: IceVault.Space.md) {
                    Text("About")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(IceVault.Colors.text)
                    Text(desc)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(IceVault.Colors.text)
                        .lineSpacing(5)
                }
                .padding(IceVault.Space.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .iceVaultCard()
            }

            Link(destination: URL(string: "https://openlibrary.org\(d.workKey)")!) {
                IVInlineLinkRow(icon: "link", title: "Open in Open Library", subtitle: "openlibrary.org")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Load

    private func load() async {
        switch route {
        case .localBook(let id):
            localBook = try? deps.library.book(id: id)
        case .searchResult(let r):
            await loadRemote(workKey: r.workKey, authors: r.authors)
        case .workDetail(let key, let authors):
            await loadRemote(workKey: key, authors: authors)
        }
    }

    private func loadRemote() async {
        switch route {
        case .searchResult(let r):
            await loadRemote(workKey: r.workKey, authors: r.authors)
        case .workDetail(let key, let authors):
            await loadRemote(workKey: key, authors: authors)
        default:
            break
        }
    }

    private func loadRemote(workKey: String?, authors: [String]) async {
        guard let wk = workKey else { workState = .error("No work key available."); return }
        if !deps.connectivity.isOnline { workState = .offline; return }
        workState = .loading
        do {
            let d = try await deps.openLibrary.workDetail(workKey: wk, fallbackAuthors: authors)
            workState = .loaded(d)
        } catch {
            if error is CancellationError { return }
            let msg = (error as? LocalizedError)?.errorDescription ?? "Couldn't load details."
            workState = .error(msg)
        }
    }

    private func addToLibrary() {
        do {
            switch route {
            case .searchResult(let r):
                let book = VaultBookFactory.newFromSearchResult(r, status: pendingStatus)
                try deps.library.upsert(book)
            case .workDetail:
                if case .loaded(let d) = workState {
                    let book = VaultBookFactory.newFromWorkDetail(d, status: pendingStatus)
                    try deps.library.upsert(book)
                }
            case .localBook:
                break
            }
            showAddSheet = false
        } catch {
            showAddSheet = false
        }
    }

    private func persistLocal(_ b: VaultBook) {
        try? deps.library.upsert(b)
        localBook = b
    }
}
