import SwiftUI

struct SecuredBookCell: View {
    let title: String
    let authorsLine: String
    let coverURL: URL?
    var year: Int? = nil
    var status: VaultReadingStatus? = nil
    var rating: Double? = nil
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: compact ? IceVault.Space.md : IceVault.Space.lg) {
            let coverW: CGFloat = compact ? 72 : 100
            let coverH: CGFloat = compact ? 108 : 150

            IVCoverView(
                url: coverURL,
                title: title,
                author: authorsLine.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
                width: coverW,
                height: coverH
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: compact ? 15 : 17, weight: .black))
                    .foregroundStyle(IceVault.Colors.text)
                    .lineLimit(2)

                if !authorsLine.isEmpty {
                    Text(authorsLine)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(IceVault.Colors.textMuted)
                        .lineLimit(1)
                        .padding(.top, 5)
                }

                if let year {
                    Text(String(year))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(IceVault.Colors.textMuted)
                        .padding(.top, 3)
                }

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    if let rating {
                        IVRatingBadge(rating: rating)
                    }
                    if let status {
                        IVStatusChip(status: status)
                    }
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, compact ? 2 : 4)
        }
        .padding(compact ? IceVault.Space.sm : IceVault.Space.md)
        .background(IceVault.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: IceVault.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: IceVault.Radius.lg, style: .continuous)
                .stroke(IceVault.Colors.border, lineWidth: 1)
        )
        .ivCardShadow()
    }
}

struct SecuredBookGridCell: View {
    let title: String
    let authorsLine: String
    let coverURL: URL?
    var year: Int? = nil
    var status: VaultReadingStatus? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            IVCoverView(url: coverURL, title: title, author: authorsLine.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces), width: 120, height: 180)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(IceVault.Colors.text)
                    .lineLimit(2)
                if !authorsLine.isEmpty {
                    Text(authorsLine)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(IceVault.Colors.textMuted)
                        .lineLimit(1)
                }
                if let status {
                    IVStatusChip(status: status)
                        .padding(.top, 2)
                }
            }
            .frame(width: 120, alignment: .leading)
        }
    }
}
