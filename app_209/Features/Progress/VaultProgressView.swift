import SwiftUI

struct VaultProgressView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    let bookID: UUID

    @State private var book: VaultBook?
    @State private var entries: [VaultProgressEntry] = []
    @State private var currentPageText: String = ""
    @State private var totalPagesText: String = ""
    @State private var debounce: Task<Void, Never>?
    @State private var showCompletedAlert = false

    private var progress: Double {
        guard let c = Int(currentPageText), let t = Int(totalPagesText), t > 0 else { return 0 }
        return VaultProgressCalculator.progressFraction(currentPage: c, totalPages: t) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: IceVault.Space.lg) {
                if let b = book {
                    progressCard(b)
                    quickBumpSection(b)
                    logSection
                } else {
                    ProgressView().tint(IceVault.Colors.accent).padding(.top, 40)
                }
            }
            .padding(.horizontal, IceVault.Space.xl)
            .padding(.bottom, 40)
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onChange(of: currentPageText) { _, _ in debounceSave() }
        .onChange(of: totalPagesText) { _, _ in debounceSave() }
        .alert("All done!", isPresented: $showCompletedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've reached the last page. Consider leaving a rating or note.")
        }
    }

    // MARK: - Progress card

    private func progressCard(_ b: VaultBook) -> some View {
        VStack(alignment: .leading, spacing: IceVault.Space.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reading Progress")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(IceVault.Colors.primary)
                    Text(b.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(IceVault.Colors.textMuted)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(IceVault.Colors.accent)
            }

            IVProgressBar(value: progress)

            HStack(spacing: IceVault.Space.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current page").font(.caption).foregroundStyle(IceVault.Colors.textMuted)
                    TextField("0", text: $currentPageText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 18, weight: .bold))
                        .padding(IceVault.Space.sm)
                        .background(RoundedRectangle(cornerRadius: 8).fill(IceVault.Colors.surfaceAlt))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total pages").font(.caption).foregroundStyle(IceVault.Colors.textMuted)
                    TextField("?", text: $totalPagesText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 18, weight: .bold))
                        .padding(IceVault.Space.sm)
                        .background(RoundedRectangle(cornerRadius: 8).fill(IceVault.Colors.surfaceAlt))
                }
            }

            Button("Mark as Finished") {
                markFinished()
            }
            .buttonStyle(IceVaultSecondaryButton())
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private func quickBumpSection(_ b: VaultBook) -> some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Quick add pages")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
            HStack(spacing: IceVault.Space.md) {
                ForEach([1, 5, 10, 25], id: \.self) { delta in
                    Button("+\(delta)") { bumpPages(delta) }
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(IceVault.Colors.primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(IceVault.Colors.primarySoft).overlay(Capsule().stroke(IceVault.Colors.border, lineWidth: 1)))
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Session Log")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
            if entries.isEmpty {
                Text("No sessions logged yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(IceVault.Colors.textMuted)
            } else {
                ForEach(entries.reversed()) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Page \(entry.pageNumber)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(IceVault.Colors.text)
                            if let total = entry.totalPages {
                                Text("of \(total)")
                                    .font(.caption)
                                    .foregroundStyle(IceVault.Colors.textMuted)
                            }
                        }
                        Spacer()
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(IceVault.Colors.textMuted)
                    }
                    .padding(.vertical, 4)
                    Divider().overlay(IceVault.Colors.border)
                }
            }
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    // MARK: - Helpers

    private func load() async {
        do {
            book = try deps.library.book(id: bookID)
            entries = try deps.progress.entries(for: bookID)
            if let b = book {
                currentPageText = String(b.currentPage)
                totalPagesText = b.totalPages.map(String.init) ?? ""
            }
        } catch { book = nil }
    }

    private func bumpPages(_ delta: Int) {
        guard let t = Int(totalPagesText), t > 0 else { return }
        let base = Int(currentPageText) ?? 0
        let next = min(t, base + delta)
        currentPageText = String(next)
        commitSave()
        if next >= t { showCompletedAlert = true }
    }

    private func markFinished() {
        guard let t = Int(totalPagesText), t > 0 else { return }
        currentPageText = String(t)
        guard var b = book else { return }
        b.currentPage = t
        b.status = .finished
        b.finishedAt = .now
        b.updatedAt = .now
        commitSave(overrideBook: b)
        showCompletedAlert = true
    }

    private func debounceSave() {
        debounce?.cancel()
        debounce = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { commitSave() }
        }
    }

    private func commitSave(overrideBook: VaultBook? = nil) {
        guard var b = overrideBook ?? book else { return }
        let newTotal = Int(totalPagesText).flatMap { $0 > 0 ? $0 : nil }
        let rawCurrent = Int(currentPageText) ?? b.currentPage
        let newCurrent = VaultProgressCalculator.clampedPage(rawCurrent, totalPages: newTotal)
        b.currentPage = newCurrent
        b.totalPages = newTotal
        if b.status == .reading && b.startedAt == nil { b.startedAt = .now }
        b.updatedAt = .now
        do {
            try deps.library.upsert(b)
            try deps.progress.logEntry(bookID: b.id, pageNumber: newCurrent, totalPages: newTotal)
            book = b
            entries = (try? deps.progress.entries(for: bookID)) ?? entries
        } catch {}
    }
}
