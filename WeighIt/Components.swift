import SwiftUI

// MARK: - Hypothesis Row

struct HypothesisRow: View {
    @Bindable var hypothesis: Hypothesis
    let canDelete: Bool
    let onDelete: () -> Void
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(hypothesis.color)
                .frame(width: 12, height: 12)
                .shadow(color: hypothesis.isRuledOut ? .clear : hypothesis.color.opacity(0.4), radius: 6)

            if hypothesis.isRuledOut {
                Text(hypothesis.name.isEmpty ? "Explanation" : hypothesis.name)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .strikethrough()
            } else {
                TextField("Explanation…", text: $hypothesis.name, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1...2)
            }

            Spacer()

            Button {
                haptic.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    hypothesis.isRuledOut.toggle()
                }
            } label: {
                Label(hypothesis.isRuledOut ? "undo" : "rule out",
                      systemImage: hypothesis.isRuledOut ? "arrow.uturn.backward" : "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(hypothesis.isRuledOut ? Theme.positive : Theme.negative)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (hypothesis.isRuledOut ? Theme.positive : Theme.negative).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder((hypothesis.isRuledOut ? Theme.positive : Theme.negative).opacity(0.2), lineWidth: 1)
                    )
            }

            if canDelete {
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
        .padding(12)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .opacity(hypothesis.isRuledOut ? 0.5 : 1)
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
        HStack(spacing: 8) {
            // Reorder
            VStack(spacing: 0) {
                Button { onMoveUp() } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isFirst ? Theme.textMuted : Theme.textDim)
                }
                .disabled(isFirst)
                Button { onMoveDown() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isLast ? Theme.textMuted : Theme.textDim)
                }
                .disabled(isLast)
            }

            Text("\(index + 1)")
                .font(.caption2)
                .fontWeight(.heavy)
                .foregroundStyle(Theme.textMuted)
                .frame(width: 18)

            TextField("Something you've observed…", text: $evidence.text, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1...3)

            VStack(alignment: .trailing, spacing: 4) {
                WeightPicker(label: "trust", value: Binding(
                    get: { evidence.credWeight },
                    set: { evidence.credibility = $0.rawValue }
                ))
                WeightPicker(label: "rel", value: Binding(
                    get: { evidence.relWeight },
                    set: { evidence.relevance = $0.rawValue }
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
        .padding(12)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Weight Picker

struct WeightPicker: View {
    let label: String
    @Binding var value: Weight

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            ForEach(Weight.allCases, id: \.self) { w in
                Button {
                    withAnimation(.spring(response: 0.2)) { value = w }
                } label: {
                    Text(w.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(value == w ? Theme.accent : Theme.textDim)
                        .frame(width: 28, height: 20)
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
