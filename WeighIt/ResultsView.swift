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
            // "Constellation Confirmed" header — the verdict moment. Quietly emphasizes
            // that ranking is by stability (fewest refutations), not popularity.
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel(text: "Constellation confirmed")
                Text("Ranked by what hasn't been knocked down: fewest refutations first, then most support.")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(board.rankedHypotheses.enumerated()), id: \.element.hypothesis.id) { index, item in
                let isFirst = index == 0
                let stability = board.stability(for: item.hypothesis)

                HStack(spacing: 14) {
                    Text("\(index + 1)")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(isFirst ? Theme.accent : Theme.textMuted)
                        .frame(width: 32, alignment: .trailing)
                        .fontDesign(.rounded)

                    // Star — sized + glow proportional to stability, not raw score.
                    Image(systemName: stability > 0.85 ? "star.fill" : "star")
                        .font(.system(size: isFirst ? 18 : 14))
                        .foregroundStyle(item.hypothesis.color)
                        .shadow(color: item.hypothesis.color.opacity(stability * 0.8), radius: stability * (isFirst ? 8 : 5))
                        .opacity(0.4 + stability * 0.6)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.hypothesis.name.isEmpty ? "Star \(index + 1)" : item.hypothesis.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.textPrimary)

                        // Refutation/support summary line — explicit about the two-signal
                        // ranking. Reads like a scoreline so users see the actual ACH math.
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color(hex: "D4746A"))
                                    .frame(width: 5, height: 5)
                                Text("\(item.refutations) refuted")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(item.refutations == 0 ? Theme.positive : Color(hex: "D4746A"))
                            }
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Theme.positive)
                                    .frame(width: 5, height: 5)
                                Text("\(item.supports) supported")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Theme.textDim)
                            }
                        }
                    }

                    Spacer()

                    // Stability percent — the real ACH ranking signal.
                    Text("\(Int(stability * 100))%")
                        .font(.body)
                        .fontWeight(.heavy)
                        .fontDesign(.rounded)
                        .foregroundStyle(isFirst ? Theme.positive : Theme.textDim)
                        .frame(minWidth: 50, alignment: .trailing)
                        .contentTransition(.numericText(value: stability * 100))
                        .animation(.spring(response: 0.4), value: stability)
                }
                .padding(.vertical, 4)

                if index < board.rankedHypotheses.count - 1 {
                    Divider().overlay(Theme.hairline)
                }
            }

            // Ruled out
            if !board.ruledOutHypotheses.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider().overlay(Theme.hairline)
                    HStack(spacing: 4) {
                        Text("Dimmed (ruled out):")
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

            // Tagline at the verdict moment
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("The brightest star isn't always the right one.")
                        .font(.caption)
                        .foregroundStyle(Theme.textPrimary)
                    Text("The one no observation has dimmed is.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .lineSpacing(2)
                }
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
