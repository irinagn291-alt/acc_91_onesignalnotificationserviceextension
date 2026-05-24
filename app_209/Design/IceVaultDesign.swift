import SwiftUI
import UIKit

// MARK: - IceVault Design System

enum IceVault {
    enum Colors {
        static let primary    = Color(hex: "#1D3557")
        static let secondary  = Color(hex: "#A8DADC")
        static let background = Color(hex: "#F1FAEE")
        static let accent     = Color(hex: "#457B9D")
        static let text       = Color(hex: "#0B132B")

        static let surface       = Color.white
        static let surfaceAlt    = Color(hex: "#E8F4F5")
        static let textMuted     = Color(hex: "#4A5568")
        static let border        = Color(hex: "#A8DADC").opacity(0.4)
        static let primarySoft   = Color(hex: "#1D3557").opacity(0.1)
        static let accentSoft    = Color(hex: "#457B9D").opacity(0.12)
        static let secondarySoft = Color(hex: "#A8DADC").opacity(0.25)
        static let success       = Color(hex: "#2D6A4F")
        static let warning       = Color(hex: "#E9C46A")
        static let danger        = Color(hex: "#C1121F")
        static let rating        = Color(hex: "#F4A261")
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 30
        static let card: CGFloat = 14
    }

    enum Shadow {
        static func card(_ tint: Color = IceVault.Colors.primary.opacity(0.08)) -> (Color, CGFloat, CGFloat, CGFloat) {
            (tint, 18, 0, 6)
        }
        static func soft(_ tint: Color = IceVault.Colors.primary.opacity(0.05)) -> (Color, CGFloat, CGFloat, CGFloat) {
            (tint, 10, 0, 4)
        }
    }

    enum Typography {
        static func display(_ weight: Font.Weight = .black) -> Font { .system(size: 30, weight: weight) }
        static func title(_ weight: Font.Weight = .bold) -> Font { .system(size: 22, weight: weight) }
        static func headline(_ weight: Font.Weight = .semibold) -> Font { .system(size: 17, weight: weight) }
        static func body(_ weight: Font.Weight = .regular) -> Font { .system(size: 15, weight: weight) }
        static func caption(_ weight: Font.Weight = .regular) -> Font { .system(size: 12, weight: weight) }
    }

    static func coverAccent(for title: String) -> Color {
        let palette: [Color] = [
            Colors.primary, Colors.accent, Colors.success,
            Color(hex: "#264653"), Color(hex: "#2A9D8F"), Color(hex: "#1B4F72"),
            Color(hex: "#154360"),
        ]
        let hash = title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[abs(hash) % palette.count]
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Accessibility motion

enum IVReduceMotion {
    @MainActor static var enabled: Bool { UIAccessibility.isReduceMotionEnabled }
    @MainActor static func animation(_ preferred: Animation?) -> Animation? {
        enabled ? .linear(duration: 0.01) : preferred
    }
}

// MARK: - Button Styles

struct IceVaultPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: IceVault.Radius.card, style: .continuous)
                    .fill(IceVault.Colors.primary)
            )
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(IVReduceMotion.animation(.easeOut(duration: 0.15)), value: configuration.isPressed)
    }
}

struct IceVaultSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: IceVault.Radius.card, style: .continuous)
                    .fill(IceVault.Colors.primarySoft)
            )
            .foregroundStyle(IceVault.Colors.primary)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(IVReduceMotion.animation(.easeOut(duration: 0.15)), value: configuration.isPressed)
    }
}

struct IceVaultScalePressButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(IVReduceMotion.animation(.easeOut(duration: 0.18)), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier

struct IceVaultCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(IceVault.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: IceVault.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: IceVault.Radius.lg, style: .continuous)
                    .stroke(IceVault.Colors.border, lineWidth: 1)
            )
            .shadow(color: IceVault.Shadow.card().0, radius: IceVault.Shadow.card().1, x: IceVault.Shadow.card().2, y: IceVault.Shadow.card().3)
    }
}

extension View {
    func iceVaultCard() -> some View {
        modifier(IceVaultCardModifier())
    }

    func ivCardShadow() -> some View {
        let (c, r, x, y) = IceVault.Shadow.card()
        return shadow(color: c, radius: r, x: x, y: y)
    }

    func ivSoftShadow() -> some View {
        let (c, r, x, y) = IceVault.Shadow.soft()
        return shadow(color: c, radius: r, x: x, y: y)
    }
}

// MARK: - Reusable Sub-Components

struct IVCoverView: View {
    let url: URL?
    let title: String
    var author: String? = nil
    var width: CGFloat = 108
    var height: CGFloat = 162

    var body: some View {
        ZStack(alignment: .leading) {
            Group {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        case .failure:
                            placeholder
                        case .empty:
                            ProgressView().tint(IceVault.Colors.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }

            LinearGradient(
                colors: [Color.black.opacity(0.22), .clear],
                startPoint: .leading,
                endPoint: UnitPoint(x: 0.3, y: 0.5)
            )
            .frame(width: min(14, width * 0.12))
            .allowsHitTesting(false)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: IceVault.Radius.card, style: .continuous))
        .shadow(color: IceVault.Colors.primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityLabel("Cover: \(title)")
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [IceVault.coverAccent(for: title), IceVault.Colors.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: width * 0.42, height: 2)
                Spacer()
                Text(title)
                    .font(.system(size: max(9, width * 0.1), weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 8)
                if let author, !author.isEmpty {
                    Text(author.uppercased())
                        .font(.system(size: max(7, width * 0.08), weight: .heavy))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                Circle()
                    .strokeBorder(.white.opacity(0.45), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            }
            .padding(.vertical, 10)
        }
    }
}

struct IVRatingBadge: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(IceVault.Colors.rating)
            Text(String(format: "%.1f", rating))
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Capsule().fill(IceVault.Colors.accentSoft))
    }
}

struct IVStatusChip: View {
    let status: VaultReadingStatus

    private var colors: (Color, Color) {
        switch status {
        case .wantToRead: (IceVault.Colors.secondarySoft, IceVault.Colors.accent)
        case .reading:    (IceVault.Colors.primarySoft, IceVault.Colors.primary)
        case .finished:   (Color(hex: "#D4EDDA"), IceVault.Colors.success)
        case .paused:     (IceVault.Colors.accentSoft, IceVault.Colors.accent)
        }
    }

    var body: some View {
        Text(status.localizedTitle)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(colors.1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Capsule().fill(colors.0))
    }
}

struct IVProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(IceVault.Colors.surfaceAlt)
                Capsule()
                    .fill(IceVault.Colors.accent)
                    .frame(width: max(6, geo.size.width * min(1, max(0, value))))
                    .animation(IVReduceMotion.animation(.easeInOut(duration: 0.35)), value: value)
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Progress \(Int(min(1, max(0, value)) * 100)) percent")
    }
}

struct IVRatingStars: View {
    @Binding var rating: Double
    var maxStars: Int = 5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxStars, id: \.self) { i in
                Image(systemName: starSymbol(for: i))
                    .font(.title3)
                    .foregroundStyle(starAmount(for: i) > 0 ? IceVault.Colors.rating : IceVault.Colors.textMuted.opacity(0.35))
                    .onTapGesture {
                        withAnimation(IVReduceMotion.animation(.spring(duration: 0.25))) {
                            rating = Double(i)
                        }
                    }
                    .accessibilityLabel("Rate \(i) of \(maxStars) stars")
            }
        }
    }

    private func starAmount(for index: Int) -> Double {
        min(1, max(0, rating - Double(index - 1)))
    }

    private func starSymbol(for index: Int) -> String {
        starAmount(for: index) >= 1 ? "star.fill" : "star"
    }
}

struct IVEmptyState: View {
    let title: String
    let message: String
    var systemImage: String = "books.vertical"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: IceVault.Space.lg) {
            ZStack {
                Circle()
                    .fill(IceVault.Colors.secondarySoft)
                    .frame(width: 88, height: 88)
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundStyle(IceVault.Colors.accent)
            }
            Text(title)
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(IceVault.Colors.text)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(IceVault.Colors.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(IceVault.Colors.primary))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(IceVault.Space.xl)
        .frame(maxWidth: .infinity)
        .iceVaultCard()
    }
}

struct IVSubjectChip: View {
    let title: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(isSelected ? .white : IceVault.Colors.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(isSelected ? IceVault.Colors.primary : IceVault.Colors.surface)
                        .overlay(Capsule().stroke(IceVault.Colors.border, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct IVStatTile: View {
    let title: String
    let value: String
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IceVault.Colors.textMuted)
                Spacer()
                if let systemImage {
                    Image(systemName: systemImage).foregroundStyle(IceVault.Colors.textMuted)
                }
            }
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(IceVault.Colors.text)
        }
        .padding(IceVault.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous)
                .fill(IceVault.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: IceVault.Radius.md, style: .continuous)
                        .stroke(IceVault.Colors.border, lineWidth: 1)
                )
                .ivSoftShadow()
        )
    }
}

struct IVSettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var danger: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: IceVault.Space.md) {
                ZStack {
                    Circle()
                        .fill(danger ? IceVault.Colors.danger.opacity(0.12) : IceVault.Colors.primarySoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 19))
                        .foregroundStyle(danger ? IceVault.Colors.danger : IceVault.Colors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(danger ? IceVault.Colors.danger : IceVault.Colors.text)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(IceVault.Colors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(IceVault.Colors.textMuted)
            }
            .padding(IceVault.Space.md)
            .iceVaultCard()
        }
        .buttonStyle(IceVaultScalePressButton())
    }
}

struct IVInlineLinkRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: IceVault.Space.md) {
            ZStack {
                Circle()
                    .fill(IceVault.Colors.primarySoft)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(IceVault.Colors.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(IceVault.Colors.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(IceVault.Colors.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(IceVault.Colors.textMuted)
        }
        .padding(IceVault.Space.md)
        .iceVaultCard()
    }
}
