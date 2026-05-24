import SwiftUI

struct SubjectPicksView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    var onSelectResult: ((BookSearchResult) -> Void)? = nil

    @State private var activePick: ActivePick? = nil
    @State private var state: VaultViewState<[SubjectBookResult]> = .idle

    private enum ActivePick: Equatable {
        case discover(VaultMoodCatalog.SubjectPick)
        case mood(VaultMoodCatalog.MoodPick)

        var slug: String {
            switch self {
            case .discover(let pick): pick.slug
            case .mood(let pick): pick.subjectSlug
            }
        }

        var title: String {
            switch self {
            case .discover(let pick): pick.title
            case .mood(let pick): pick.title
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.lg) {
            discoverSection
            moodSection
            if let activePick {
                subjectResults(activePick)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.sm) {
            Text("Discover")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
                .padding(.horizontal, IceVault.Space.lg)
                .padding(.top, IceVault.Space.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IceVault.Space.sm) {
                    ForEach(VaultMoodCatalog.discoverSubjects) { pick in
                        genreChip(
                            title: pick.title,
                            icon: pick.icon,
                            isSelected: activePick == .discover(pick)
                        ) {
                            select(.discover(pick))
                        }
                    }
                }
                .padding(.horizontal, IceVault.Space.lg)
            }
            .scrollClipDisabled()
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.sm) {
            Text("How are you feeling?")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
                .padding(.horizontal, IceVault.Space.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IceVault.Space.sm) {
                    ForEach(VaultMoodCatalog.moods) { pick in
                        genreChip(
                            title: pick.title,
                            icon: pick.icon,
                            isSelected: activePick == .mood(pick)
                        ) {
                            select(.mood(pick))
                        }
                    }
                }
                .padding(.horizontal, IceVault.Space.lg)
            }
            .scrollClipDisabled()
        }
    }

    private func genreChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .white : IceVault.Colors.primary)
                Text(title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(isSelected ? .white : IceVault.Colors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 76, height: 76)
            .background(
                RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous)
                    .fill(isSelected ? IceVault.Colors.primary : IceVault.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous)
                            .stroke(IceVault.Colors.border, lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous))
        }
        .buttonStyle(.borderless)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func subjectResults(_ pick: ActivePick) -> some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: IceVault.Space.md) {
                ProgressView().tint(IceVault.Colors.accent)
                Text("Loading \(pick.title) picks…")
                    .font(.system(size: 13))
                    .foregroundStyle(IceVault.Colors.textMuted)
            }
            .padding(.horizontal, IceVault.Space.lg)

        case .loaded(let books):
            VStack(alignment: .leading, spacing: IceVault.Space.md) {
                Text(pick.title)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(IceVault.Colors.text)
                    .padding(.horizontal, IceVault.Space.lg)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: IceVault.Space.md) {
                        ForEach(books) { book in
                            let url = CoverURLBuilder.url(coverID: book.coverID).flatMap(URL.init(string:))
                            Button {
                                let result = BookSearchResult(
                                    openLibraryId: VaultOpenLibraryMapper.workId(fromKey: book.key),
                                    workKey: book.key,
                                    title: book.title,
                                    authors: book.authors,
                                    coverID: book.coverID,
                                    year: book.year,
                                    subjects: [],
                                    pageCount: nil
                                )
                                onSelectResult?(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    IVCoverView(url: url, title: book.title, author: book.authors.first, width: 100, height: 150)
                                    Text(book.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(IceVault.Colors.text)
                                        .lineLimit(2)
                                        .frame(width: 100, alignment: .leading)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.horizontal, IceVault.Space.lg)
                }
                .scrollClipDisabled()
            }

        case .error(let msg):
            IVEmptyState(
                title: "Couldn't load",
                message: msg,
                systemImage: "wifi.exclamationmark",
                actionTitle: "Retry"
            ) { select(pick) }
            .padding(.horizontal, IceVault.Space.lg)

        case .offline:
            IVEmptyState(title: "Offline", message: "Connect to browse picks.", systemImage: "wifi.slash")
                .padding(.horizontal, IceVault.Space.lg)
        }
    }

    private func select(_ pick: ActivePick) {
        activePick = pick
        guard deps.connectivity.isOnline else { state = .offline; return }
        state = .loading
        Task { @MainActor in
            do {
                let books = try await deps.openLibrary.subjectBooks(slug: pick.slug, limit: 20, offset: 0)
                state = books.isEmpty ? .error("No books found for \(pick.title).") : .loaded(books)
            } catch {
                if error is CancellationError { return }
                let msg = (error as? LocalizedError)?.errorDescription ?? "Couldn't reach Open Library."
                state = .error(msg)
            }
        }
    }
}
