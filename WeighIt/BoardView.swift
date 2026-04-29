import SwiftUI
import SwiftData

struct BoardView: View {
    @Bindable var board: Board
    @State private var showResults = false
    @State private var selectedCell: CellKey?
    @State private var ratingPopoverCell: CellKey?
    @State private var showConfetti = false
    @State private var previousFilledCount = 0

    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private let successHaptic = UINotificationFeedbackGenerator()
    private let confettiDisplayDuration: Duration = .seconds(2.5)

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Question
                questionSection

                // Explanations
                hypothesesSection

                // Evidence
                evidenceSection

                // Matrix
                matrixSection

                // Results button + results
                if board.filledCells > 0 {
                    resultsToggle
                }

                if showResults && board.filledCells > 0 {
                    ResultsView(board: board)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    conclusionSection
                }

                // Footer
                footerView
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: board.filledCells) { oldVal, newVal in
            if board.completionPercent == 100 && previousFilledCount < board.totalCells && board.totalCells > 0 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showConfetti = true
                }
                successHaptic.notificationOccurred(.success)
                Task {
                    try? await Task.sleep(for: confettiDisplayDuration)
                    await MainActor.run {
                        showConfetti = false
                    }
                }
            }
            previousFilledCount = newVal
        }
    }

    // MARK: - Question

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "The question")
            TextField("e.g. Why are signups dropping?", text: $board.question, axis: .vertical)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
        }
        .cardStyle()
    }

    // MARK: - Hypotheses

    private var hypothesesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel(text: "Stars to test")
                    Text("Each candidate explanation. Reckon ranks them by what hasn't been knocked down — not by what has the most support.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if board.hypotheses.count < 7 {
                    Button {
                        haptic.impactOccurred()
                        let h = Hypothesis(
                            name: "",
                            colorHex: HypothesisColors.all[board.hypotheses.count % HypothesisColors.all.count],
                            sortOrder: board.hypotheses.count
                        )
                        board.hypotheses.append(h)
                    } label: {
                        Text("+ add")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }

            ForEach(board.sortedHypotheses) { hyp in
                HypothesisRow(
                    hypothesis: hyp,
                    canDelete: board.hypotheses.count > 2,
                    onDelete: {
                        board.cellRatings.removeAll { $0.hypothesisID == hyp.id }
                        board.hypotheses.removeAll { $0.id == hyp.id }
                    }
                )
            }
        }
        .cardStyle()
    }

    // MARK: - Evidence

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel(text: "Observation log")
                    Text("Each piece of evidence is one observation. Credibility × relevance is your viewing condition.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    haptic.impactOccurred()
                    let ev = Evidence(sortOrder: board.evidences.count)
                    board.evidences.append(ev)
                } label: {
                    Text("+ add")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.accent)
                }
            }

            ForEach(board.sortedEvidence) { ev in
                EvidenceRow(
                    evidence: ev,
                    index: board.sortedEvidence.firstIndex(where: { $0.id == ev.id }) ?? 0,
                    canDelete: board.evidences.count > 1,
                    onDelete: {
                        board.cellRatings.removeAll { $0.evidenceID == ev.id }
                        board.evidences.removeAll { $0.id == ev.id }
                    },
                    onMoveUp: {
                        moveEvidence(ev, by: -1)
                    },
                    onMoveDown: {
                        moveEvidence(ev, by: 1)
                    },
                    isFirst: ev.id == board.sortedEvidence.first?.id,
                    isLast: ev.id == board.sortedEvidence.last?.id
                )
            }
        }
        .cardStyle()
    }

    // MARK: - Matrix

    private var matrixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel(text: "The star chart")
                    Text("Each cell is one sightline: this observation against this star. Empty sightlines pulse to remind you they're unobserved.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if board.filledCells > 0 {
                    Text("\(board.filledCells)/\(board.totalCells)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textDim)
                }
            }

            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Rating.allCases) { r in
                        HStack(spacing: 4) {
                            Image(systemName: r.iconName).font(.caption).foregroundStyle(r.color)
                            Text(r.shortLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(r.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(r.bgColor, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            // Matrix grid
            MatrixGridView(
                board: board,
                selectedCell: $selectedCell,
                ratingPopoverCell: $ratingPopoverCell,
                onRate: { evID, hypID, rating in
                    haptic.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        board.setRating(rating, evidenceID: evID, hypothesisID: hypID)
                    }
                }
            )

            // Note panel
            if let cell = selectedCell,
               let ev = board.evidences.first(where: { $0.id == cell.evidenceID }),
               let hyp = board.hypotheses.first(where: { $0.id == cell.hypothesisID }) {
                NotePanel(
                    evidence: ev,
                    hypothesis: hyp,
                    note: board.note(evidenceID: ev.id, hypothesisID: hyp.id),
                    onUpdate: { newNote in
                        board.setNote(newNote, evidenceID: ev.id, hypothesisID: hyp.id)
                    },
                    onClose: { selectedCell = nil }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .cardStyle()
    }

    // MARK: - Results Toggle

    private var resultsToggle: some View {
        Button {
            haptic.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showResults.toggle()
            }
        } label: {
            Text(showResults ? "Hide constellation" : "Confirm the constellation ↓")
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(showResults ? Theme.textDim : Theme.bg)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background {
                    if showResults {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.raised)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Theme.border, lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.accentGradient)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 16, y: 6)
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Conclusion

    private var conclusionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("So, what do you think?")
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(Theme.accent)
            Text("Write your conclusion. Included in exports.")
                .font(.caption)
                .foregroundStyle(Theme.textDim)
            TextField("Based on the evidence, I believe…", text: $board.conclusion, axis: .vertical)
                .font(.body)
                .lineLimit(3...8)
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.15), lineWidth: 1)
                )
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: 6) {
            Text("The brightest star isn't always the right one.\nThe steadiest one is.")
                .font(.caption2)
                .italic()
                .foregroundStyle(Theme.textDim)
                .multilineTextAlignment(.center)
            Text("Based on Analysis of Competing Hypotheses — the technique CIA analysts use to keep wishful thinking out of conclusions.")
                .font(.caption2)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Helpers

    private func moveEvidence(_ ev: Evidence, by offset: Int) {
        var sorted = board.sortedEvidence
        guard let idx = sorted.firstIndex(where: { $0.id == ev.id }) else { return }
        let newIdx = idx + offset
        guard newIdx >= 0, newIdx < sorted.count else { return }
        sorted.swapAt(idx, newIdx)
        for (i, e) in sorted.enumerated() { e.sortOrder = i }
        haptic.impactOccurred()
    }
}
