import SwiftUI

struct VaultNotesView: View {
    @EnvironmentObject private var deps: VaultAppDependencies
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID

    @State private var book: VaultBook?
    @State private var rating: Double = 0
    @State private var noteText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: IceVault.Space.lg) {
                if let b = book {
                    bookHeader(b)
                    ratingSection
                    noteSection
                    saveSection
                } else {
                    ProgressView().tint(IceVault.Colors.accent).padding(.top, 40)
                }
            }
            .padding(.horizontal, IceVault.Space.xl)
            .padding(.bottom, 40)
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
        .navigationTitle("Rating & Notes")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func bookHeader(_ b: VaultBook) -> some View {
        HStack(spacing: IceVault.Space.md) {
            let url = b.coverURL.flatMap(URL.init(string:))
            IVCoverView(url: url, title: b.title, author: b.authors.first, width: 60, height: 90)
            VStack(alignment: .leading, spacing: 4) {
                Text(b.title)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(IceVault.Colors.text)
                    .lineLimit(2)
                Text(b.authors.joined(separator: ", "))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(IceVault.Colors.textMuted)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(IceVault.Space.md)
        .iceVaultCard()
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Your Rating")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
            IVRatingStars(rating: $rating)
            if rating > 0 {
                Text(String(format: "%.0f out of 5 stars", rating))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IceVault.Colors.textMuted)
            }
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: IceVault.Space.md) {
            Text("Your Note")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(IceVault.Colors.surfaceAlt)
                    .frame(minHeight: 140)
                TextEditor(text: $noteText)
                    .frame(minHeight: 140)
                    .font(.system(size: 14))
                    .foregroundStyle(IceVault.Colors.text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(8)
                if noteText.isEmpty {
                    Text("Write your thoughts about this book…")
                        .font(.system(size: 14))
                        .foregroundStyle(IceVault.Colors.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(IceVault.Space.lg)
        .iceVaultCard()
    }

    private var saveSection: some View {
        VStack(spacing: IceVault.Space.md) {
            Button("Save Rating & Note") { save() }
                .buttonStyle(IceVaultPrimaryButton())
            if book?.note != nil {
                Button("Delete Note", role: .destructive) { deleteNote() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(IceVault.Colors.danger)
            }
        }
    }

    // MARK: - Helpers

    private func load() async {
        do {
            book = try deps.library.book(id: bookID)
            if let b = book {
                rating = b.rating ?? 0
                noteText = b.note ?? ""
            }
        } catch { book = nil }
    }

    private func save() {
        guard var b = book else { return }
        let now = Date.now
        if b.note == nil || (b.note ?? "").isEmpty { b.noteCreatedAt = now }
        b.noteUpdatedAt = now
        b.note = noteText.isEmpty ? nil : noteText
        b.rating = rating > 0 ? rating : nil
        b.updatedAt = now
        do {
            try deps.library.upsert(b)
            book = b
            dismiss()
        } catch {}
    }

    private func deleteNote() {
        guard var b = book else { return }
        b.note = nil
        b.noteCreatedAt = nil
        b.noteUpdatedAt = nil
        b.updatedAt = .now
        do {
            try deps.library.upsert(b)
            noteText = ""
            book = b
        } catch {}
    }
}
