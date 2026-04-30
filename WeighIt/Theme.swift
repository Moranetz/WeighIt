import SwiftUI

// MARK: - Theme — "Vivid Twilight"
//
// The previous near-black ground was reading as cold and lifeless. Engagement
// research (Mehta & Zhu 2009; Pickering 2020; the Duolingo / Headspace /
// Spotify / Linear playbooks) all converge on the same recipe for "alive but
// not chaotic" interfaces:
//
//   1. Warm-tinted dark, not pure black. Pure #000 makes the brain read
//      the surface as void; warm grays make it read as material.
//   2. One bright, fully-saturated brand color used confidently.
//   3. A second contrasting hue for "thinking" or secondary punctuation.
//   4. A semantic palette that's bright enough to pop — emerald, cherry,
//      mustard — not muted neutrals.
//   5. Multi-hue identity colors so each piece of content has its own
//      pattern-recognition anchor.

enum Theme {
    // Ground — warm chocolate-tinted dark. Reads as a surface, not a hole.
    static let bg = Color(hex: "1A1410")
    static let bgElevated = Color(hex: "241C16")

    // Card surfaces — slightly stronger than the previous restraint pass so
    // they have presence. Warm white over warm dark gives a subtle peach cast.
    static let surface = Color.white.opacity(0.05)
    static let surfaceRaised = Color.white.opacity(0.08)
    static let surfacePressed = Color.white.opacity(0.12)

    static let hairline = Color.white.opacity(0.10)

    // Brand accent — confident saturated coral. Brighter and more luminous
    // than the previous dim peach so it actually carries energy.
    static let accent = Color(hex: "FF6B47")
    static let accentMuted = Color(hex: "FF6B47").opacity(0.18)

    // Secondary accent — vivid indigo. Used for "thought" cues (priors,
    // posteriors, depth) so it never competes with the brand for primary CTAs.
    static let accentSecondary = Color(hex: "818CF8")

    // Text — warm cream whites, never neutral gray. The warm cast keeps the
    // surface feeling like material, not a screen.
    static let textPrimary = Color(hex: "F9F3EC")
    static let textSecondary = Color(hex: "BCB0A4")
    static let textDim = Color(hex: "7A7269")
    static let textMuted = Color(hex: "4D4640")

    // Semantic — bright and saturated. These read as "good / bad / careful"
    // at a glance, before a single word is parsed.
    static let positive = Color(hex: "34D399")  // bright emerald
    static let negative = Color(hex: "F87171")  // bright cherry
    static let warning = Color(hex: "FBBF24")   // saturated mustard
}

// MARK: - Card Modifier

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
            .shadow(color: Color.black.opacity(0.30), radius: 14, y: 5)
    }
}

extension View {
    func cardStyle(inset: CGFloat = 20, cornerRadius: CGFloat = 18) -> some View {
        modifier(CardStyle(inset: inset, cornerRadius: cornerRadius))
    }
}

// MARK: - Section Label

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

struct CelestialFieldStyle: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isFocused ? Theme.accent.opacity(0.7) : Theme.hairline,
                        lineWidth: isFocused ? 1.5 : 0.5
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

// MARK: - Starfield (kept for onboarding hero)

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
