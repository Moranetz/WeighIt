import SwiftUI

// MARK: - Matrix Grid

struct MatrixGridView: View {
    let board: Board
    @Binding var selectedCell: CellKey?
    @Binding var ratingPopoverCell: CellKey?
    let onRate: (UUID, UUID, Rating?) -> Void

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
                        let normScore = board.normalizedScore(for: hyp)
                        let biasWarning = board.monotonicBias(for: hyp)
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(hyp.color)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: hyp.color.opacity(0.5), radius: 3)
                                Text(hypothesisTitle(for: hyp))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 6)

                            // Score bar — fills/shrinks as ratings accumulate. Reduces the urge
                            // to skip to a separate "results" view by showing the column verdict
                            // visually, in real time.
                            ColumnScoreBar(score: normScore, color: hyp.color)
                                .frame(height: 3)
                                .padding(.horizontal, 8)

                            // Inline bias chip — appears AS users rate, not gated behind a toggle.
                            // The whole point of the app is bias surfacing; it can't hide.
                            if let warning = biasWarning {
                                Text(warning)
                                    .font(.system(size: 8.5, weight: .semibold))
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
                        .frame(width: 110, height: 70)
                        .background(Color(hex: "161416"))
                        .opacity(hyp.isRuledOut ? 0.35 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: normScore)
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
                                isSelected: selectedCell == cellKey
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

// MARK: - Column Score Bar
// Visualizes a hypothesis column's running score (-1...1) as a thin filling bar centered
// on a midline. Pulls the eye to whichever hypothesis is gaining ground as the user rates.
// Drives the "you couldn't avoid comparing" feel — the column is alive, not static.

struct ColumnScoreBar: View {
    let score: Double?       // -1 ... 1, or nil for "no signal yet"
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .fill(Theme.border.opacity(0.6))
                if let s = score, abs(s) > 0.01 {
                    let halfWidth = geo.size.width / 2
                    let fillWidth = halfWidth * abs(s)
                    let fillColor: Color = s > 0
                        ? Color(hex: "7EC49B")            // positive score = green
                        : Color(hex: "D4746A")            // negative score = red
                    Capsule()
                        .fill(fillColor)
                        .frame(width: fillWidth)
                        .offset(x: s > 0 ? fillWidth / 2 : -fillWidth / 2)
                        .shadow(color: fillColor.opacity(0.4), radius: 3)
                }
                // midline tick — anchor for the bar
                Rectangle()
                    .fill(color.opacity(score == nil ? 0.5 : 0.7))
                    .frame(width: 1.5, height: 5)
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
    @State private var justSet = false
    @State private var emptyPulse = false
    private let ratingPulseDuration: Duration = .milliseconds(400)

    var body: some View {
        ZStack {
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
