import SwiftUI

enum Theme {
    // Backgrounds
    static let bg = Color(hex: "111014")
    static let surface = Color.white.opacity(0.03)
    static let raised = Color.white.opacity(0.05)
    static let hover = Color.white.opacity(0.08)

    // Borders
    static let border = Color.white.opacity(0.06)
    static let borderLight = Color.white.opacity(0.10)

    // Accent
    static let accent = Color(hex: "EF8B6E")
    static let accentSecondary = Color(hex: "E8C47A")
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "EF8B6E"), Color(hex: "E8C47A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Text
    static let textPrimary = Color(hex: "F0EBE6")
    static let textSecondary = Color(hex: "9A928A")
    static let textDim = Color(hex: "5A544E")
    static let textMuted = Color(hex: "3A3530")

    // Semantic
    static let positive = Color(hex: "7EC49B")
    static let negative = Color(hex: "D4746A")
    static let warning = Color(hex: "E8C47A")

    // Card style
    static let cardBackground = Color.white.opacity(0.03)
    static let cardBorder = Color.white.opacity(0.06)
    static let cardShadow = Color.black.opacity(0.12)
}

// MARK: - Card Modifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Theme.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: Theme.cardShadow, radius: 10, y: 2)
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.textSecondary)
    }
}
