import SwiftUI

// MARK: - Hypothesis Row

struct HypothesisRow: View {
    @Bindable var hypothesis: Hypothesis
    let canDelete: Bool
    var showPriorSlider: Bool = false
    let onDelete: () -> Void
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    @State private var starPulse = false
    @State private var falsifierExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
        mainRow
        if showPriorSlider {
            priorSlider
                .transition(.opacity)
        }
        if falsifierExpanded {
            falsifierField
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
        }
    }

    private var mainRow: some View {
        HStack(spacing: 14) {
            // The star — a glowing point that breathes with its hypothesis.
            // When ruled out, the star is dimmed (visually "dimmed star").
            ZStack {
                Circle()
                    .fill(hypothesis.color.opacity(hypothesis.isRuledOut ? 0 : 0.25))
                    .frame(width: 38, height: 38)
                    .blur(radius: 8)
                    .scaleEffect(starPulse ? 1.05 : 0.95)
                Image(systemName: hypothesis.isRuledOut ? "star.slash" : "star.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(hypothesis.color)
                    .shadow(color: hypothesis.isRuledOut ? .clear : hypothesis.color.opacity(0.6), radius: 6)
            }
            .frame(width: 32)
            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: starPulse)
            .onAppear { starPulse = true }

            if hypothesis.isRuledOut {
                Text(hypothesis.name.isEmpty ? "Star" : hypothesis.name)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .strikethrough()
            } else {
                TextField("Name this star…", text: $hypothesis.name, axis: .vertical)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1...2)
            }

            Spacer()

            // Falsifier toggle — opens the "what would prove this wrong?" field
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    falsifierExpanded.toggle()
                }
            } label: {
                Image(systemName: hypothesis.falsifier.isEmpty
                      ? "questionmark.bubble"
                      : "questionmark.bubble.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(hypothesis.falsifier.isEmpty
                                     ? Theme.textDim
                                     : Theme.accent)
            }

            Button {
                haptic.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    hypothesis.isRuledOut.toggle()
                }
            } label: {
                Image(systemName: hypothesis.isRuledOut ? "sparkles" : "moon.stars")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(hypothesis.isRuledOut ? Theme.positive : Theme.negative)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        (hypothesis.isRuledOut ? Theme.positive : Theme.negative).opacity(0.1),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(
                        (hypothesis.isRuledOut ? Theme.positive : Theme.negative).opacity(0.2),
                        lineWidth: 1
                    ))
            }

            if canDelete {
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background {
            ZStack {
                // Subtle vignette tinted with the star's color so each row reads as
                // its own pocket of sky around its star.
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.025))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            hypothesis.color.opacity(hypothesis.isRuledOut ? 0 : 0.10),
                            Color.clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        hypothesis.color.opacity(hypothesis.isRuledOut ? 0.06 : 0.18),
                        lineWidth: 1
                    )
            }
        }
        .opacity(hypothesis.isRuledOut ? 0.55 : 1)
    }

    /// Prior probability slider — shown only when strict Bayes mode is on. Forces
    /// users to think about base rates BEFORE adding evidence. Default value of 0
    /// signals "use uniform prior"; any nonzero value is treated as user-set and
    /// normalized at compute time across active hypotheses.
    private var priorSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("PRIOR")
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(Theme.accent.opacity(0.8))
                Spacer()
                Text(hypothesis.priorProbability < 0.001
                     ? "auto"
                     : "\(Int(hypothesis.priorProbability * 100))% (rel.)")
                    .font(.system(size: 9, weight: .heavy))
                    .fontDesign(.rounded)
                    .foregroundStyle(Theme.textDim)
            }
            Slider(
                value: $hypothesis.priorProbability,
                in: 0...1,
                step: 0.05
            )
            .tint(hypothesis.color)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    /// Pre-commitment falsifier field — expands below the main row when toggled.
    /// Asks "what observation would prove this hypothesis wrong?" — locking the
    /// answer at hypothesis-creation time so later evidence can be checked against it.
    private var falsifierField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("WHAT WOULD FALSIFY THIS?")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(Theme.accent.opacity(0.85))
            }
            .padding(.top, 10)

            TextField("e.g. \"If we see X, this is wrong.\"", text: $hypothesis.falsifier, axis: .vertical)
                .font(.caption)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1...3)
                .padding(10)
                .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.accent.opacity(0.18), lineWidth: 1)
                )

            Text("Locking a falsifier up front is the structural difference between reasoning and rationalization.")
                .font(.system(size: 10))
                .italic()
                .foregroundStyle(Theme.textDim)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, 14)
    }
}

// MARK: - Evidence Row

struct EvidenceRow: View {
    @Bindable var evidence: Evidence
    let index: Int
    let canDelete: Bool
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Reorder + observation index — like a numbered telescope log entry
            VStack(spacing: 4) {
                Button { onMoveUp() } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isFirst ? Theme.textMuted : Theme.textDim)
                }
                .disabled(isFirst)

                Text("№\(index + 1)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(0.5)

                Button { onMoveDown() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isLast ? Theme.textMuted : Theme.textDim)
                }
                .disabled(isLast)
            }
            .frame(width: 24)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Something you've observed…", text: $evidence.text, axis: .vertical)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1...3)

                HStack(spacing: 10) {
                    WeightPicker(label: "sky", kind: .sky, value: Binding(
                        get: { evidence.credWeight },
                        set: { evidence.credibility = $0.rawValue }
                    ))
                    WeightPicker(label: "view", kind: .sight, value: Binding(
                        get: { evidence.relWeight },
                        set: { evidence.relevance = $0.rawValue }
                    ))
                }
            }

            Spacer(minLength: 0)

            if canDelete {
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(Theme.textDim)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.022))
                // Tiny twinkle in the corner — observation log entry asterism
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.border.opacity(0.7), lineWidth: 1)
            }
        }
    }
}

// MARK: - Weight Picker

struct WeightPicker: View {
    enum Kind { case sky, sight, raw }
    let label: String
    let kind: Kind
    @Binding var value: Weight

    init(label: String, kind: Kind = .raw, value: Binding<Weight>) {
        self.label = label
        self.kind = kind
        self._value = value
    }

    private func displayLabel(for w: Weight) -> String {
        switch kind {
        case .sky:   return w.skyLabel
        case .sight: return w.sightLabel
        case .raw:   return w.label
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            ForEach(Weight.allCases, id: \.self) { w in
                Button {
                    withAnimation(.spring(response: 0.2)) { value = w }
                } label: {
                    Text(displayLabel(for: w))
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(value == w ? Theme.accent : Theme.textDim)
                        .frame(width: 44, height: 20)
                        .background(
                            value == w ? Theme.accent.opacity(0.15) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Note Panel

struct NotePanel: View {
    let evidence: Evidence
    let hypothesis: Hypothesis
    let note: String
    let onUpdate: (String) -> Void
    let onClose: () -> Void
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .foregroundStyle(Theme.accent)
                    Text(evidence.text.isEmpty ? "Evidence" : evidence.text)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textSecondary)
                    Text("→")
                        .foregroundStyle(Theme.textDim)
                    Text(hypothesis.name.isEmpty ? "Explanation" : hypothesis.name)
                        .fontWeight(.semibold)
                        .foregroundStyle(hypothesis.color)
                }
                .font(.caption)
                .lineLimit(1)

                Spacer()

                Button { onClose() } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }
            }

            TextField("Why did you rate it this way?", text: $draft, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2...5)
                .padding(12)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
                .onChange(of: draft) { _, newVal in
                    onUpdate(newVal)
                }
        }
        .padding(14)
        .background(Theme.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.15), lineWidth: 1)
        )
        .onAppear { draft = note }
    }
}
