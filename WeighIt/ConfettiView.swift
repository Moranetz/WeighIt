import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: p.size > 6 ? 2 : p.size / 2)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .rotationEffect(.degrees(isAnimating ? p.rotation : 0))
                    .offset(
                        x: isAnimating ? p.endX : p.startX,
                        y: isAnimating ? p.endY : p.startY
                    )
                    .opacity(isAnimating ? 0 : 1)
            }
        }
        .onAppear {
            particles = (0..<50).map { _ in ConfettiParticle() }
            withAnimation(.easeOut(duration: 2.0)) {
                isAnimating = true
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let size: CGFloat
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double

    init() {
        let colors: [Color] = [
            Color(hex: "EF8B6E"), Color(hex: "5CC4B8"), Color(hex: "7E9BE0"),
            Color(hex: "E8C47A"), Color(hex: "C490D4"), Color(hex: "6EC4A0"),
            Color(hex: "7EC49B"), Color(hex: "D4746A"),
        ]
        size = CGFloat.random(in: 4...10)
        color = colors.randomElement()!
        startX = CGFloat.random(in: -180...180)
        startY = -50
        endX = startX + CGFloat.random(in: -120...120)
        endY = CGFloat.random(in: 300...800)
        rotation = Double.random(in: 360...1080)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView()
    }
}
