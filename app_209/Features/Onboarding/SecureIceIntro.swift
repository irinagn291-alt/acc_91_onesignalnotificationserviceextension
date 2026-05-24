import SwiftUI

struct SecureIceIntro: View {
    let onComplete: () -> Void

    @State private var page: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let screens: [(icon: String, heading: String, body: String)] = [
        (
            "lock.shield.fill",
            "Your Reading Vault",
            "Keep every book locked in one secure place. Your personal library, always private and always yours."
        ),
        (
            "chart.line.uptrend.xyaxis",
            "Track Every Page",
            "Log your progress, visualise how far you've come, and celebrate milestones as you read."
        ),
        (
            "calendar.badge.plus",
            "Plan Your Week",
            "Schedule exactly what to read each day. Build the reading habit one session at a time."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(screens.indices, id: \.self) { i in
                    screenCard(screens[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : .easeInOut, value: page)

            HStack(spacing: IceVault.Space.md) {
                if page > 0 {
                    Button("Back") { page -= 1 }
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(IceVault.Colors.primary)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(IceVault.Colors.surface)
                                .overlay(Capsule().stroke(IceVault.Colors.border, lineWidth: 1))
                        )
                        .buttonStyle(IceVaultScalePressButton())
                }
                Spacer(minLength: 0)
                if page < screens.count - 1 {
                    Button("Next") { page += 1 }
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(IceVault.Colors.primary))
                        .buttonStyle(IceVaultScalePressButton())
                } else {
                    Button("Get Started") { onComplete() }
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(IceVault.Colors.primary))
                        .buttonStyle(IceVaultScalePressButton())
                }
            }
            .padding(.horizontal, IceVault.Space.xl)
            .padding(.vertical, IceVault.Space.lg)
            .padding(.bottom, 8)
        }
        .background(IceVault.Colors.background.ignoresSafeArea())
    }

    private func screenCard(_ screen: (icon: String, heading: String, body: String)) -> some View {
        VStack(spacing: IceVault.Space.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(IceVault.Colors.primary.opacity(0.08))
                    .frame(width: 140, height: 140)
                Image(systemName: screen.icon)
                    .font(.system(size: 58))
                    .foregroundStyle(IceVault.Colors.primary)
            }

            VStack(spacing: IceVault.Space.md) {
                Text(screen.heading)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(IceVault.Colors.text)
                    .multilineTextAlignment(.center)

                Text(screen.body)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(IceVault.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, IceVault.Space.xl)
            }

            Spacer()
        }
        .padding(.horizontal, IceVault.Space.xl)
    }
}
