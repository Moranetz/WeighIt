import SwiftUI

struct ResultsView: View {
    let board: Board
    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 14) {

            // Ranking
            rankingCard

            // Diagnostics
            if !board.highDiagnostics.isEmpty || !board.lowDiagnostics.isEmpty {
                diagnosticsCard
            }

            // Bias
            if !board.biasWarnings.isEmpty {
                biasCard
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
        .onDisappear { animateIn = false }
    }

    // MARK: - Ranking

    private var rankingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Which explanation holds up best?")

            ForEach(Array(board.rankedHypotheses.enumerated()), id: \.element.hypothesis.id) { index, item in
                let isFirst = index == 0

                HStack(spacing: 14) {
                    Text("\(index + 1)")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(isFirst ? Theme.accent : Theme.textMuted)
                        .frame(width: 32, alignment: .trailing)
                        .fontDesign(.rounded)

                    Circle()
                        .fill(item.hypothesis.color)
                        .frame(width: 12, height: 12)
                        .shadow(color: item.hypothesis.color.opacity(0.4), radius: 6)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.hypothesis.name.isEmpty ? "Explanation \(index + 1)" : item.hypothesis.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.textPrimary)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.04))
                                    .frame(height: 5)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.score >= 0
                                          ? LinearGradient(colors: [item.hypothesis.color.opacity(0.5), item.hypothesis.color], startPoint: .leading, endPoint: .trailing)
                                          : LinearGradient(colors: [Theme.negative.opacity(0.5), Theme.negative], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: animateIn ? barWidth(score: item.score, maxAbs: board.maxAbsScore, totalWidth: geo.size.width) : 0, height: 5)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateIn)
                            }
                        }
                        .frame(height: 5)
                    }

                    AnimatedScoreText(score: item.score)
                }
                .padding(.vertical, 4)

                if index < board.rankedHypotheses.count - 1 {
                    Divider().overlay(Theme.border)
                }
            }

            // Ruled out
            if !board.ruledOutHypotheses.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider().overlay(Theme.border)
                    HStack(spacing: 4) {
                        Text("Ruled out:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.negative)
                        Text(board.ruledOutHypotheses.map { $0.name.isEmpty ? "Unnamed" : $0.name }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(Theme.negative)
                            .strikethrough()
                    }
                }
                .padding(.top, 4)
            }

            // Tip
            HStack(alignment: .top, spacing: 8) {
                Text("💡")
                Text("The best explanation isn't the one with the most support — it's the one with the fewest contradictions.")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                    .lineSpacing(2)
            }
            .padding(12)
            .background(Theme.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.accent)
                    .frame(width: 3)
            }
        }
        .cardStyle()
    }

    // MARK: - Diagnostics

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Which evidence actually matters?")

            if !board.highDiagnostics.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Helps you decide:", systemImage: "scope")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.positive)

                    ForEach(board.highDiagnostics) { d in
                        Text(d.evidence.text.isEmpty ? "Unnamed" : d.evidence.text)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "A0CFA0"))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.positive.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Theme.positive.opacity(0.18), lineWidth: 1)
                            )
                    }
                }
            }

            if !board.lowDiagnostics.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Doesn't differentiate:", systemImage: "minus.circle")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.warning)

                    ForEach(board.lowDiagnostics) { d in
                        Text(d.evidence.text.isEmpty ? "Unnamed" : d.evidence.text)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "C0A870"))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.warning.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Theme.warning.opacity(0.12), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Bias

    private var biasCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Honest check", systemImage: "eye")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Theme.warning)

            ForEach(board.biasWarnings, id: \.self) { warning in
                Text(warning)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "B0A080"))
                    .lineSpacing(2)
            }
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.warning.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func barWidth(score: Int, maxAbs: Int, totalWidth: CGFloat) -> CGFloat {
        guard maxAbs > 0 else { return totalWidth * 0.04 }
        let pct = CGFloat(abs(score)) / CGFloat(maxAbs)
        return max(totalWidth * pct, totalWidth * 0.04)
    }
}

// MARK: - Animated Score

struct AnimatedScoreText: View {
    let score: Int

    var body: some View {
        Text(score > 0 ? "+\(score)" : "\(score)")
            .font(.body)
            .fontWeight(.heavy)
            .fontDesign(.rounded)
            .foregroundStyle(score > 0 ? Theme.positive : score < 0 ? Theme.negative : Theme.textDim)
            .frame(minWidth: 44, alignment: .trailing)
            .contentTransition(.numericText(value: Double(score)))
            .animation(.spring(response: 0.4), value: score)
    }
}
