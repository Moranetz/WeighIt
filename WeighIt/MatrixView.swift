import SwiftUI

// MARK: - Matrix Grid

struct MatrixGridView: View {
    let board: Board
    @Binding var selectedCell: CellKey?
    @Binding var ratingPopoverCell: CellKey?
    let onRate: (UUID, UUID, Rating?) -> Void
    @AppStorage("strictBayesMode") private var strictBayesMode = false

    private func hypothesisTitle(for hypothesis: Hypothesis) -> String {
        guard !hypothesis.name.isEmpty else {
            let index = board.sortedHypotheses.firstIndex(where: { $0.id == hypothesis.id }) ?? 0
            return "Expl. \(index + 1)"
        }
        return hypothesis.name
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    // Corner cell
                    Text("EVIDENCE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.textDim)
                        .frame(width: 150, height: 70, alignment: .leading)
                        .padding(.leading, 14)
                        .background(Color(hex: "161416"))
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(Theme.border).frame(width: 1)
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Theme.borderLight).frame(height: 1)
                        }

                    ForEach(board.sortedHypotheses) { hyp in
                        let stability = board.stability(for: hyp)
                        let refutations = board.refutationCount(for: hyp)
                        let supports = board.supportCount(for: hyp)
                        let biasWarning = board.monotonicBias(for: hyp)
                        let posterior = board.bayesianPosterior(for: hyp)
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                // Star — sized & glow proportional to stability (steadiness under
                                // observation), not raw support. A star nothing has dimmed shines
                                // brightest. Refutation pressure dims the glow.
                                Image(systemName: stability > 0.85 ? "star.fill" : "star")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(hyp.color)
                                    .shadow(color: hyp.color.opacity(stability * 0.9), radius: stability * 5)
                                    .opacity(0.4 + (stability * 0.6))
                                Text(hypothesisTitle(for: hyp))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                // In strict Bayes mode, badge shows posterior probability.
                                // In refutation-first mode, badge shows refutation count.
                                if strictBayesMode {
                                    Text("\(Int(posterior * 100))%")
                                        .font(.system(size: 9, weight: .heavy))
                                        .fontDesign(.rounded)
                                        .foregroundStyle(hyp.color)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1.5)
                                        .background(hyp.color.opacity(0.18), in: Capsule())
                                        .overlay(Capsule().strokeBorder(hyp.color.opacity(0.4), lineWidth: 0.75))
                                        .accessibilityLabel("Bayesian posterior \(Int(posterior * 100)) percent")
                                } else if refutations > 0 {
                                    Text("\(refutations)")
                                        .font(.system(size: 9, weight: .heavy))
                                        .fontDesign(.rounded)
                                        .foregroundStyle(Color(hex: "F0EBE6"))
                                        .frame(width: 14, height: 14)
                                        .background(Color(hex: "D4746A"), in: Circle())
                                        .overlay(Circle().strokeBorder(Color(hex: "D4746A").opacity(0.3), lineWidth: 2).blur(radius: 2))
                                        .accessibilityLabel("\(refutations) refutations")
                                }
                            }
                            .padding(.horizontal, 6)

                            // In Bayes mode, the bar visualizes posterior as a probability fill.
                            // In refutation-first, it shows support count.
                            if strictBayesMode {
                                PosteriorBar(probability: posterior, color: hyp.color)
                                    .frame(height: 3)
                                    .padding(.horizontal, 8)
                            } else {
                                SupportBar(supports: supports, totalCells: board.activeHypotheses.isEmpty ? 1 : board.evidences.count, color: hyp.color)
                                    .frame(height: 3)
                                    .padding(.horizontal, 8)
                            }

                            // Pareidolia Alert — appears AS users rate. Names the bias they're
                            // fighting (seeing patterns in stars that aren't actually constellations).
                            if let warning = biasWarning {
                                HStack(spacing: 3) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 7))
                                    Text("Pareidolia: \(warning)")
                                        .font(.system(size: 8.5, weight: .semibold))
                                }
                                .foregroundStyle(Theme.warning)
                                .lineLimit(1)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Theme.warning.opacity(0.12), in: Capsule())
                                .overlay(Capsule().strokeBorder(Theme.warning.opacity(0.25), lineWidth: 0.5))
                                .padding(.horizontal, 4)
                                .transition(.scale.combined(with: .opacity))
                            } else if hyp.isRuledOut {
                                Text("RULED OUT")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Theme.negative)
                            }
                        }
                        .frame(width: 110, height: 72)
                        .background(Color(hex: "161416"))
                        .opacity(hyp.isRuledOut ? 0.35 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: stability)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: refutations)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: biasWarning)
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(Theme.border).frame(width: 1)
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Theme.borderLight).frame(height: 1)
                        }
                    }
                }

                // Data rows
                ForEach(board.sortedEvidence) { ev in
                    let evIndex = board.sortedEvidence.firstIndex(where: { $0.id == ev.id }) ?? 0
                    HStack(spacing: 0) {
                        // Evidence label
                        Text(ev.text.isEmpty ? "Evidence \(evIndex + 1)" : ev.text)
                            .font(.system(size: 13))
                            .foregroundStyle(ev.text.isEmpty ? Theme.textMuted : Theme.textSecondary)
                            .lineLimit(2)
                            .frame(width: 150, alignment: .leading)
                            .padding(.leading, 14)
                            .padding(.vertical, 8)
                            .frame(minHeight: 66)
                            .background(Theme.bg.opacity(0.5))
                            .overlay(alignment: .trailing) {
                                Rectangle().fill(Theme.border).frame(width: 1)
                            }
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(Theme.border).frame(height: 1)
                            }

                        ForEach(board.sortedHypotheses) { hyp in
                            let cellKey = CellKey(evidenceID: ev.id, hypothesisID: hyp.id)
                            let rating = board.rating(evidenceID: ev.id, hypothesisID: hyp.id)
                            let hasNote = !board.note(evidenceID: ev.id, hypothesisID: hyp.id).isEmpty

                            MatrixCellView(
                                rating: rating,
                                hasNote: hasNote,
                                isDimmed: hyp.isRuledOut,
                                isSelected: selectedCell == cellKey,
                                starColor: hyp.color
                            )
                            .frame(width: 110, height: 66)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !hyp.isRuledOut {
                                    ratingPopoverCell = cellKey
                                }
                            }
                            .popover(isPresented: Binding(
                                get: { ratingPopoverCell == cellKey },
                                set: { if !$0 { ratingPopoverCell = nil } }
                            )) {
                                RatingPickerView(
                                    currentRating: rating,
                                    onPick: { r in
                                        onRate(ev.id, hyp.id, r)
                                        ratingPopoverCell = nil
                                    },
                                    onNote: {
                                        selectedCell = cellKey
                                        ratingPopoverCell = nil
                                    },
                                    onClear: {
                                        onRate(ev.id, hyp.id, nil)
                                        ratingPopoverCell = nil
                                    }
                                )
                                .presentationCompactAdaptation(.popover)
                            }
                            .overlay(alignment: .trailing) {
                                Rectangle().fill(Theme.border).frame(width: 1)
                            }
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(Theme.border).frame(height: 1)
                            }
                        }
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Posterior Bar
// Strict-Bayes-mode column header bar. Visualizes posterior probability (0...1) as
// a left-anchored fill — full width = 100% certainty for this hypothesis. Differs
// from SupportBar in that it represents an actual probability, not just a count.

struct PosteriorBar: View {
    let probability: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.border.opacity(0.6))
                Capsule()
                    .fill(LinearGradient(
                        colors: [color.opacity(0.6), color],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(2, geo.size.width * CGFloat(probability)))
                    .shadow(color: color.opacity(0.5), radius: 3)
            }
        }
    }
}

// MARK: - Support Bar
// Uni-directional bar showing only support count for a hypothesis column. Refutation
// pressure is shown SEPARATELY as a red badge — keeping the two signals visually distinct
// is the whole point: users learn that "lots of support" and "no refutation" are different
// things, and what really matters in ACH is the absence of refutation.

struct SupportBar: View {
    let supports: Int        // count of supporting cells
    let totalCells: Int      // total possible (number of evidence rows)
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.border.opacity(0.6))
                if supports > 0 && totalCells > 0 {
                    let pct = min(1.0, Double(supports) / Double(totalCells))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(pct))
                        .shadow(color: color.opacity(0.4), radius: 3)
                }
            }
        }
    }
}

// MARK: - Matrix Cell

struct MatrixCellView: View {
    let rating: Rating?
    let hasNote: Bool
    let isDimmed: Bool
    let isSelected: Bool
    let starColor: Color
    @State private var justSet = false
    @State private var emptyPulse = false
    private let ratingPulseDuration: Duration = .milliseconds(400)

    /// Sightline opacity by rating strength. A strong supporting observation casts
    /// a brighter line up to the star; a contradicting one casts a dimmer one.
    /// Irrelevant ratings get no line — they don't draw your eye toward the star.
    private var sightlineOpacity: Double {
        guard let r = rating else { return 0 }
        switch r {
        case .stronglySupports: return 0.55
        case .supports: return 0.32
        case .irrelevant: return 0.05
        case .contradicts: return 0.20
        case .stronglyContradicts: return 0.32
        }
    }

    /// Rated cells emit a sightline pointing upward toward their column's star.
    /// Supporting ratings get the star's color (bright). Contradicting ratings get
    /// red (negative pull). The visual effect: looking up a column you see a chain
    /// of beams converging on the star header.
    private var sightlineColor: Color {
        guard let r = rating else { return .clear }
        switch r {
        case .stronglySupports, .supports: return starColor
        case .stronglyContradicts, .contradicts: return Color(hex: "D4746A")
        case .irrelevant: return Theme.textMuted
        }
    }

    var body: some View {
        ZStack {
            // Sightline beam — a thin vertical line through the cell pointing toward
            // the column header star. Layered behind everything so it reads as a
            // background atmospheric glow, not foreground UI.
            if rating != nil && !isDimmed && sightlineOpacity > 0.05 {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [
                            sightlineColor.opacity(sightlineOpacity * 0.4),
                            sightlineColor.opacity(sightlineOpacity)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(width: 2)
                    .blur(radius: 1.5)
            }

            // Background
            if let r = rating, !isDimmed {
                Rectangle()
                    .fill(r.bgColor.shadow(.inner(color: r.color.opacity(0.15), radius: 10)))
            } else if !isDimmed {
                // Empty cell: visibly incomplete. The whole point of the app is structured
                // comparison — so unrated cells show a dashed border + slow pulsing dot
                // instead of a passive "+". The user can't visually skip what isn't done.
                ZStack {
                    Color.white.opacity(0.012)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(
                            Theme.textMuted.opacity(0.3),
                            style: StrokeStyle(lineWidth: 0.75, dash: [3, 3])
                        )
                        .padding(8)
                }
            } else {
                Color.white.opacity(0.01)
            }

            // Content
            if isDimmed {
                Color.clear
            } else if let r = rating {
                VStack(spacing: 3) {
                    Image(systemName: r.iconName)
                        .font(.title3)
                        .foregroundStyle(r.color)
                        .scaleEffect(justSet ? 1.2 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: justSet)
                    Text(r.shortLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(r.color)
                }
            } else {
                // Pulsing dot marks the cell as a missing comparison.
                Circle()
                    .fill(Theme.textMuted.opacity(emptyPulse ? 0.55 : 0.25))
                    .frame(width: 6, height: 6)
                    .scaleEffect(emptyPulse ? 1.15 : 0.85)
                    .animation(
                        .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                        value: emptyPulse
                    )
                    .onAppear { emptyPulse = true }
            }

            // Note indicator
            if hasNote && !isDimmed {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "note.text")
                            .font(.system(size: 8))
                            .foregroundStyle(Theme.textDim)
                            .padding(3)
                    }
                    Spacer()
                }
            }
        }
        .opacity(isDimmed ? 0.25 : 1)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Theme.accent, lineWidth: 2)
            }
        }
        .onChange(of: rating) { _, _ in
            justSet = true
            Task {
                try? await Task.sleep(for: ratingPulseDuration)
                await MainActor.run {
                    justSet = false
                }
            }
        }
    }
}

// MARK: - Rating Picker

struct RatingPickerView: View {
    let currentRating: Rating?
    let onPick: (Rating) -> Void
    let onNote: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Rating.allCases) { r in
                let isActive = currentRating == r
                Button {
                    onPick(r)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: r.iconName)
                            .font(.title3)
                            .foregroundStyle(r.color)
                            .frame(width: 28)
                        Text(r.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(r.color)
                        Spacer()
                        if isActive {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(r.color)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isActive ? r.bgColor : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isActive ? r.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.horizontal, 8)
                .padding(.vertical, 2)

            if currentRating != nil {
                Button {
                    onClear()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "delete.backward")
                            .foregroundStyle(Theme.textDim)
                            .frame(width: 28)
                        Text("Clear")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }

            Button {
                onNote()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 28)
                    Text("Add note")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .frame(minWidth: 200)
    }
}
