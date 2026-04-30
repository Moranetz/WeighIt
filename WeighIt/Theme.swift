import SwiftUI

// MARK: - Theme
//
// Restrained palette. One brand color (warm peach) used as punctuation, not
// decoration. Surfaces are flat near-black with a single low-saturation tint.
// No gradient borders, no glow stacks, no atmospheric overlays — those signals
// belong to the launch screen and the onboarding hero, not the work surface.

enum Theme {
    // Background — a single deep, near-neutral with a faint cool bias so it
    // doesn't read as warm gray. The work surface stays calm; decoration is
    // earned by content.
    static let bg = Color(hex: "0A0A0C")
    static let bgElevated = Color(hex: "121215")

    // Surfaces — solid alphas, not gradients. A card is a card, not a window
    // into a nebula.
    static let surface = Color.white.opacity(0.035)
    static let surfaceRaised = Color.white.opacity(0.06)
    static let surfacePressed = Color.white.opacity(0.09)

    // A single hairline. Used sparingly, mostly for inputs and dividers, not
    // around every card.
    static let hairline = Color.white.opacity(0.07)

    // Accent — warm peach. The only chromatic element on the board surface.
    // Reserved for the brand mark, the active focus state, and primary CTAs.
    static let accent = Color(hex: "EF8B6E")
    static let accentMuted = Color(hex: "EF8B6E").opacity(0.18)

    // Text scale — true neutrals, no chromatic tint. Type carries the page;
    // it shouldn't compete with the surface.
    static let textPrimary = Color(hex: "F4F2EF")
    static let textSecondary = Color(hex: "9A9AA0")
    static let textDim = Color(hex: "5C5C62")
    static let textMuted = Color(hex: "3A3A40")

    // Semantic — used only on labels/states that genuinely need to read as
    // good/bad/warning. Never as decoration.
    static let positive = Color(hex: "7EC49B")
    static let negative = Color(hex: "D4746A")
    static let warning = Color(hex: "E8C47A")
}

// MARK: - Card Modifier
// A card is a calm container. Solid translucent fill, one hairline, one soft
// ambient shadow. No gradient borders, no inner washes.

struct CardStyle: ViewModifier {
    var inset: CGFloat = 20
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(inset)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, y: 4)
    }
}

extension View {
    func cardStyle(inset: CGFloat = 20, cornerRadius: CGFloat = 18) -> some View {
        modifier(CardStyle(inset: inset, cornerRadius: cornerRadius))
    }
}

// MARK: - Section Label
// Sentence-cased, semibold, no uppercase tracked novelty. The icon is
// optional and quiet — same color as the label, same weight, smaller size.

struct SectionLabel: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Field Style
// A focused input gets a hairline that brightens to the accent. No glow, no
// outer shadow. The change in border weight + color is enough.

struct CelestialFieldStyle: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isFocused ? Theme.accent.opacity(0.55) : Theme.hairline,
                        lineWidth: isFocused ? 1.25 : 0.5
                    )
            )
            .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

extension View {
    func celestialField(isFocused: Bool = false) -> some View {
        modifier(CelestialFieldStyle(isFocused: isFocused))
    }
}

// MARK: - Starfield (preserved for onboarding hero only)
// Kept available so the onboarding hero can still feel atmospheric. Not used
// on the working board — the work surface stays quiet.

struct StarfieldView: View {
    let starCount: Int
    private let seed: UInt64
    @State private var phase: Double = 0

    init(starCount: Int = 80, seed: UInt64 = 47) {
        self.starCount = starCount
        self.seed = seed
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0)) { timeline in
            GeometryReader { geo in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    var rng = SeededGenerator(seed: seed)
                    for _ in 0..<starCount {
                        let x = Double.random(in: 0...size.width, using: &rng)
                        let y = Double.random(in: 0...size.height, using: &rng)
                        let r = Double.random(in: 0.35...1.1, using: &rng)
                        let alpha = Double.random(in: 0.10...0.32, using: &rng)
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                    }
                    var rng2 = SeededGenerator(seed: seed &+ 1)
                    let twinkleCount = max(8, starCount / 8)
                    for i in 0..<twinkleCount {
                        let x = Double.random(in: 0...size.width, using: &rng2)
                        let y = Double.random(in: 0...size.height, using: &rng2)
                        let r = Double.random(in: 0.7...1.7, using: &rng2)
                        let baseAlpha = Double.random(in: 0.20...0.55, using: &rng2)
                        let speed = Double.random(in: 0.6...1.4, using: &rng2)
                        let offset = Double(i) * 0.7
                        let breath = (sin(now * speed + offset) + 1) / 2
                        let alpha = baseAlpha * (0.4 + breath * 0.6)
                        let glowRect = CGRect(x: x - r * 2.5, y: y - r * 2.5, width: r * 5, height: r * 5)
                        context.fill(Path(ellipseIn: glowRect), with: .color(.white.opacity(alpha * 0.18)))
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed != 0 ? seed : 0xdeadbeef }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
