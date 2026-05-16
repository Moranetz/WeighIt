import SwiftUI
import SwiftData

struct BoardView: View {
    @Bindable var board: Board
    @State private var showResults = false
    @State private var selectedCell: CellKey?
    @State private var ratingPopoverCell: CellKey?

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false

    /// True if this board is the bare-bones first-time tutorial. Detected by
    /// the question text since we don't have a flag on Board (avoiding a schema
    /// migration just for this). The coachmark banner only shows on this board
    /// AND only until the user marks the tutorial complete.
    private var isTutorialBoard: Bool {
        board.question == "Should I work out today or rest?"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if isTutorialBoard && !hasCompletedTutorial {
                    tutorialCoachmark
                }

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
    }

    // MARK: - Question

    @FocusState private var questionFocused: Bool
    @FocusState private var conclusionFocused: Bool

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: plainEnglishMode ? "Question" : "The question", icon: "questionmark.circle")
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

    @AppStorage("strictBayesMode") private var strictBayesMode = false
    @AppStorage("plainEnglishMode") private var plainEnglishMode = false

    private var hypothesesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: plainEnglishMode ? "Hypotheses" : "Stars to test", icon: "star")
                    Text(strictBayesMode
                         ? "Set a prior, then watch the posterior update with each \(plainEnglishMode ? "rating" : "observation")."
                         : "Each candidate explanation. Ranked by what hasn't been knocked down.")
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
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            board.hypotheses.append(h)
                        }
                    } label: {
                        addPillLabel(plainEnglishMode ? "Add hypothesis" : "Add a star", systemImage: "plus")
                    }
                }
            }

            ForEach(board.sortedHypotheses) { hyp in
                HypothesisRow(
                    hypothesis: hyp,
                    canDelete: board.hypotheses.count > 2,
                    showPriorSlider: strictBayesMode,
                    onDelete: {
                        board.cellRatings.removeAll { $0.hypothesisID == hyp.id }
                        board.hypotheses.removeAll { $0.id == hyp.id }
                    }
                )
            }

            // Unknown-unknowns prompt — appears once 2+ hypotheses exist. Pushes the
            // user to add the boring/contrarian hypothesis they almost dismissed.
            if board.activeHypotheses.count >= 2 && board.hypotheses.count < 6 {
                HStack(spacing: 7) {
                    Image(systemName: "questionmark.app.dashed")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textDim)
                    Text("Have you considered the boring or contrarian explanation?")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(Theme.textDim)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(Color.white.opacity(0.018), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 0.75, dash: [3, 2]))
                )
            }

            // Conjunction-fallacy warnings — flag overlapping or "X and Y" hypotheses.
            // Tversky/Kahneman's classic guard: P(X ∧ Y) ≤ P(X), so a hypothesis
            // containing "and" is by definition less probable than its parts.
            ForEach(Array(board.conjunctionWarnings.enumerated()), id: \.offset) { _, warning in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "function")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CONJUNCTION CHECK")
                            .font(.system(size: 8.5, weight: .heavy))
                            .tracking(1.0)
                            .foregroundStyle(Theme.warning)
                        Text("\"\(warning.0.name)\": \(warning.1)")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(Theme.warning.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Theme.warning.opacity(0.18), lineWidth: 1)
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
                    SectionLabel(text: plainEnglishMode ? "Evidence" : "Observation log",
                                 icon: plainEnglishMode ? "doc.text" : "binoculars")
                    Text(plainEnglishMode
                         ? "Each piece of evidence weighted by trust × relevance."
                         : "Each piece of evidence is one observation. Sky × view is your condition.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    haptic.impactOccurred()
                    let ev = Evidence(sortOrder: board.evidences.count)
                    Telemetry.activation("first_evidence")
                    Telemetry.coreAction("add_evidence")
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        board.evidences.append(ev)
                    }
                } label: {
                    addPillLabel(plainEnglishMode ? "Add evidence" : "Log observation",
                                 systemImage: plainEnglishMode ? "plus" : "binoculars")
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
                    SectionLabel(text: plainEnglishMode ? "Matrix" : "The star chart",
                                 icon: plainEnglishMode ? "tablecells" : "scope")
                    Text(plainEnglishMode
                         ? "Tap any cell to rate that evidence against that hypothesis. Empty cells pulse."
                         : "Each cell is one sightline. Empty cells pulse — unobserved.")
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
            HStack(spacing: 8) {
                if !showResults {
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(showResults
                 ? (plainEnglishMode ? "Hide ranking" : "Hide constellation")
                 : (plainEnglishMode ? "See ranking" : "Confirm the constellation"))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                if !showResults {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                        .opacity(0.7)
                }
            }
            .foregroundStyle(showResults ? Theme.textSecondary : Theme.accent)
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
            .background {
                ZStack {
                    Capsule()
                        .fill(showResults ? Color.white.opacity(0.025) : Theme.accent.opacity(0.08))
                    Capsule()
                        .strokeBorder(
                            showResults ? Theme.hairline : Theme.accent.opacity(0.45),
                            lineWidth: 1
                        )
                }
                .shadow(color: showResults ? .clear : Theme.accent.opacity(0.35), radius: showResults ? 0 : 18)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Conclusion

    private var conclusionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: plainEnglishMode ? "Conclusion" : "Your verdict", icon: "checkmark.seal")
            Text(plainEnglishMode
                 ? "Based on the evidence, what do you think?"
                 : "Based on the constellation, what do you think?")
                .font(.caption)
                .foregroundStyle(Theme.textDim)
                .italic()
            TextField("Based on the evidence, I believe…", text: $board.conclusion, axis: .vertical)
                .font(.system(.body, design: .rounded))
                .lineLimit(3...8)
                .foregroundStyle(Theme.textPrimary)
                .focused($conclusionFocused)
                .celestialField(isFocused: conclusionFocused)

            // Calibration: confidence slider + check-in date. These appear once a
            // verdict has been written. Reckon will surface a calibration curve
            // across all completed boards over time, turning a one-shot tool into
            // a thinking gym that gets better with each decision.
            if !board.conclusion.isEmpty {
                calibrationCard
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                preMortemCard
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .cardStyle()
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: board.conclusion.isEmpty)
    }

    /// Pre-mortem prompt — Klein/Murphyjitsu. After the user writes a verdict and
    /// sets confidence, force one more falsificationist beat: imagine the verdict
    /// turned out wrong in a year. What happened? Catches wishful thinking that
    /// even refutation-first scoring misses, because it asks the user to actively
    /// imagine being wrong AFTER they've reached their conclusion.
    private var preMortemCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.bubble")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.warning)
                Text("PRE-MORTEM")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(Theme.warning.opacity(0.85))
            }
            Text("Imagine you're wrong about this in a year. What happened?")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            TextField("Concretely — what got you here?", text: $board.preMortem, axis: .vertical)
                .font(.system(.body, design: .rounded))
                .lineLimit(2...5)
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.warning.opacity(0.20), lineWidth: 1)
                )
            Text("Imagining concrete failure modes after a conclusion catches wishful thinking that even refutation-first scoring misses.")
                .font(.system(size: 10))
                .italic()
                .foregroundStyle(Theme.textDim)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.warning.opacity(0.18), lineWidth: 1)
                )
        }
    }

    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "gauge.with.needle")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("CALIBRATION")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(Theme.accent.opacity(0.85))
            }

            // Confidence
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("How confident are you?")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("\(board.confidence ?? 50)%")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.accent)
                        .contentTransition(.numericText())
                }
                Slider(
                    value: Binding(
                        get: { Double(board.confidence ?? 50) },
                        set: { board.confidence = Int($0) }
                    ),
                    in: 0...100,
                    step: 5
                )
                .tint(Theme.accent)
            }

            // Check-in date
            VStack(alignment: .leading, spacing: 6) {
                Text("Remind me to check the outcome on:")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    ForEach(checkInChoices, id: \.label) { choice in
                        Button {
                            haptic.impactOccurred()
                            withAnimation(.spring(response: 0.3)) {
                                board.checkInDate = choice.date
                            }
                            // Schedule the actual reminder. Permission is requested
                            // inside the manager — first time only.
                            Task {
                                await NotificationManager.scheduleCheckIn(
                                    boardID: board.id,
                                    question: board.question,
                                    fireAt: choice.date
                                )
                            }
                        } label: {
                            Text(choice.label)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(
                                    isSelectedCheckIn(choice) ? Color(hex: "0A0A12") : Theme.textSecondary
                                )
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(
                                    isSelectedCheckIn(choice) ? Theme.accent : Color.white.opacity(0.04),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.18), lineWidth: 1)
                )
        }
    }

    private struct CheckInChoice {
        let label: String
        let days: Int
        var date: Date { Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date() }
    }

    private var checkInChoices: [CheckInChoice] {
        [
            .init(label: "1w", days: 7),
            .init(label: "1m", days: 30),
            .init(label: "3m", days: 90),
            .init(label: "6m", days: 180),
            .init(label: "1y", days: 365),
        ]
    }

    private func isSelectedCheckIn(_ choice: CheckInChoice) -> Bool {
        guard let stored = board.checkInDate else { return false }
        // Match within ~12 hours
        return abs(stored.timeIntervalSince(choice.date)) < 12 * 3600
    }

    // MARK: - Footer

    /// Small accent-tinted capsule action. Replaces tiny gray "+ add" labels.
    /// Reads like "log an observation" or "add a new star" — verbs that fit the
    /// observatory metaphor.
    private func addPillLabel(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.accent.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.4), lineWidth: 1))
        .primaryCTAGlow(strength: 0.18, radius: 10)
    }

    /// Tutorial coachmark — a friendly inline card at the top of the tutorial board
    /// guiding the user through their first interactions. Auto-fades when dismissed.
    /// Designed to read like a Steve Jobs welcome note, not a forced-march onboarding
    /// overlay. The user can ignore it and the tutorial board still works as a normal board.
    private var tutorialCoachmark: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "F5C49A"))
                Text("YOUR FIRST BOARD")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(Color(hex: "F5C49A"))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        hasCompletedTutorial = true
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textDim)
                }
                .buttonStyle(.plain)
            }

            Text("Two hypotheses. Two pieces of evidence. Two cells already rated.\nTry rating the empty cells in the matrix below — long-press a cell to cycle ratings, or tap to pick one.")
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(2)

            Text("When you're done, tap \"\(plainEnglishMode ? "See ranking" : "Confirm the constellation")\" to see which hypothesis holds up.")
                .font(.caption)
                .italic()
                .foregroundStyle(Theme.textDim)
                .lineSpacing(2)

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    hasCompletedTutorial = true
                }
            } label: {
                Text("I've got it →")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: "0A0A12"))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.accent, in: Capsule()).primaryCTAGlow()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.7))
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: "F5C49A").opacity(0.18), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(hex: "F5C49A").opacity(0.4), lineWidth: 1)
            }
            .shadow(color: Color(hex: "F5C49A").opacity(0.2), radius: 12)
        }
    }

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
