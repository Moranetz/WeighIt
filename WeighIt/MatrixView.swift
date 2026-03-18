import SwiftUI

// MARK: - Matrix Grid

struct MatrixGridView: View {
    let board: Board
    @Binding var selectedCell: CellKey?
    @Binding var ratingPopoverCell: CellKey?
    let onRate: (UUID, UUID, Rating?) -> Void

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
                        .frame(width: 150, height: 60, alignment: .leading)
                        .padding(.leading, 14)
                        .background(Color(hex: "161416"))
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(Theme.border).frame(width: 1)
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Theme.borderLight).frame(height: 1)
                        }

                    ForEach(board.sortedHypotheses) { hyp in
                        VStack(spacing: 5) {
                            Circle()
                                .fill(hyp.color)
                                .frame(width: 10, height: 10)
                                .shadow(color: hyp.color.opacity(0.5), radius: 4)
                            Text(hyp.name.isEmpty ? "Expl. \(board.sortedHypotheses.firstIndex(where: { $0.id == hyp.id })! + 1)" : hyp.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            if hyp.isRuledOut {
                                Text("RULED OUT")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Theme.negative)
                            }
                        }
                        .frame(width: 110, height: 60)
                        .background(Color(hex: "161416"))
                        .opacity(hyp.isRuledOut ? 0.35 : 1)
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

// MARK: - Matrix Cell

struct MatrixCellView: View {
    let rating: Rating?
    let hasNote: Bool
    let isDimmed: Bool
    let isSelected: Bool
    @State private var justSet = false

    var body: some View {
        ZStack {
            // Background
            if let r = rating, !isDimmed {
                r.bgColor
                    .shadow(.inner(color: r.color.opacity(0.15), radius: 10))
            } else {
                Color.white.opacity(isDimmed ? 0.01 : 0.015)
            }

            // Content
            if isDimmed {
                Color.clear
            } else if let r = rating {
                VStack(spacing: 3) {
                    Text(r.emoji)
                        .font(.title3)
                        .scaleEffect(justSet ? 1.2 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: justSet)
                    Text(r.shortLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(r.color)
                }
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Theme.textMuted)
            }

            // Note indicator
            if hasNote && !isDimmed {
                VStack {
                    HStack {
                        Spacer()
                        Text("📝")
                            .font(.system(size: 8))
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { justSet = false }
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
                        Text(r.emoji)
                            .font(.title3)
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
                    Text("📝")
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
