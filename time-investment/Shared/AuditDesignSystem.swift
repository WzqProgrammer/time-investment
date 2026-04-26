import SwiftUI

enum AuditTheme {
    static let bg = Color(hex: "#131313")
    static let card = Color(hex: "#1C1B1B")
    static let cardHigh = Color(hex: "#2A2A2A")
    static let textPrimary = Color(hex: "#E5E2E1")
    static let textSecondary = Color(hex: "#D0C6AB")
    static let gold = Color(hex: "#E9C400")
    static let amber = Color(hex: "#FCA300")
    static let green = Color(hex: "#69F580")
    static let red = Color(hex: "#FFB4AB")

    static let radiusCard: CGFloat = 16
    static let radiusPill: CGFloat = 12
    static let pagePadding: CGFloat = 32
    static let sectionGap: CGFloat = 24
    static let cardGap: CGFloat = 16

    static let motionQuick: Double = 0.18
    static let motionStandard: Double = 0.26
}

struct AuditPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: AuditTheme.radiusPill)
                    .fill(
                        LinearGradient(
                            colors: [AuditTheme.gold, AuditTheme.amber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: AuditTheme.motionQuick), value: configuration.isPressed)
    }
}

struct AuditSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AuditTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: AuditTheme.radiusPill)
                    .fill(AuditTheme.cardHigh.opacity(configuration.isPressed ? 0.75 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: AuditTheme.radiusPill)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: AuditTheme.motionQuick), value: configuration.isPressed)
    }
}

struct CircleGaugeView: View {
    let progress: Double
    let centerText: String
    let caption: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(AuditTheme.cardHigh, lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(AuditTheme.gold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(centerText)
                    .font(.system(size: 34, weight: .bold))
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(AuditTheme.textSecondary)
            }
        }
    }
}

struct AuditCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: AuditTheme.radiusCard)
                    .fill(AuditTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AuditTheme.radiusCard)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
    }
}

struct AuditHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AuditTheme.gold.opacity(0.9))
            Text(title)
                .font(.system(size: 40, weight: .bold))
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
