import Foundation
import SwiftData
import SwiftUI

// MARK: - Rating

enum Rating: String, Codable, CaseIterable, Identifiable {
    case stronglySupports = "CC"
    case supports = "C"
    case irrelevant = "N"
    case contradicts = "I"
    case stronglyContradicts = "II"

    var id: String { rawValue }

    /// Celestial icon vocabulary. Each rating is "what this observation does to the
    /// star": brightens it, leaves it alone, or dims it. Replaces the old generic
    /// hearts/thumbs-up — those were a brand mismatch in a star-map app.
    var iconName: String {
        switch self {
        case .stronglySupports:    "sparkles"           // bright burst — confirms the star
        case .supports:            "star.fill"          // confirmed star
        case .irrelevant:          "circle.dotted"      // silent — neither dims nor brightens
        case .contradicts:         "moon"               // partial dimming
        case .stronglyContradicts: "moon.stars.fill"    // eclipsed — visible refutation
        }
    }

    /// Analyst vocabulary — verbs an actual decision-maker would use, not horoscope
    /// language. "Confirms / Bears out / Inconclusive / Cuts against / Falsifies"
    /// echo the way Popper, Heuer, and forensic / intelligence analysts write about
    /// evidence-vs-hypothesis fit. "Falsifies" especially: the strongest possible
    /// claim that an observation has refuted a hypothesis (Popper's term).
    var label: String {
        switch self {
        case .stronglySupports:    "Confirms"
        case .supports:            "Bears out"
        case .irrelevant:          "Inconclusive"
        case .contradicts:         "Cuts against"
        case .stronglyContradicts: "Falsifies"
        }
    }

    var shortLabel: String {
        switch self {
        case .stronglySupports:    "confirms"
        case .supports:            "bears out"
        case .irrelevant:          "inconclusive"
        case .contradicts:         "cuts against"
        case .stronglyContradicts: "falsifies"
        }
    }

    var value: Int {
        switch self {
        case .stronglySupports: 2
        case .supports: 1
        case .irrelevant: 0
        case .contradicts: -1
        case .stronglyContradicts: -2
        }
    }

    /// Likelihood ratio P(E|H) / P(E|¬H) — the proper Bayesian interpretation of
    /// what each rating says about a hypothesis. Used in strict Bayes mode to
    /// compute posteriors via Bayes's theorem instead of weighted-sum heuristics.
    /// Values mirror the Heuer/Tetlock convention of order-of-magnitude steps:
    /// stronglySupports ≈ 9× more likely under H than under ¬H, contradicts ≈ 1/3, etc.
    var likelihoodRatio: Double {
        switch self {
        case .stronglySupports:    9.0
        case .supports:            3.0
        case .irrelevant:          1.0
        case .contradicts:         1.0 / 3.0
        case .stronglyContradicts: 1.0 / 9.0
        }
    }

    var color: Color {
        switch self {
        case .stronglySupports: Color(hex: "7EC49B")
        case .supports: Color(hex: "A0CFA0")
        case .irrelevant: Color(hex: "8A8278")
        case .contradicts: Color(hex: "E8C47A")
        case .stronglyContradicts: Color(hex: "D4746A")
        }
    }

    var bgColor: Color {
        color.opacity(0.15)
    }
}

// MARK: - Weight

enum Weight: String, Codable, CaseIterable {
    case high = "H"
    case medium = "M"
    case low = "L"

    var label: String {
        switch self {
        case .high: "High"
        case .medium: "Med"
        case .low: "Low"
        }
    }

    /// Sky-quality label for credibility (source trust). Astronomical metaphor:
    /// a clear sky lets you see the truth; a cloudy one obscures it.
    var skyLabel: String {
        switch self {
        case .high: "Clear"
        case .medium: "Hazy"
        case .low: "Cloudy"
        }
    }

    /// Sightline label for relevance (how directly the observation bears on the
    /// hypothesis). Direct line of sight vs peripheral glimpse.
    var sightLabel: String {
        switch self {
        case .high: "Direct"
        case .medium: "Angle"
        case .low: "Edge"
        }
    }

    var multiplier: Double {
        switch self {
        case .high: 3
        case .medium: 2
        case .low: 1
        }
    }

    var tip: String {
        switch self {
        case .high: "Very trustworthy / highly relevant"
        case .medium: "Somewhat trustworthy / somewhat relevant"
        case .low: "Uncertain source / tangentially relevant"
        }
    }
}

// MARK: - Cell Key

struct CellKey: Hashable, Codable {
    let evidenceID: UUID
    let hypothesisID: UUID
}

// MARK: - Hypothesis

@Model
final class Hypothesis {
    var id: UUID
    var name: String
    var colorHex: String
    var isRuledOut: Bool
    var sortOrder: Int
    /// Pre-commitment falsifier: what observation would prove this hypothesis wrong?
    /// Asked at hypothesis creation time. At verdict time, the app shows whether the
    /// stated falsifier actually showed up in evidence — surfacing the structural
    /// difference between reasoning (committing to falsifiers up front) and
    /// rationalization (adjusting standards to fit conclusions).
    var falsifier: String

    /// Prior probability for this hypothesis in strict Bayes mode (0...1). Default
    /// is 0.0, which Reckon interprets as "use uniform prior across active hypotheses
    /// at compute time." User-edited priors are treated literally and normalized.
    /// Forces base-rate thinking up front — the most common cognitive failure ACH
    /// users skip.
    var priorProbability: Double

    /// Auxiliary assumptions this hypothesis depends on. Quine-Duhem awareness: when
    /// evidence "falsifies" a hypothesis, the failure may actually be in an auxiliary
    /// assumption, not the core hypothesis itself. Surfacing this field reminds users
    /// that refutation is conjunctive, not crisp.
    var auxiliaryAssumptions: String

    /// Steel-manned case for this hypothesis: the strongest version of the argument
    /// FOR it. Captured before "dimming" (ruling out) so users have to engage with
    /// the strongest version of a disfavored position before discarding it. Fixes
    /// the most common ACH failure: rating a disfavored hypothesis dismissively,
    /// then ruling it out — never actually wrestling with its strongest form.
    var steelmanCase: String

    init(name: String = "", colorHex: String = "EF8B6E", sortOrder: Int = 0, falsifier: String = "") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.isRuledOut = false
        self.sortOrder = sortOrder
        self.falsifier = falsifier
        self.priorProbability = 0.0
        self.auxiliaryAssumptions = ""
        self.steelmanCase = ""
    }

    var color: Color { Color(hex: colorHex) }
}

// MARK: - Evidence

@Model
final class Evidence {
    var id: UUID
    var text: String
    var credibility: String  // Weight raw value
    var relevance: String    // Weight raw value
    var sortOrder: Int

    init(text: String = "", credibility: Weight = .medium, relevance: Weight = .medium, sortOrder: Int = 0) {
        self.id = UUID()
        self.text = text
        self.credibility = credibility.rawValue
        self.relevance = relevance.rawValue
        self.sortOrder = sortOrder
    }

    var credWeight: Weight { Weight(rawValue: credibility) ?? .medium }
    var relWeight: Weight { Weight(rawValue: relevance) ?? .medium }
}

// MARK: - Cell Rating

@Model
final class CellRating {
    var id: UUID
    var evidenceID: UUID
    var hypothesisID: UUID
    var ratingValue: String?  // Rating raw value
    var note: String

    init(evidenceID: UUID, hypothesisID: UUID, rating: Rating? = nil, note: String = "") {
        self.id = UUID()
        self.evidenceID = evidenceID
        self.hypothesisID = hypothesisID
        self.ratingValue = rating?.rawValue
        self.note = note
    }

    var rating: Rating? {
        get { ratingValue.flatMap { Rating(rawValue: $0) } }
        set { ratingValue = newValue?.rawValue }
    }
}

// MARK: - Board

@Model
final class Board {
    var id: UUID
    var question: String
    var conclusion: String
    var createdAt: Date
    var updatedAt: Date

    /// Calibration: when the user finalizes their conclusion, ask them how confident
    /// they are (0-100) and when they want to check whether they were right. Lets
    /// the app surface a per-user calibration curve over time across many boards.
    var confidence: Int?            // 0...100, set when conclusion is locked
    var checkInDate: Date?           // user-set reminder date for outcome review
    var actualOutcome: String        // filled in at check-in: what actually happened
    var outcomeAccuracy: Int?        // user's self-rating: was the leading hypothesis right? (0...100)
    var outcomeReviewedAt: Date?     // when the user actually came back

    /// Whether this board is a template — a reusable hypothesis structure with no
    /// real ratings. Templates appear above starter archetypes in the picker.
    var isTemplate: Bool
    var templateName: String

    /// Pre-mortem: after writing a conclusion, the user imagines the conclusion was
    /// wrong in a year and writes what plausibly went wrong. Forces a final
    /// falsificationist beat AFTER the verdict — catches the wishful thinking that
    /// even refutation-first scoring misses.
    var preMortem: String

    @Relationship(deleteRule: .cascade) var hypotheses: [Hypothesis]
    @Relationship(deleteRule: .cascade) var evidences: [Evidence]
    @Relationship(deleteRule: .cascade) var cellRatings: [CellRating]

    init(question: String = "", isExample: Bool = false, archetype: ExampleArchetype? = nil) {
        self.id = UUID()
        self.question = question
        self.conclusion = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.confidence = nil
        self.checkInDate = nil
        self.actualOutcome = ""
        self.outcomeAccuracy = nil
        self.outcomeReviewedAt = nil
        self.isTemplate = false
        self.templateName = ""
        self.preMortem = ""
        self.hypotheses = []
        self.evidences = []
        self.cellRatings = []

        if let archetype {
            setupExample(archetype)
        } else if isExample {
            // Backward compat default: founder/product example
            setupExample(.founder)
        } else {
            setupBlank()
        }
    }

    var sortedHypotheses: [Hypothesis] {
        hypotheses.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedEvidence: [Evidence] {
        evidences.sorted { $0.sortOrder < $1.sortOrder }
    }

    var activeHypotheses: [Hypothesis] {
        sortedHypotheses.filter { !$0.isRuledOut }
    }

    var ruledOutHypotheses: [Hypothesis] {
        sortedHypotheses.filter { $0.isRuledOut }
    }

    var displayName: String {
        question.isEmpty ? "Untitled board" : String(question.prefix(50))
    }

    // MARK: Cell Access

    func cellRating(evidenceID: UUID, hypothesisID: UUID) -> CellRating? {
        cellRatings.first { $0.evidenceID == evidenceID && $0.hypothesisID == hypothesisID }
    }

    func rating(evidenceID: UUID, hypothesisID: UUID) -> Rating? {
        cellRating(evidenceID: evidenceID, hypothesisID: hypothesisID)?.rating
    }

    func note(evidenceID: UUID, hypothesisID: UUID) -> String {
        cellRating(evidenceID: evidenceID, hypothesisID: hypothesisID)?.note ?? ""
    }

    func setRating(_ rating: Rating?, evidenceID: UUID, hypothesisID: UUID) {
        if let existing = cellRating(evidenceID: evidenceID, hypothesisID: hypothesisID) {
            existing.rating = rating
        } else if let rating {
            let cell = CellRating(evidenceID: evidenceID, hypothesisID: hypothesisID, rating: rating)
            cellRatings.append(cell)
        }
        updatedAt = Date()
    }

    func setNote(_ note: String, evidenceID: UUID, hypothesisID: UUID) {
        if let existing = cellRating(evidenceID: evidenceID, hypothesisID: hypothesisID) {
            existing.note = note
        } else {
            let cell = CellRating(evidenceID: evidenceID, hypothesisID: hypothesisID, note: note)
            cellRatings.append(cell)
        }
        updatedAt = Date()
    }

    // MARK: Scoring

    func score(for hypothesis: Hypothesis) -> Int? {
        guard !hypothesis.isRuledOut else { return nil }
        var total = 0.0
        for ev in evidences {
            if let r = rating(evidenceID: ev.id, hypothesisID: hypothesis.id) {
                let weight = ev.credWeight.multiplier * ev.relWeight.multiplier
                total += Double(r.value) * weight
            }
        }
        return Int(total)
    }

    /// Count of refuting cells for a hypothesis — number of evidence rows rated as
    /// `.contradicts` or `.stronglyContradicts`. Heuer's ACH technique ranks hypotheses
    /// by FEWEST refutations (not most support), because confirming evidence rarely
    /// distinguishes between competing explanations — refuting evidence does.
    func refutationCount(for hypothesis: Hypothesis) -> Int {
        guard !hypothesis.isRuledOut else { return 0 }
        return evidences.compactMap { ev in
            rating(evidenceID: ev.id, hypothesisID: hypothesis.id)
        }.filter { $0 == .contradicts || $0 == .stronglyContradicts }.count
    }

    /// Count of supporting cells for a hypothesis. Used as a tiebreaker after
    /// refutation count (the primary ACH ranking signal).
    func supportCount(for hypothesis: Hypothesis) -> Int {
        guard !hypothesis.isRuledOut else { return 0 }
        return evidences.compactMap { ev in
            rating(evidenceID: ev.id, hypothesisID: hypothesis.id)
        }.filter { $0 == .supports || $0 == .stronglySupports }.count
    }

    /// Weighted refutation pressure — refuting cells × evidence credibility × relevance.
    /// Stronger and higher-weighted refutations contribute more.
    func weightedRefutation(for hypothesis: Hypothesis) -> Double {
        guard !hypothesis.isRuledOut else { return 0 }
        var total = 0.0
        for ev in evidences {
            guard let r = rating(evidenceID: ev.id, hypothesisID: hypothesis.id) else { continue }
            if r == .contradicts || r == .stronglyContradicts {
                let weight = ev.credWeight.multiplier * ev.relWeight.multiplier
                total += Double(abs(r.value)) * weight
            }
        }
        return total
    }

    // MARK: Bayesian core

    /// Effective prior for a hypothesis: respects user-set priors when meaningfully
    /// nonzero, otherwise distributes uniformly across active hypotheses. Always
    /// normalized so all active hypotheses sum to 1.0.
    func effectivePrior(for hypothesis: Hypothesis) -> Double {
        guard !hypothesis.isRuledOut else { return 0 }
        let totalUserPrior = activeHypotheses.reduce(0.0) { $0 + max(0, $1.priorProbability) }
        if totalUserPrior > 0.001 {
            return max(0, hypothesis.priorProbability) / totalUserPrior
        }
        return 1.0 / Double(activeHypotheses.count)
    }

    /// Bayesian posterior probability for a hypothesis given current evidence. Uses
    /// each cell rating as a likelihood ratio per Tetlock/Heuer convention, then
    /// computes posterior via Bayes's theorem. Credibility × relevance modulates how
    /// much each rating shifts the posterior — low-credibility / low-relevance evidence
    /// pulls the LR closer to 1 (no update).
    ///
    /// Returns a normalized probability in [0...1] across all active hypotheses.
    func bayesianPosterior(for hypothesis: Hypothesis) -> Double {
        guard !hypothesis.isRuledOut else { return 0 }
        let active = activeHypotheses
        guard !active.isEmpty else { return 0 }

        // Compute unnormalized posterior for each active hypothesis: prior × ∏ LR
        let unnormalized: [Double] = active.map { h in
            var posterior = effectivePrior(for: h)
            for ev in evidences {
                guard let r = rating(evidenceID: ev.id, hypothesisID: h.id) else { continue }
                let baseLR = r.likelihoodRatio
                // Modulate LR toward 1 based on weight — weak evidence shouldn't
                // swing posteriors as hard as a high-credibility, high-relevance datum.
                let weight = (ev.credWeight.multiplier * ev.relWeight.multiplier) / 9.0  // 0...1
                let adjustedLR = pow(baseLR, weight)
                posterior *= adjustedLR
            }
            return posterior
        }
        let total = unnormalized.reduce(0.0, +)
        guard total > 0 else { return effectivePrior(for: hypothesis) }
        guard let myIndex = active.firstIndex(where: { $0.id == hypothesis.id }) else { return 0 }
        return unnormalized[myIndex] / total
    }

    /// Hypotheses ranked by Bayesian posterior probability (descending). Used when
    /// strict Bayes mode is on. The leading hypothesis is the one with highest
    /// posterior — accounting for both priors and likelihood ratios from evidence.
    var rankedByBayesianPosterior: [(hypothesis: Hypothesis, posterior: Double)] {
        activeHypotheses
            .map { ($0, bayesianPosterior(for: $0)) }
            .sorted { $0.1 > $1.1 }
    }

    /// Inference-to-the-Best-Explanation score: explanatory completeness × consistency.
    /// A hypothesis "best explains" the evidence if it accounts for many observations
    /// (high support count) with few contradictions. Different from refutation-first
    /// (which only counts negatives) and from Bayesian (which integrates priors). Used
    /// when both refutation-first and Bayesian rankings disagree as a tiebreaker frame.
    func ibeScore(for hypothesis: Hypothesis) -> Double {
        guard !hypothesis.isRuledOut else { return 0 }
        var supportPower = 0.0
        var contradictPower = 0.0
        for ev in evidences {
            guard let r = rating(evidenceID: ev.id, hypothesisID: hypothesis.id) else { continue }
            let weight = ev.credWeight.multiplier * ev.relWeight.multiplier
            if r.value > 0 { supportPower += Double(r.value) * weight }
            if r.value < 0 { contradictPower += Double(abs(r.value)) * weight }
        }
        // Best-explanation: rewards explained evidence, penalizes contradiction
        return supportPower - contradictPower
    }

    var rankedByIBE: [(hypothesis: Hypothesis, score: Double)] {
        activeHypotheses
            .map { ($0, ibeScore(for: $0)) }
            .sorted { $0.1 > $1.1 }
    }

    /// Conjunction-fallacy detection: hypotheses whose names share substantial overlap
    /// or that contain "and" / "or" combining clauses. By definition, P(X ∧ Y) ≤ P(X),
    /// so a hypothesis like "X and Y" can never be more probable than "X" alone.
    /// Returns hypothesis pairs that may be conjunctively related so the UI can flag.
    var conjunctionWarnings: [(Hypothesis, String)] {
        var warnings: [(Hypothesis, String)] = []
        for h in activeHypotheses {
            let lower = h.name.lowercased()
            if lower.contains(" and ") || lower.contains(" plus ") || lower.contains("&") {
                warnings.append((h, "Has 'and' — conjunction is by definition less likely than either part alone"))
            }
        }
        // Detect substantial name-overlap pairs
        let active = activeHypotheses
        for i in 0..<active.count {
            for j in (i+1)..<active.count {
                let a = Set(active[i].name.lowercased().split(separator: " ").map(String.init).filter { $0.count > 4 })
                let b = Set(active[j].name.lowercased().split(separator: " ").map(String.init).filter { $0.count > 4 })
                let shared = a.intersection(b)
                if shared.count >= 2 {
                    warnings.append((active[i], "Overlaps with '\(active[j].name)' — make sure they're truly competing"))
                    break
                }
            }
        }
        return warnings
    }

    /// Astronomical metaphor: a star's "stability" — its steadiness under observation.
    /// Lower refutation pressure = more stable. Returned as 0...1 where 1 is perfectly
    /// stable (nothing has dimmed it). Used to drive star-brightness visualization.
    func stability(for hypothesis: Hypothesis) -> Double {
        guard !hypothesis.isRuledOut else { return 0 }
        let weighted = weightedRefutation(for: hypothesis)
        // Each cell can contribute up to 2 (strong contradicts) × 9 (high×high) = 18 to refutation.
        // Use evidence count to scale max, falling back to 1 to avoid div by zero.
        let cellCount = max(1, evidences.count)
        let maxPossibleRefutation = Double(cellCount) * 18.0
        let normalized = weighted / maxPossibleRefutation
        return max(0, 1.0 - normalized)
    }

    /// Hypotheses ranked by Heuer's ACH technique: fewest refutations first, with a
    /// tiebreaker on most support. The "leading" hypothesis is the steadiest star —
    /// the one that no observation has knocked down.
    var rankedHypotheses: [(hypothesis: Hypothesis, score: Int, refutations: Int, supports: Int)] {
        activeHypotheses
            .compactMap { h in
                guard let s = score(for: h) else { return nil }
                return (h, s, refutationCount(for: h), supportCount(for: h))
            }
            .sorted { lhs, rhs in
                if lhs.refutations != rhs.refutations { return lhs.refutations < rhs.refutations }
                if lhs.supports != rhs.supports { return lhs.supports > rhs.supports }
                return lhs.score > rhs.score
            }
    }

    var maxAbsScore: Int {
        let scores = activeHypotheses.compactMap { score(for: $0) }
        return scores.map { abs($0) }.max() ?? 1
    }

    var totalCells: Int { activeHypotheses.count * evidences.count }

    var filledCells: Int {
        cellRatings.filter { cell in
            cell.ratingValue != nil &&
            // Count a rated cell only when its hypothesis still exists and is not
            // ruled out. Using optional chaining (instead of a force-unwrap) keeps
            // an orphaned cell rating — one whose hypothesis was deleted without its
            // ratings being cleaned up — from crashing the whole board list.
            (hypotheses.first(where: { $0.id == cell.hypothesisID })?.isRuledOut == false)
        }.count
    }

    var completionPercent: Int {
        totalCells > 0 ? Int((Double(filledCells) / Double(totalCells)) * 100) : 0
    }

    // MARK: Diagnostics

    struct DiagnosticItem: Identifiable {
        let id: UUID
        let evidence: Evidence
        let spread: Int
    }

    var diagnostics: [DiagnosticItem] {
        evidences.map { ev in
            let values = activeHypotheses.map { h in
                rating(evidenceID: ev.id, hypothesisID: h.id)?.value ?? 0
            }
            let spread = values.isEmpty ? 0 : (values.max()! - values.min()!)
            return DiagnosticItem(id: ev.id, evidence: ev, spread: spread)
        }.sorted { $0.spread > $1.spread }
    }

    var highDiagnostics: [DiagnosticItem] { diagnostics.filter { $0.spread >= 2 } }
    var lowDiagnostics: [DiagnosticItem] { diagnostics.filter { $0.spread == 0 } }

    // MARK: Bias Warnings

    var biasWarnings: [String] {
        var warnings: [String] = []
        for h in activeHypotheses {
            if let warning = monotonicBias(for: h) {
                warnings.append(warning)
            }
        }
        if evidences.count < 3 { warnings.append("Only a few data points. Could you be missing something?") }
        return warnings
    }

    /// Returns a brief inline bias warning for a single hypothesis column (3+ ratings, all
    /// in the same direction). nil if the column is balanced or under-rated. Used by the
    /// matrix to show bias detection inline at the column header — so users see it AS they
    /// rate, not after they hit a "results" toggle.
    func monotonicBias(for hypothesis: Hypothesis) -> String? {
        guard !hypothesis.isRuledOut else { return nil }
        let ratings = evidences.compactMap { rating(evidenceID: $0.id, hypothesisID: hypothesis.id) }
        guard ratings.count >= 3 else { return nil }
        let allSupport = ratings.allSatisfy { $0 == .stronglySupports || $0 == .supports }
        let allOppose = ratings.allSatisfy { $0 == .stronglyContradicts || $0 == .contradicts }
        if allSupport { return "No disconfirming evidence yet" }
        if allOppose  { return "No supporting evidence yet" }
        return nil
    }

    /// Returns the column score normalized to -1...1 for visual representation in the
    /// matrix column header bar. nil when there's no signal yet (no ratings or all
    /// neutral). Used to drive a thin colored bar that fills as evidence accumulates.
    func normalizedScore(for hypothesis: Hypothesis) -> Double? {
        guard !hypothesis.isRuledOut else { return nil }
        let ratings = evidences.compactMap { ev -> (Rating, Double)? in
            guard let r = rating(evidenceID: ev.id, hypothesisID: hypothesis.id) else { return nil }
            let weight = ev.credWeight.multiplier * ev.relWeight.multiplier
            return (r, weight)
        }
        guard !ratings.isEmpty else { return nil }
        let total = ratings.reduce(0.0) { $0 + Double($1.0.value) * $1.1 }
        // Max possible per cell = 2 * 9 (high * high * stronglySupports). Sum to scale.
        let maxPossible = Double(ratings.count) * 2.0 * 9.0
        guard maxPossible > 0 else { return nil }
        let normalized = total / maxPossible
        if normalized > -0.05 && normalized < 0.05 { return 0 }  // round near-zero to flat
        return max(-1, min(1, normalized))
    }

    // MARK: Export

    func exportMarkdown() -> String {
        var md = "# Weigh It\n\n"
        if !question.isEmpty { md += "**Question:** \(question)\n\n" }
        md += "## Explanations\n"
        for (i, h) in sortedHypotheses.enumerated() {
            let s = score(for: h)
            let scoreStr = s.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "n/a"
            let prefix = h.isRuledOut ? "~~" : ""
            let suffix = h.isRuledOut ? "~~ (ruled out)" : ""
            md += "\(i + 1). \(prefix)\(h.name.isEmpty ? "Unnamed" : h.name)\(suffix) → score: \(scoreStr)\n"
        }
        md += "\n## Evidence\n\n"
        for ev in sortedEvidence {
            md += "**\(ev.text.isEmpty ? "Unnamed" : ev.text)** (trust: \(ev.credWeight.label), relevance: \(ev.relWeight.label))\n"
            for h in sortedHypotheses {
                if let r = rating(evidenceID: ev.id, hypothesisID: h.id) {
                    let n = note(evidenceID: ev.id, hypothesisID: h.id)
                    md += "  - vs. \(h.name.isEmpty ? "?" : h.name): \(r.shortLabel)\(n.isEmpty ? "" : " — \"\(n)\"")\n"
                }
            }
            md += "\n"
        }
        if !conclusion.isEmpty { md += "## Conclusion\n\n\(conclusion)\n\n" }
        md += "---\n_Weigh It — based on Analysis of Competing Hypotheses_\n"
        return md
    }

    // MARK: Setup

    private func setupBlank() {
        let colors = HypothesisColors.all
        hypotheses = [
            Hypothesis(name: "", colorHex: colors[0], sortOrder: 0),
            Hypothesis(name: "", colorHex: colors[1], sortOrder: 1),
        ]
        evidences = [Evidence(sortOrder: 0)]
    }

    private func setupExample(_ archetype: ExampleArchetype = .founder) {
        switch archetype {
        case .tutorial:       setupTutorialExample()
        case .shortseller:    setupShortsellerExample()
        case .founder:        setupFounderExample()
        case .scientist:      setupScientistExample()
        case .investigator:   setupInvestigatorExample()
        case .lifeDecision:   setupLifeDecisionExample()
        case .diagnostician:  setupDiagnosticianExample()
        }
    }

    // MARK: Tutorial — bare-bones first-time example
    // 2 hypotheses, 2 evidence, 2 cells pre-rated (to demonstrate the structure)
    // and 2 cells empty (so the user gets to try rating themselves). Question is
    // a small, relatable everyday call so the user isn't intimidated by the topic
    // before they've understood the matrix.

    private func setupTutorialExample() {
        question = "Should I work out today or rest?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "Work out — long-term gains worth it", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "Rest — body needs recovery", colorHex: colors[1], sortOrder: 1)
        hypotheses = [h1, h2]

        let e1 = Evidence(text: "Slept poorly last night (5 hours)", credibility: .high, relevance: .high, sortOrder: 0)
        let e2 = Evidence(text: "Have an event tomorrow needing energy", credibility: .high, relevance: .high, sortOrder: 1)
        evidences = [e1, e2]

        // 2 cells pre-rated to demonstrate the structure; the other 2 cells are
        // intentionally empty so the user gets to do their first ratings themselves.
        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .contradicts,
                       note: "Bad sleep makes a hard workout less productive."),
            CellRating(evidenceID: e1.id, hypothesisID: h2.id, rating: .supports,
                       note: "Recovery sleep would help."),
            // e2 vs h1, e2 vs h2 left empty for user to rate
        ]
    }

    // MARK: Founder / product example

    private func setupFounderExample() {
        question = "Why did our latest product launch underperform?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "Marketing didn't reach the right audience", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "The product has usability issues", colorHex: colors[1], sortOrder: 1)
        let h3 = Hypothesis(name: "Pricing is too high for the market", colorHex: colors[2], sortOrder: 2)
        let h4 = Hypothesis(name: "Timing was wrong — market not ready", colorHex: colors[3], sortOrder: 3)
        hypotheses = [h1, h2, h3, h4]

        let e1 = Evidence(text: "Social media impressions up 40%", credibility: .high, relevance: .high, sortOrder: 0)
        let e2 = Evidence(text: "Support tickets doubled in the first week", credibility: .high, relevance: .high, sortOrder: 1)
        let e3 = Evidence(text: "Competitors priced 20% lower", credibility: .medium, relevance: .high, sortOrder: 2)
        let e4 = Evidence(text: "Users who finished onboarding had great retention", credibility: .medium, relevance: .medium, sortOrder: 3)
        let e5 = Evidence(text: "Search volume for category up only 5% YoY", credibility: .medium, relevance: .medium, sortOrder: 4)
        evidences = [e1, e2, e3, e4, e5]

        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .stronglyContradicts, note: "Impressions up = marketing DID reach people"),
            CellRating(evidenceID: e2.id, hypothesisID: h2.id, rating: .stronglySupports, note: "Support tickets = confused users"),
            CellRating(evidenceID: e3.id, hypothesisID: h3.id, rating: .stronglySupports),
            CellRating(evidenceID: e3.id, hypothesisID: h1.id, rating: .irrelevant),
            CellRating(evidenceID: e4.id, hypothesisID: h2.id, rating: .contradicts, note: "Good retention post-onboarding → maybe onboarding, not product"),
            CellRating(evidenceID: e5.id, hypothesisID: h4.id, rating: .supports, note: "Slow category growth = market still warming up"),
        ]
    }

    // MARK: Shortseller / financial-analyst example

    private func setupShortsellerExample() {
        question = "Is Acme Corp's reported growth real, or are they cooking the books?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "Real organic growth", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "Earnings management (channel stuffing, AR aging)", colorHex: colors[1], sortOrder: 1)
        let h3 = Hypothesis(name: "Outright accounting fraud", colorHex: colors[6], sortOrder: 2)
        let h4 = Hypothesis(name: "One-time tailwind treated as recurring", colorHex: colors[3], sortOrder: 3)
        hypotheses = [h1, h2, h3, h4]

        let e1 = Evidence(text: "DSO rose 40% YoY", credibility: .high, relevance: .high, sortOrder: 0)
        let e2 = Evidence(text: "C-suite insider selling spiked last quarter", credibility: .high, relevance: .medium, sortOrder: 1)
        let e3 = Evidence(text: "Top 3 customers = 60% of revenue", credibility: .high, relevance: .high, sortOrder: 2)
        let e4 = Evidence(text: "Auditor changed mid-year", credibility: .medium, relevance: .high, sortOrder: 3)
        let e5 = Evidence(text: "Revenue growth +30%, operating cash flow flat", credibility: .high, relevance: .high, sortOrder: 4)
        evidences = [e1, e2, e3, e4, e5]

        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .contradicts, note: "Healthy growth doesn't blow out DSO"),
            CellRating(evidenceID: e1.id, hypothesisID: h2.id, rating: .stronglySupports, note: "Classic channel-stuffing tell"),
            CellRating(evidenceID: e1.id, hypothesisID: h3.id, rating: .supports),
            CellRating(evidenceID: e2.id, hypothesisID: h1.id, rating: .contradicts),
            CellRating(evidenceID: e2.id, hypothesisID: h3.id, rating: .stronglySupports, note: "Insiders know first"),
            CellRating(evidenceID: e3.id, hypothesisID: h4.id, rating: .supports, note: "Concentration = lumpy, episodic revenue"),
            CellRating(evidenceID: e4.id, hypothesisID: h1.id, rating: .contradicts),
            CellRating(evidenceID: e4.id, hypothesisID: h3.id, rating: .stronglySupports, note: "Auditor changes mid-cycle = red flag"),
            CellRating(evidenceID: e5.id, hypothesisID: h1.id, rating: .stronglyContradicts, note: "Real growth converts to cash"),
            CellRating(evidenceID: e5.id, hypothesisID: h2.id, rating: .stronglySupports, note: "Accruals without cash = aggressive recognition"),
        ]
    }

    // MARK: Researcher / scientist example

    private func setupScientistExample() {
        question = "Why isn't our published finding replicating in independent studies?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "Original finding is real — replication conditions differed", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "P-hacking or publication bias inflated the original", colorHex: colors[1], sortOrder: 1)
        let h3 = Hypothesis(name: "Replication had insufficient power or sample mismatch", colorHex: colors[2], sortOrder: 2)
        let h4 = Hypothesis(name: "Measurement instrument inconsistency between studies", colorHex: colors[3], sortOrder: 3)
        hypotheses = [h1, h2, h3, h4]

        let e1 = Evidence(text: "Replication used different demographic", credibility: .high, relevance: .high, sortOrder: 0)
        let e2 = Evidence(text: "Original p-value was 0.048 (right at threshold)", credibility: .high, relevance: .high, sortOrder: 1)
        let e3 = Evidence(text: "Replication n=1200, original n=84", credibility: .high, relevance: .high, sortOrder: 2)
        let e4 = Evidence(text: "Replication used updated measurement protocol", credibility: .medium, relevance: .high, sortOrder: 3)
        let e5 = Evidence(text: "5 of 7 conceptual replications also failed", credibility: .high, relevance: .high, sortOrder: 4)
        evidences = [e1, e2, e3, e4, e5]

        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .stronglySupports, note: "Could explain divergence"),
            CellRating(evidenceID: e1.id, hypothesisID: h2.id, rating: .irrelevant),
            CellRating(evidenceID: e2.id, hypothesisID: h2.id, rating: .supports, note: "Borderline p suggests fragility"),
            CellRating(evidenceID: e2.id, hypothesisID: h1.id, rating: .contradicts),
            CellRating(evidenceID: e3.id, hypothesisID: h3.id, rating: .stronglyContradicts, note: "1200 is plenty of power"),
            CellRating(evidenceID: e3.id, hypothesisID: h1.id, rating: .contradicts),
            CellRating(evidenceID: e4.id, hypothesisID: h4.id, rating: .stronglySupports),
            CellRating(evidenceID: e5.id, hypothesisID: h1.id, rating: .stronglyContradicts, note: "Multiple conceptual failures kills the conditions argument"),
            CellRating(evidenceID: e5.id, hypothesisID: h2.id, rating: .stronglySupports, note: "Pattern of failure → original was likely fragile"),
        ]
    }

    // MARK: Investigator / journalist example

    private func setupInvestigatorExample() {
        question = "What really happened in the security breach?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "External attacker exploited an unpatched system", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "An insider with credentials acted maliciously", colorHex: colors[1], sortOrder: 1)
        let h3 = Hypothesis(name: "Third-party vendor was compromised first", colorHex: colors[2], sortOrder: 2)
        let h4 = Hypothesis(name: "Misreported normal access — no breach occurred", colorHex: colors[5], sortOrder: 3)
        hypotheses = [h1, h2, h3, h4]

        let e1 = Evidence(text: "Logs show access at 3am from a new IP", credibility: .high, relevance: .high, sortOrder: 0)
        let e2 = Evidence(text: "One employee's credentials used 3× outside their normal role", credibility: .high, relevance: .high, sortOrder: 1)
        let e3 = Evidence(text: "Vendor reported their own breach 2 weeks earlier", credibility: .high, relevance: .high, sortOrder: 2)
        let e4 = Evidence(text: "No data exfiltration found in 2 weeks of forensics", credibility: .medium, relevance: .high, sortOrder: 3)
        let e5 = Evidence(text: "Affected systems all have public CVEs from 6 months ago", credibility: .high, relevance: .medium, sortOrder: 4)
        evidences = [e1, e2, e3, e4, e5]

        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .stronglySupports),
            CellRating(evidenceID: e1.id, hypothesisID: h2.id, rating: .contradicts, note: "Insider would use familiar IP / hours"),
            CellRating(evidenceID: e2.id, hypothesisID: h2.id, rating: .stronglySupports),
            CellRating(evidenceID: e2.id, hypothesisID: h1.id, rating: .supports, note: "Stolen creds also fit"),
            CellRating(evidenceID: e3.id, hypothesisID: h3.id, rating: .stronglySupports),
            CellRating(evidenceID: e3.id, hypothesisID: h4.id, rating: .stronglyContradicts, note: "Confirmed prior breach makes 'no breach' implausible"),
            CellRating(evidenceID: e4.id, hypothesisID: h1.id, rating: .contradicts),
            CellRating(evidenceID: e4.id, hypothesisID: h4.id, rating: .supports),
            CellRating(evidenceID: e5.id, hypothesisID: h1.id, rating: .supports, note: "Unpatched CVEs + new IP = textbook"),
        ]
    }

    // MARK: Personal life-decision example

    private func setupLifeDecisionExample() {
        question = "Should I take this new job offer?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "Yes — significantly better long-term", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "Yes — better short-term but not long-term", colorHex: colors[3], sortOrder: 1)
        let h3 = Hypothesis(name: "No — current role is undervalued by me", colorHex: colors[5], sortOrder: 2)
        let h4 = Hypothesis(name: "No — wait, better options will appear", colorHex: colors[2], sortOrder: 3)
        hypotheses = [h1, h2, h3, h4]

        let e1 = Evidence(text: "25% comp increase", credibility: .high, relevance: .high, sortOrder: 0)
        let e2 = Evidence(text: "New role grows skills I want for 5-yr trajectory", credibility: .high, relevance: .high, sortOrder: 1)
        let e3 = Evidence(text: "New manager has bad reputation in industry", credibility: .medium, relevance: .high, sortOrder: 2)
        let e4 = Evidence(text: "Current company likely to IPO in 18 months", credibility: .medium, relevance: .high, sortOrder: 3)
        let e5 = Evidence(text: "Commute would double", credibility: .high, relevance: .medium, sortOrder: 4)
        evidences = [e1, e2, e3, e4, e5]

        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .supports),
            CellRating(evidenceID: e1.id, hypothesisID: h2.id, rating: .stronglySupports, note: "Comp jump alone could be short-term win"),
            CellRating(evidenceID: e2.id, hypothesisID: h1.id, rating: .stronglySupports),
            CellRating(evidenceID: e2.id, hypothesisID: h2.id, rating: .contradicts),
            CellRating(evidenceID: e3.id, hypothesisID: h1.id, rating: .stronglyContradicts, note: "Bad manager destroys long-term upside"),
            CellRating(evidenceID: e3.id, hypothesisID: h4.id, rating: .supports, note: "Reason to wait"),
            CellRating(evidenceID: e4.id, hypothesisID: h3.id, rating: .stronglySupports, note: "IPO upside is concrete"),
            CellRating(evidenceID: e4.id, hypothesisID: h4.id, rating: .supports),
            CellRating(evidenceID: e5.id, hypothesisID: h1.id, rating: .contradicts),
        ]
    }

    // MARK: Differential-diagnosis example

    private func setupDiagnosticianExample() {
        question = "What's most likely causing this patient's chronic fatigue?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "Iron-deficiency anemia", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "Subclinical hypothyroidism", colorHex: colors[1], sortOrder: 1)
        let h3 = Hypothesis(name: "Undiagnosed sleep apnea", colorHex: colors[2], sortOrder: 2)
        let h4 = Hypothesis(name: "Major depressive disorder", colorHex: colors[5], sortOrder: 3)
        let h5 = Hypothesis(name: "Chronic infection (post-viral, Lyme, EBV)", colorHex: colors[6], sortOrder: 4)
        hypotheses = [h1, h2, h3, h4, h5]

        let e1 = Evidence(text: "Hemoglobin 11.5 (low end of normal)", credibility: .high, relevance: .medium, sortOrder: 0)
        let e2 = Evidence(text: "TSH 4.2 (slightly elevated)", credibility: .high, relevance: .high, sortOrder: 1)
        let e3 = Evidence(text: "BMI 32, sleeps 9h but reports unrefreshed", credibility: .high, relevance: .high, sortOrder: 2)
        let e4 = Evidence(text: "Anhedonia and low mood × 3 months", credibility: .high, relevance: .high, sortOrder: 3)
        let e5 = Evidence(text: "Recent travel to tick-endemic area", credibility: .high, relevance: .medium, sortOrder: 4)
        evidences = [e1, e2, e3, e4, e5]

        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .supports, note: "Borderline; iron studies needed"),
            CellRating(evidenceID: e1.id, hypothesisID: h2.id, rating: .irrelevant),
            CellRating(evidenceID: e2.id, hypothesisID: h2.id, rating: .stronglySupports),
            CellRating(evidenceID: e2.id, hypothesisID: h1.id, rating: .contradicts),
            CellRating(evidenceID: e3.id, hypothesisID: h3.id, rating: .stronglySupports, note: "Classic OSA presentation"),
            CellRating(evidenceID: e3.id, hypothesisID: h4.id, rating: .irrelevant),
            CellRating(evidenceID: e4.id, hypothesisID: h4.id, rating: .stronglySupports),
            CellRating(evidenceID: e4.id, hypothesisID: h3.id, rating: .supports, note: "OSA can cause depressive symptoms"),
            CellRating(evidenceID: e5.id, hypothesisID: h5.id, rating: .supports),
        ]
    }
}

// MARK: - Example Archetypes

enum ExampleArchetype: String, CaseIterable, Identifiable {
    case tutorial       = "tutorial"
    case shortseller    = "shortseller"
    case founder        = "founder"
    case scientist      = "scientist"
    case investigator   = "investigator"
    case lifeDecision   = "life"
    case diagnostician  = "doctor"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tutorial:      "Quick tour"
        case .shortseller:   "The shortseller"
        case .founder:       "The founder"
        case .scientist:     "The researcher"
        case .investigator:  "The investigator"
        case .lifeDecision:  "The big personal call"
        case .diagnostician: "The diagnostician"
        }
    }

    var subtitle: String {
        switch self {
        case .tutorial:      "Start here if it's your first time"
        case .shortseller:   "Are these numbers real?"
        case .founder:       "Why didn't this work?"
        case .scientist:     "Why isn't this replicating?"
        case .investigator:  "What actually happened?"
        case .lifeDecision:  "Should I take the offer?"
        case .diagnostician: "What's the differential?"
        }
    }

    /// SF Symbol for the archetype card.
    var icon: String {
        switch self {
        case .tutorial:      "graduationcap"
        case .shortseller:   "chart.line.downtrend.xyaxis"
        case .founder:       "rocket"
        case .scientist:     "atom"
        case .investigator:  "doc.text.magnifyingglass"
        case .lifeDecision:  "signpost.right.and.left"
        case .diagnostician: "stethoscope"
        }
    }

    /// Hex color used to tint the archetype's card edge — keeps the night-sky
    /// aesthetic but gives each archetype a recognizable signal.
    var accentHex: String {
        switch self {
        case .tutorial:      "F5C49A"  // warm gold — beginner-friendly
        case .shortseller:   "D4746A"  // alarm red — danger
        case .founder:       "EF8B6E"  // warm peach — building
        case .scientist:     "5CC4B8"  // teal — clarity
        case .investigator:  "7E9BE0"  // night blue — depth
        case .lifeDecision:  "C490D4"  // violet — values
        case .diagnostician: "6EC4A0"  // green — health
        }
    }

    /// True for the tutorial — gets a special "START HERE" badge in the picker.
    var isTutorial: Bool { self == .tutorial }
}

// MARK: - Colors

enum HypothesisColors {
    // Vivid identity palette — saturated brights so each hypothesis has a
    // distinct pattern-recognition anchor on the work surface. Coral, teal,
    // indigo, mustard, violet, emerald, cherry.
    static let all = ["FF6B47", "2DD4BF", "818CF8", "FBBF24", "C084FC", "34D399", "F87171"]
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
