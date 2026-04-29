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
// Cards in Reckon have to RESPECT the starfield. The old style was nearly opaque —
// every card was a black rectangle that buried the night sky. The new style is a
// soft, very-translucent glass with a subtle inner gradient and an accent-tinted
// border. Cards feel like "light lifted slightly off the sky," not blocks pasted on top.

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(22)
            .background {
                ZStack {
                    // Glass layer — very thin, lets the starfield shimmer through.
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.55))

                    // Subtle vertical gradient — slightly darker at the top, like a
                    // cloud lit from below. Adds dimension without opacity.
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(0.015),
                                Color.white.opacity(0.045),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))

                    // A soft warm glint along the top edge — light catching on a
                    // distant lens. Anchors the celestial mood.
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Theme.accent.opacity(0.18),
                                    Color.white.opacity(0.04),
                                    Theme.accent.opacity(0.04),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.18), radius: 14, y: 4)
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Section Label
// Reckon's section labels read like chapter titles in an observatory log book:
// uppercase, tracked, soft, with a tiny star glyph that suggests "this is part of
// the sky chart." Optional icon parameter overrides the default star.

struct SectionLabel: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon ?? "sparkle")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.accent.opacity(0.85))
            Text(text.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.6)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Field Style
// A focused field that glows softly when active — like a telescope tracking. Used
// for the question + conclusion text fields so they feel like part of the
// observatory, not generic iOS inputs.

struct CelestialFieldStyle: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isFocused ? Theme.accent.opacity(0.6) : Theme.border,
                                lineWidth: isFocused ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: isFocused ? Theme.accent.opacity(0.25) : .clear,
                        radius: isFocused ? 12 : 0
                    )
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isFocused)
    }
}

extension View {
    func celestialField(isFocused: Bool = false) -> some View {
        modifier(CelestialFieldStyle(isFocused: isFocused))
    }
}

// MARK: - Starfield
// Layered backdrop with subtle twinkle. Stars at three "depths" — a still distant layer,
// a slowly twinkling middle layer, and a few bright "named" stars. Stable seed so the
// pattern is consistent across launches; only the alpha breathes.

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
                    // Distant dust — most stars, no twinkle, just there.
                    for _ in 0..<starCount {
                        let x = Double.random(in: 0...size.width, using: &rng)
                        let y = Double.random(in: 0...size.height, using: &rng)
                        let r = Double.random(in: 0.35...1.1, using: &rng)
                        let alpha = Double.random(in: 0.10...0.32, using: &rng)
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                    }
                    // Twinkling layer — fewer, brighter, with slow alpha breathing.
                    var rng2 = SeededGenerator(seed: seed &+ 1)
                    let twinkleCount = max(8, starCount / 8)
                    for i in 0..<twinkleCount {
                        let x = Double.random(in: 0...size.width, using: &rng2)
                        let y = Double.random(in: 0...size.height, using: &rng2)
                        let r = Double.random(in: 0.7...1.7, using: &rng2)
                        let baseAlpha = Double.random(in: 0.20...0.55, using: &rng2)
                        let speed = Double.random(in: 0.6...1.4, using: &rng2)
                        let offset = Double(i) * 0.7
                        let breath = (sin(now * speed + offset) + 1) / 2  // 0...1
                        let alpha = baseAlpha * (0.4 + breath * 0.6)
                        // Soft glow — fill with a slightly larger blurred ellipse first
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
        // SplitMix64 — fast, stable, good distribution
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
