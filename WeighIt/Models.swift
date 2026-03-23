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

    var iconName: String {
        switch self {
        case .stronglySupports: "heart.circle.fill"
        case .supports: "hand.thumbsup.fill"
        case .irrelevant: "minus.circle"
        case .contradicts: "hand.thumbsdown.fill"
        case .stronglyContradicts: "xmark.octagon.fill"
        }
    }

    var label: String {
        switch self {
        case .stronglySupports: "Strong yes"
        case .supports: "Supports"
        case .irrelevant: "Irrelevant"
        case .contradicts: "Contradicts"
        case .stronglyContradicts: "Strong no"
        }
    }

    var shortLabel: String {
        switch self {
        case .stronglySupports: "strongly supports"
        case .supports: "supports"
        case .irrelevant: "irrelevant"
        case .contradicts: "contradicts"
        case .stronglyContradicts: "strongly contradicts"
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

    init(name: String = "", colorHex: String = "EF8B6E", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.isRuledOut = false
        self.sortOrder = sortOrder
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

    @Relationship(deleteRule: .cascade) var hypotheses: [Hypothesis]
    @Relationship(deleteRule: .cascade) var evidences: [Evidence]
    @Relationship(deleteRule: .cascade) var cellRatings: [CellRating]

    init(question: String = "", isExample: Bool = false) {
        self.id = UUID()
        self.question = question
        self.conclusion = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.hypotheses = []
        self.evidences = []
        self.cellRatings = []

        if isExample {
            setupExample()
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

    var rankedHypotheses: [(hypothesis: Hypothesis, score: Int)] {
        activeHypotheses
            .compactMap { h in score(for: h).map { (h, $0) } }
            .sorted { $0.score > $1.score }
    }

    var maxAbsScore: Int {
        let scores = activeHypotheses.compactMap { score(for: $0) }
        return scores.map { abs($0) }.max() ?? 1
    }

    var totalCells: Int { activeHypotheses.count * evidences.count }

    var filledCells: Int {
        cellRatings.filter { cell in
            cell.ratingValue != nil &&
            !hypotheses.first(where: { $0.id == cell.hypothesisID })!.isRuledOut
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
            let ratings = evidences.compactMap { rating(evidenceID: $0.id, hypothesisID: h.id) }
            if ratings.count > 2 && ratings.allSatisfy({ $0 == .stronglySupports || $0 == .supports }) {
                warnings.append("Everything supports \"\(h.name.isEmpty ? "one explanation" : h.name)\" — are you seeing what you want to see?")
            }
        }
        if evidences.count < 3 { warnings.append("Only a few data points. Could you be missing something?") }
        return warnings
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

    private func setupExample() {
        question = "Why did our latest product launch underperform?"
        let colors = HypothesisColors.all

        let h1 = Hypothesis(name: "Marketing didn't reach the right audience", colorHex: colors[0], sortOrder: 0)
        let h2 = Hypothesis(name: "The product has usability issues", colorHex: colors[1], sortOrder: 1)
        let h3 = Hypothesis(name: "Pricing is too high for the market", colorHex: colors[2], sortOrder: 2)
        hypotheses = [h1, h2, h3]

        let e1 = Evidence(text: "Social media impressions were up 40%", credibility: .high, relevance: .high, sortOrder: 0)
        let e2 = Evidence(text: "Support tickets doubled in the first week", credibility: .high, relevance: .high, sortOrder: 1)
        let e3 = Evidence(text: "Competitors priced 20% lower", credibility: .medium, relevance: .high, sortOrder: 2)
        let e4 = Evidence(text: "Users who finished onboarding had great retention", credibility: .medium, relevance: .medium, sortOrder: 3)
        evidences = [e1, e2, e3, e4]

        cellRatings = [
            CellRating(evidenceID: e1.id, hypothesisID: h1.id, rating: .contradicts, note: "Impressions up = marketing DID reach people"),
            CellRating(evidenceID: e2.id, hypothesisID: h2.id, rating: .stronglySupports, note: "Support tickets = confused users"),
            CellRating(evidenceID: e3.id, hypothesisID: h3.id, rating: .stronglySupports),
            CellRating(evidenceID: e3.id, hypothesisID: h1.id, rating: .irrelevant),
            CellRating(evidenceID: e4.id, hypothesisID: h2.id, rating: .contradicts, note: "Good retention after onboarding → maybe onboarding issue, not product"),
        ]
    }
}

// MARK: - Colors

enum HypothesisColors {
    static let all = ["EF8B6E", "5CC4B8", "7E9BE0", "E8C47A", "C490D4", "6EC4A0", "D4746A"]
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
