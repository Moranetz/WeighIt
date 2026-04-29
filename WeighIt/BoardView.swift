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
                ConstellationRevealView(board: board)
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

    @FocusState private var questionFocused: Bool
    @FocusState private var conclusionFocused: Bool

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "The question", icon: "questionmark.circle")
            TextField("e.g. Why are signups dropping?", text: $board.question, axis: .vertical)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.textPrimary)
                .focused($questionFocused)
                .celestialField(isFocused: questionFocused)
        }
        .cardStyle()
    }

    // MARK: - Hypotheses

    private var hypothesesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: "Stars to test", icon: "star")
                    Text("Each candidate explanation. Ranked by what hasn't been knocked down.")
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
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: "Observation log", icon: "binoculars")
                    Text("Each piece of evidence is one observation. Sky × view is your condition.")
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
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: "The star chart", icon: "scope")
                    Text("Each cell is one sightline. Empty cells pulse — unobserved.")
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
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Your verdict", icon: "checkmark.seal")
            Text("Based on the constellation, what do you think?")
                .font(.caption)
                .foregroundStyle(Theme.textDim)
                .italic()
            TextField("Based on the evidence, I believe…", text: $board.conclusion, axis: .vertical)
                .font(.system(.body, design: .rounded))
                .lineLimit(3...8)
                .foregroundStyle(Theme.textPrimary)
                .focused($conclusionFocused)
                .celestialField(isFocused: conclusionFocused)
        }
        .cardStyle()
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

// MARK: - Constellation Reveal
// Replaces the celebratory confetti with a deliberative "verdict settled" moment.
// When the matrix hits 100%, the leading hypothesis (the steadiest star, fewest
// refutations) emerges with a soft glow + lines drawn outward to its supporting
// observations. No particles, no explosion — just quiet pattern recognition.

struct ConstellationRevealView: View {
    let board: Board
    @State private var animateIn = false

    /// The leading hypothesis = the steadiest star = the result of refutation-first
    /// ranking. Whatever ACH rules say is the right answer is what we celebrate here.
    private var leadingHypothesis: Hypothesis? {
        board.rankedHypotheses.first?.hypothesis
    }

    /// Names of supporting observations for the leading star — drawn as connection
    /// labels around the star. These are the cells that confirmed the constellation.
    private var supportingObservations: [String] {
        guard let lead = leadingHypothesis else { return [] }
        return board.evidences.compactMap { ev in
            let r = board.rating(evidenceID: ev.id, hypothesisID: lead.id)
            guard r == .supports || r == .stronglySupports else { return nil }
            return ev.text.isEmpty ? nil : String(ev.text.prefix(40))
        }
    }

    var body: some View {
        ZStack {
            // Dim the background for focus
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // The leading star — pulses softly as the verdict moment lands
                if let lead = leadingHypothesis {
                    ZStack {
                        Circle()
                            .fill(lead.color.opacity(0.18))
                            .frame(width: 220, height: 220)
                            .blur(radius: 36)
                            .scaleEffect(animateIn ? 1.05 : 0.85)
                        Image(systemName: "star.fill")
                            .font(.system(size: 84))
                            .foregroundStyle(lead.color)
                            .shadow(color: lead.color.opacity(0.7), radius: animateIn ? 26 : 8)
                            .scaleEffect(animateIn ? 1.0 : 0.6)
                    }

                    VStack(spacing: 10) {
                        Text("Constellation confirmed")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.textSecondary)
                            .opacity(animateIn ? 1 : 0)

                        Text(lead.name.isEmpty ? "(unnamed star)" : lead.name)
                            .font(.system(size: 28, weight: .heavy))
                            .fontDesign(.rounded)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 6)
                    }
                }

                // Supporting observations — appear as quiet text under the star,
                // each on its own line, like a list of confirming sightlines.
                if !supportingObservations.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(Array(supportingObservations.prefix(4).enumerated()), id: \.offset) { index, obs in
                            Text(obs)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textDim)
                                .multilineTextAlignment(.center)
                                .opacity(animateIn ? 1 : 0)
                                .animation(
                                    .easeOut(duration: 0.5).delay(0.4 + Double(index) * 0.15),
                                    value: animateIn
                                )
                        }
                        if supportingObservations.count > 4 {
                            Text("+ \(supportingObservations.count - 4) more")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textMuted)
                                .opacity(animateIn ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                Text("The brightest star isn't always the right one.\nThe steadiest one is.")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 60)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.9), value: animateIn)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                animateIn = true
            }
        }
    }
}
