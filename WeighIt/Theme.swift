import SwiftUI

// MARK: - Theme — "The Night Sky As A Place"
//
// 2026-09-02: the flat near-black ground read as a rectangle with dots, not a
// sky — bar_audit G1 (dark AND desaturated) failed on every screen. The fix
// isn't a filter, it's a WORLD: a deep saturated indigo-blue ground that
// warms toward a horizon glow at the bottom, a Milky Way band, stars in three
// sizes, and a treeline so the sky sits on land. Chroma lives in the ground
// (a large, low-frequency field — halation-safe); text stays a restrained
// cream so nothing shimmers at small sizes (dark_mode_chroma_in_fields).
//
//   1. Ground carries the world (fleet-loop research: chrome load kills a
//      screen faster than any single component choice).
//   2. Chroma in the FIELD, restraint in the GLYPHS.
//   3. One accent, ember orange, used for the one thing on each screen.
//   4. No glow filters — a hand-drawn poster, not a bloom.

enum Theme {
    // Ground — deep saturated indigo-blue, matching the sky's zenith tone.
    // Used for flat chrome (toolbar tint, sticky headers) so it reads as one
    // continuous world rather than a patchwork of leftover neutrals.
    static let bg = Color(hex: "10163E")
    static let bgElevated = Color(hex: "1B2150")

    // Card surfaces — translucent white over the indigo ground, so cards
    // read as a lighter, cooler indigo rather than a separate material.
    static let surface = Color.white.opacity(0.10)
    static let surfaceRaised = Color.white.opacity(0.14)
    static let surfacePressed = Color.white.opacity(0.18)

    static let hairline = Color.white.opacity(0.14)
    // The lit top edge of a card — light from the sky above, not a glow.
    static let cardTopEdge = Color.white.opacity(0.38)

    // Brand accent — saturated coral.
    static let accent = Color(hex: "FF6B47")
    static let accentMuted = Color(hex: "FF6B47").opacity(0.18)

    // Secondary — vivid indigo for thought / depth.
    static let accentSecondary = Color(hex: "818CF8")

    // Text — lifted for higher contrast against the deeper ground.
    // textPrimary brighter, textSecondary brighter, textDim lifted out
    // of the read-as-disabled zone.
    static let textPrimary = Color(hex: "FFFCF7")
    static let textSecondary = Color(hex: "C9BEB2")
    static let textDim = Color(hex: "847A6E")
    static let textMuted = Color(hex: "5A5048")

    // Semantic.
    static let positive = Color(hex: "34D399")
    static let negative = Color(hex: "F87171")
    static let warning = Color(hex: "FBBF24")

    // MARK: - The Night Sky
    // Ground gradient: deep indigo-blue zenith, warming through a low-chroma
    // dusk band, to an ember horizon glow — the light from somewhere. The
    // path deliberately dips saturation around 341° before ramping the
    // ember hue so the transition never sustains a violet band.
    static let skyGroundStops: [Gradient.Stop] = [
        .init(color: Color(hex: "04063F"), location: 0.0),
        .init(color: Color(hex: "0A18A0"), location: 0.35),
        .init(color: Color(hex: "221A74"), location: 0.60),
        .init(color: Color(hex: "5C2032"), location: 0.80),
        .init(color: Color(hex: "C24C0A"), location: 1.0),
    ]

    static let starWarm = Color(hex: "FFD9A8")
    static let starCool = Color(hex: "AFCBFF")
    static let ridge = Color(hex: "070912")
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
                // Lit top edge — light from the sky above the card, not a glow.
                // Brighter at the top, settling to the ordinary hairline below.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Theme.cardTopEdge, Theme.hairline],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 0.75
                    )
            )
            // One ambient shadow — neutral near-black, no chromatic bloom.
            // Per impeccable.style #14, colored box-shadow glows on dark are
            // the signature cyberpunk/AI-slop tell.
            .shadow(color: Color.black.opacity(0.40), radius: 12, y: 4)
    }
}

extension View {
    func cardStyle(inset: CGFloat = 20, cornerRadius: CGFloat = 18) -> some View {
        modifier(CardStyle(inset: inset, cornerRadius: cornerRadius))
    }
}

// MARK: - Primary CTA Glow (no-op)
// Kept as a no-op stub so existing call sites still compile. The actual
// glow has been removed — colored box-shadow glows on dark surfaces are
// listed by impeccable.style as anti-pattern #14 ("dark mode with glowing
// accents", the cyberpunk AI tell). Hierarchy comes from solid color +
// type weight, not from radiating light.

extension View {
    func primaryCTAGlow(strength: Double = 0.40, radius: CGFloat = 14) -> some View {
        self
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
                        isFocused ? Theme.accent : Theme.hairline,
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

// MARK: - Drawn Star (onboarding hero)
// A crisp vector star standing in for the SF Symbol + Gaussian-blur glow
// combo, which reads as the "neon on near-black" tell (impeccable.style
// #14 — colored glow blobs on dark grounds). This is a flat-filled shape
// with one directional shading pass (light from upper right, so the
// lower-left facet reads slightly darker) and a thin, unblurred halo ring
// at low opacity — the hand-made poster look, not a bloom.

struct StarShape: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio
        var path = Path()
        let step = Double.pi / Double(points)
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = Double(i) * step - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct DrawnStar: View {
    var color: Color
    var size: CGFloat = 64
    var haloSize: CGFloat = 108
    var pulse: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.42), lineWidth: 2.5)
                .frame(width: haloSize, height: haloSize)

            StarShape()
                .fill(color)
                .overlay(
                    // Shadow facet, lower-left.
                    StarShape()
                        .fill(LinearGradient(colors: [Color.black.opacity(0.32), .clear],
                                              startPoint: .bottomLeading, endPoint: .center))
                        .blendMode(.multiply)
                )
                .overlay(
                    // Highlight facet, upper-right — the implied light source.
                    StarShape()
                        .fill(LinearGradient(colors: [Color.white.opacity(0.24), .clear],
                                              startPoint: .topTrailing, endPoint: .center))
                        .blendMode(.screen)
                )
                .compositingGroup()
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.45), radius: 7, y: 2)
                .scaleEffect(pulse ? 1.05 : 1)
        }
    }
}

// MARK: - The Sky
//
// One background for every screen: a saturated indigo-blue ground, a Milky
// Way band (a soft cloud of many tiny points, not a blur), and stars in
// three sizes with a warm/cool mix. Drawn once per appearance — no
// TimelineView — so it costs nothing on a screen that scrolls (BoardView) or
// rebuilds on every keystroke (the matrix). `treeline` adds a thin dark
// ridge silhouette along the bottom edge so the sky sits on land; use it on
// screens that read as "a place" (home, calibration) and leave it off where
// a sheet or modal is transient (onboarding, example picker, AI seed).

struct SkyBackground: View {
    var seed: UInt64 = 1
    var treeline: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: Theme.skyGroundStops),
                           startPoint: .top, endPoint: .bottom)

            SkyFieldView(seed: seed)

            if treeline {
                VStack(spacing: 0) {
                    Spacer()
                    RidgelineShape(seed: seed &+ 900)
                        .fill(Theme.ridge)
                        .frame(height: 56)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// The Milky Way band + the ambient starfield, drawn in one Canvas pass.
private struct SkyFieldView: View {
    let seed: UInt64

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawMilkyWay(&context, size: size)
                drawStars(&context, size: size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// A diagonal band of many tiny, low-alpha points — dense near its
    /// centerline, thinning toward the edges (three summed uniforms stand
    /// in for a Gaussian without pulling in extra machinery). Kept out of
    /// the bottom quarter so it never muddies the horizon glow.
    private func drawMilkyWay(_ context: inout GraphicsContext, size: CGSize) {
        var rng = SeededGenerator(seed: seed &+ 500)
        // Endpoints chosen just outside the frame so the sampled segment
        // (not a length*angle projection that mostly misses the screen)
        // maps almost entirely onto visible pixels.
        let a = CGPoint(x: size.width * -0.15, y: size.height * 0.02)
        let b = CGPoint(x: size.width * 1.15, y: size.height * 0.60)
        let dx = b.x - a.x, dy = b.y - a.y
        let segLength = max(1, (dx * dx + dy * dy).squareRoot())
        let dir = CGVector(dx: dx / segLength, dy: dy / segLength)
        let perp = CGVector(dx: -dir.dy, dy: dir.dx)
        let bandWidth = size.width * 0.24
        let ceiling = size.height * 0.76
        let count = 2600

        for _ in 0..<count {
            let along = Double.random(in: 0...segLength, using: &rng)
            // Two summed uniforms (not one) so the band keeps a visible,
            // brighter core rather than a uniform-density strip.
            let g = (Double.random(in: -1...1, using: &rng)
                     + Double.random(in: -1...1, using: &rng)) / 2
            let perpOffset = g * bandWidth
            let x = a.x + dir.dx * along + perp.dx * perpOffset
            let y = a.y + dir.dy * along + perp.dy * perpOffset
            guard x > -4, x < size.width + 4, y > -4, y < ceiling else { continue }
            // Denser near the centerline reads brighter there, same as a
            // real Milky Way core — falloff comes from |g|, not just alpha jitter.
            let core = max(0, 1 - abs(g))
            let r = Double.random(in: 0.35...0.8, using: &rng)
            let alpha = (0.07 + core * 0.24) * Double.random(in: 0.65...1.0, using: &rng)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(Color(hex: "E8E2FF").opacity(alpha)))
        }
    }

    /// Three size tiers: many tiny points, fewer mid stars, a handful of
    /// large ones — mostly white with a deliberate warm/cool minority so
    /// the sky reads as varied light, not a uniform dot grid.
    private func drawStars(_ context: inout GraphicsContext, size: CGSize) {
        var rng = SeededGenerator(seed: seed)

        func starColor(_ r: inout SeededGenerator) -> Color {
            let roll = Double.random(in: 0...1, using: &r)
            if roll < 0.72 { return .white }
            return roll < 0.86 ? Theme.starWarm : Theme.starCool
        }

        // Tier 1 — small, majority.
        for _ in 0..<170 {
            let x = Double.random(in: 0...size.width, using: &rng)
            let y = Double.random(in: 0...size.height * 0.88, using: &rng)
            let r = Double.random(in: 0.4...0.8, using: &rng)
            let alpha = Double.random(in: 0.28...0.55, using: &rng)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(starColor(&rng).opacity(alpha)))
        }
        // Tier 2 — medium, fewer.
        for _ in 0..<38 {
            let x = Double.random(in: 0...size.width, using: &rng)
            let y = Double.random(in: 0...size.height * 0.85, using: &rng)
            let r = Double.random(in: 1.0...1.5, using: &rng)
            let alpha = Double.random(in: 0.45...0.72, using: &rng)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(starColor(&rng).opacity(alpha)))
        }
        // Tier 3 — large, rare. A thin unblurred halo ring, not a glow.
        for _ in 0..<9 {
            let x = Double.random(in: 0...size.width, using: &rng)
            let y = Double.random(in: 0...size.height * 0.6, using: &rng)
            let r = Double.random(in: 1.6...2.2, using: &rng)
            let color = starColor(&rng)
            let alpha = Double.random(in: 0.7...0.95, using: &rng)
            let haloRect = CGRect(x: x - r * 2.4, y: y - r * 2.4, width: r * 4.8, height: r * 4.8)
            context.stroke(Path(ellipseIn: haloRect), with: .color(color.opacity(alpha * 0.35)), lineWidth: 0.6)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha)))
        }
    }
}

/// A thin, jagged ridge silhouette so the sky sits on land — deliberately
/// irregular (varying peak heights), never a smooth wave.
private struct RidgelineShape: Shape {
    let seed: UInt64

    func path(in rect: CGRect) -> Path {
        var rng = SeededGenerator(seed: seed)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        let segments = 14
        for i in 0...segments {
            let x = rect.width * CGFloat(i) / CGFloat(segments)
            let y = rect.maxY - CGFloat.random(in: 4...(rect.height * 0.92), using: &rng)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        path.closeSubpath()
        return path
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
