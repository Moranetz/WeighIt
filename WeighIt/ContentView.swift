import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Board.updatedAt, order: .reverse) private var allBoards: [Board]
    @State private var activeBoard: Board?
    @State private var showBoardList = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @State private var showExamplePicker = false
    @State private var showAISeed = false

    // Working boards (exclude templates from the main list / picker logic)
    private var boards: [Board] { allBoards.filter { !$0.isTemplate } }
    private var templates: [Board] { allBoards.filter { $0.isTemplate } }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background — deep night sky. Layered: solid base, faint nebula glow,
                // subtle starfield, atmospheric color washes. Reinforces the observatory
                // metaphor at the perceptual level.
                Color(hex: "0A0A12").ignoresSafeArea()
                RadialGradient(colors: [Color(hex: "1A1426").opacity(0.6), .clear],
                               center: .topLeading, startRadius: 0, endRadius: 600)
                    .ignoresSafeArea()
                RadialGradient(colors: [Color(hex: "0F2436").opacity(0.5), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 500)
                    .ignoresSafeArea()
                StarfieldView(starCount: 90, seed: 47)
                    .ignoresSafeArea()
                RadialGradient(colors: [Theme.accent.opacity(0.04), .clear],
                               center: .top, startRadius: 0, endRadius: 400)
                    .ignoresSafeArea()

                if let board = activeBoard {
                    BoardView(board: board)
                } else {
                    ProgressView()
                        .tint(Theme.accent)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showBoardList = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "scale.3d")
                                .font(.title2)
                                .foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Reckon")
                                    .font(.headline)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(activeBoard?.displayName ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textDim)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if let board = activeBoard {
                            ProgressRingView(percent: board.completionPercent)
                                .frame(width: 32, height: 32)
                        }

                        Menu {
                            Button("New blank board", systemImage: "plus") { createNewBoard() }
                            Button("Load example…", systemImage: "books.vertical") { showExamplePicker = true }
                            if let board = activeBoard, !board.isTemplate {
                                Button("Save as template", systemImage: "tray.and.arrow.down") { saveAsTemplate(board) }
                            }
                            Divider()
                            if let board = activeBoard {
                                ShareLink(item: board.exportMarkdown()) {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .toolbarBackground(Theme.bg.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showBoardList) {
            BoardListSheet(
                boards: boards,
                activeBoard: $activeBoard,
                onNew: createNewBoard,
                onDelete: deleteBoard
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if !boards.isEmpty {
                activeBoard = boards.first
            }
            if !hasSeenOnboarding {
                showOnboarding = true
            } else if boards.isEmpty {
                // User completed onboarding previously but has no boards — show the picker
                showExamplePicker = true
            }
        }
        .onChange(of: showOnboarding) { _, newValue in
            // When onboarding closes for the first time and no boards exist, present
            // the example picker so the user lands on something tailored, not blank.
            if !newValue && boards.isEmpty {
                showExamplePicker = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showExamplePicker) {
            ExamplePickerView(
                onPick: { archetype in
                    let board = Board(archetype: archetype)
                    context.insert(board)
                    activeBoard = board
                    showExamplePicker = false
                },
                onSkip: {
                    let board = Board()
                    context.insert(board)
                    activeBoard = board
                    showExamplePicker = false
                },
                onPickTemplate: { template in
                    let board = newBoardFromTemplate(template)
                    context.insert(board)
                    activeBoard = board
                    showExamplePicker = false
                },
                onAISeed: {
                    showExamplePicker = false
                    // Defer slightly so the sheet dismissal animation can finish
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAISeed = true
                    }
                },
                templates: templates
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAISeed) {
            AISeedView { board in
                context.insert(board)
                activeBoard = board
                showAISeed = false
            } onCancel: {
                showAISeed = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func newBoardFromTemplate(_ template: Board) -> Board {
        let board = Board(question: "")
        board.hypotheses.removeAll()
        board.evidences.removeAll()
        board.cellRatings.removeAll()
        for h in template.sortedHypotheses {
            board.hypotheses.append(Hypothesis(
                name: h.name,
                colorHex: h.colorHex,
                sortOrder: h.sortOrder,
                falsifier: h.falsifier
            ))
        }
        // One blank evidence slot to invite a first observation
        board.evidences.append(Evidence(sortOrder: 0))
        return board
    }

    private func createNewBoard() {
        let board = Board()
        context.insert(board)
        activeBoard = board
        showBoardList = false
    }

    private func deleteBoard(_ board: Board) {
        let wasActive = board.id == activeBoard?.id
        context.delete(board)
        if wasActive {
            activeBoard = boards.first(where: { $0.id != board.id })
        }
    }

    /// Save a copy of the current board as a reusable template — preserves the
    /// hypothesis structure (and falsifiers) but strips the question, evidence,
    /// ratings, conclusion, and calibration. Templates appear above the starter
    /// archetypes in the example picker.
    private func saveAsTemplate(_ source: Board) {
        let template = Board(question: "")
        template.isTemplate = true
        template.templateName = source.question.isEmpty ? "Untitled template" : String(source.question.prefix(40))
        // Replace blank scaffolding with copies of the source hypotheses
        template.hypotheses.removeAll()
        template.evidences.removeAll()
        template.cellRatings.removeAll()
        for h in source.sortedHypotheses {
            template.hypotheses.append(Hypothesis(
                name: h.name,
                colorHex: h.colorHex,
                sortOrder: h.sortOrder,
                falsifier: h.falsifier
            ))
        }
        context.insert(template)
    }
}

// MARK: - Board List Sheet

struct BoardListSheet: View {
    let boards: [Board]
    @Binding var activeBoard: Board?
    let onNew: () -> Void
    let onDelete: (Board) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(boards) { board in
                    Button {
                        activeBoard = board
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(board.displayName)
                                    .font(.subheadline)
                                    .fontWeight(board.id == activeBoard?.id ? .bold : .medium)
                                    .foregroundStyle(board.id == activeBoard?.id ? Theme.accent : Theme.textPrimary)
                                Text(board.updatedAt.formatted(.relative(presentation: .named)))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textDim)
                            }
                            Spacer()
                            if board.id == activeBoard?.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                            Text("\(board.completionPercent)%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(board.completionPercent == 100 ? Theme.positive : Theme.textDim)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if boards.count > 1 {
                            Button(role: .destructive) { onDelete(board) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                Button { onNew() } label: {
                    Label("New Board", systemImage: "plus.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
            }
            .navigationTitle("Your Boards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let percent: Int
    private var done: Bool { percent >= 100 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.border, lineWidth: 3)
            Circle()
                .trim(from: 0, to: Double(percent) / 100)
                .stroke(done ? Theme.positive : Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: percent)
            Text("\(percent)")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(done ? Theme.positive : Theme.accent)
        }
    }
}

// MARK: - Onboarding
// First-launch tutorial. Three pages teaching the cognitive premise + the metaphor:
//   1) The promise — why most decision tools fail (rationalization-friendly)
//   2) The metaphor — stars (hypotheses), observations (evidence), sightlines (cells)
//   3) The cognitive twist — refutation-first scoring, Pareidolia Alert
// User can skip after page 1; on completion, dismiss permanently.

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page = 0
    @State private var pageStarPulse = false
    private let totalPages = 3

    var body: some View {
        ZStack {
            // Same starfield + night sky as the main app
            Color(hex: "0A0A12").ignoresSafeArea()
            RadialGradient(colors: [Color(hex: "1A1426").opacity(0.7), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            RadialGradient(colors: [Color(hex: "0F2436").opacity(0.6), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
            StarfieldView(starCount: 140, seed: 12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button — only after page 0
                HStack {
                    Spacer()
                    Button("Skip") { complete() }
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .opacity(page == 0 ? 0 : 1)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                Spacer()

                TabView(selection: $page) {
                    pageOne.tag(0)
                    pageTwo.tag(1)
                    pageThree.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 480)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Theme.accent : Theme.textMuted)
                            .frame(width: 6, height: 6)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)

                // CTA
                Button {
                    if page < totalPages - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            page += 1
                        }
                    } else {
                        complete()
                    }
                } label: {
                    Text(page == totalPages - 1 ? "Begin observing" : "Next")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "0A0A12"))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func complete() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            isPresented = false
        }
    }

    // MARK: - Pages

    /// Page 1: The premise. Why most decision tools don't help, and what's different here.
    private var pageOne: some View {
        VStack(spacing: 32) {
            // Hero: a single bright star
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)
                Image(systemName: "star.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.accent)
                    .shadow(color: Theme.accent.opacity(0.7), radius: pageStarPulse ? 20 : 10)
                    .scaleEffect(pageStarPulse ? 1.06 : 1)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: pageStarPulse)
            }
            .onAppear { pageStarPulse = true }

            VStack(spacing: 16) {
                Text("Reckon")
                    .font(.system(size: 38, weight: .heavy))
                    .fontDesign(.rounded)
                    .foregroundStyle(Theme.textPrimary)

                Text("Forces structure on murky thinking.")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Most decision tools let you write a long pros-and-cons list and call it analysis. You can rationalize anything in prose.\n\nReckon makes you compare every piece of evidence against every hypothesis — and ranks them by what hasn't been knocked down, not by what has the most support.")
                    .font(.body)
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
    }

    /// Page 2: The metaphor. Stars, observations, sightlines.
    private var pageTwo: some View {
        VStack(spacing: 24) {
            // Mini star chart visual
            HStack(spacing: 32) {
                miniStar(color: Color(hex: "EF8B6E"), label: "Hypothesis A", scale: 1.0)
                miniStar(color: Color(hex: "5CC4B8"), label: "Hypothesis B", scale: 0.85)
                miniStar(color: Color(hex: "7E9BE0"), label: "Hypothesis C", scale: 0.7)
            }
            .padding(.top, 12)

            VStack(spacing: 12) {
                Text("A star map for decisions")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(Theme.textPrimary)

                VStack(alignment: .leading, spacing: 14) {
                    metaphorRow(icon: "star", title: "Hypotheses are stars", body: "Each candidate explanation. Brightness = stability under observation.")
                    metaphorRow(icon: "binoculars", title: "Evidence is observations", body: "Each piece you log. Credibility × relevance is the viewing condition.")
                    metaphorRow(icon: "scope", title: "Cells are sightlines", body: "Each cell rates one observation against one star. Empty cells pulse — you haven't pointed the telescope there yet.")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
    }

    /// Page 3: The cognitive twist. Refutation-first + Pareidolia Alert.
    private var pageThree: some View {
        VStack(spacing: 24) {
            // Hero: a star with a refutation badge
            ZStack {
                Circle()
                    .fill(Color(hex: "5CC4B8").opacity(0.15))
                    .frame(width: 130, height: 130)
                    .blur(radius: 25)
                Image(systemName: "star.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color(hex: "5CC4B8"))
                    .shadow(color: Color(hex: "5CC4B8").opacity(0.6), radius: 12)
                // Refutation badge
                Text("0")
                    .font(.system(size: 14, weight: .heavy))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color(hex: "F0EBE6"))
                    .frame(width: 26, height: 26)
                    .background(Color(hex: "D4746A"), in: Circle())
                    .offset(x: 28, y: -28)
            }
            .frame(height: 130)

            VStack(spacing: 10) {
                Text("Steadiness, not popularity")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(Theme.textPrimary)

                Text("Heuer's ACH technique ranks hypotheses by FEWEST refutations — not most support. The right answer is the star nothing has dimmed.")
                    .font(.body)
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)
            }

            // Pareidolia callout
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.warning)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pareidolia Alert")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.warning)
                    Text("If a column fills with same-direction ratings, Reckon warns you you're seeing a face in the stars. Find an observation that breaks the pattern.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .lineSpacing(2)
                }
            }
            .padding(14)
            .background(Theme.warning.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.warning.opacity(0.18), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            // Closing tagline
            Text("The brightest star isn't always the right one.\nThe steadiest one is.")
                .font(.subheadline)
                .italic()
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Subviews

    private func miniStar(color: Color, label: String, scale: CGFloat) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 28 * scale))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.6), radius: 8 * scale)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.textDim)
        }
        .opacity(0.5 + (scale * 0.5))
    }

    private func metaphorRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.textPrimary)
                Text(body)
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Example Picker
// Shown after onboarding (and accessible from the toolbar Menu) so users can land on
// a board that matches their domain instead of a generic founder example. ACH is
// universal but the FRAMING isn't — a shortseller doesn't want to learn the method
// through a startup launch postmortem.

struct ExamplePickerView: View {
    let onPick: (ExampleArchetype) -> Void
    let onSkip: () -> Void
    let onPickTemplate: ((Board) -> Void)?
    let onAISeed: (() -> Void)?
    let templates: [Board]

    init(
        onPick: @escaping (ExampleArchetype) -> Void,
        onSkip: @escaping () -> Void,
        onPickTemplate: ((Board) -> Void)? = nil,
        onAISeed: (() -> Void)? = nil,
        templates: [Board] = []
    ) {
        self.onPick = onPick
        self.onSkip = onSkip
        self.onPickTemplate = onPickTemplate
        self.onAISeed = onAISeed
        self.templates = templates
    }

    var body: some View {
        ZStack {
            // Same observatory backdrop as onboarding — continuity matters.
            Color(hex: "0A0A12").ignoresSafeArea()
            RadialGradient(colors: [Color(hex: "1A1426").opacity(0.6), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            RadialGradient(colors: [Color(hex: "0F2436").opacity(0.5), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
            StarfieldView(starCount: 110, seed: 23)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Pick a starter example")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.heavy)
                            .foregroundStyle(Theme.textPrimary)

                        Text("ACH works the same in every domain — but the framing matters.\nPick the lens closest to yours. You can always switch later.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 28)

                    // AI seed card — full-width promoted CTA at the top
                    if let onAISeed {
                        AISeedCard(onTap: onAISeed)
                            .padding(.horizontal, 18)
                    }

                    // Saved user templates (if any)
                    if !templates.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("YOUR TEMPLATES")
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(1.4)
                                .foregroundStyle(Theme.textDim)
                                .padding(.horizontal, 22)
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                                spacing: 14
                            ) {
                                ForEach(templates) { tpl in
                                    TemplateCard(template: tpl) {
                                        onPickTemplate?(tpl)
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }

                    if !templates.isEmpty {
                        Text("STARTER ARCHETYPES")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.4)
                            .foregroundStyle(Theme.textDim)
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                    }

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(ExampleArchetype.allCases) { archetype in
                            ArchetypeCard(archetype: archetype) {
                                onPick(archetype)
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    Button { onSkip() } label: {
                        Text("Start with a blank board instead")
                            .font(.subheadline)
                            .underline()
                            .foregroundStyle(Theme.textDim)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct ArchetypeCard: View {
    let archetype: ExampleArchetype
    let onTap: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: archetype.accentHex).opacity(0.15))
                        .frame(width: 52, height: 52)
                        .blur(radius: 6)
                    Image(systemName: archetype.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(hex: archetype.accentHex))
                }
                .frame(height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(archetype.title)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.textPrimary)
                    Text(archetype.subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .italic()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.55))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color(hex: archetype.accentHex).opacity(0.10),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(hex: archetype.accentHex).opacity(0.30), lineWidth: 1)
                }
                .shadow(color: Color(hex: archetype.accentHex).opacity(pressed ? 0.35 : 0.18), radius: pressed ? 14 : 8, y: 3)
            }
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 80, perform: {}) { isPressing in
            pressed = isPressing
        }
    }
}

// MARK: - AI Seed Card

private struct AISeedCard: View {
    let onTap: () -> Void
    @State private var pressed = false
    @State private var sparklePulse = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.18))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .scaleEffect(sparklePulse ? 1.1 : 0.95)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: sparklePulse)
                }
                .frame(width: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Describe your situation")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.heavy)
                            .foregroundStyle(Theme.textPrimary)
                        Text("BETA")
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(Color(hex: "0A0A12"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Theme.accent, in: Capsule())
                    }
                    Text("Type a paragraph; on-device AI proposes hypotheses and observations.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Theme.accent.opacity(0.18), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.42), lineWidth: 1)
                }
                .shadow(color: Theme.accent.opacity(pressed ? 0.4 : 0.22), radius: pressed ? 16 : 10, y: 3)
            }
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 80, perform: {}) { isPressing in
            pressed = isPressing
        }
        .onAppear { sparklePulse = true }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: Board
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "tray.full")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.templateName.isEmpty ? "Saved template" : template.templateName)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    Text("\(template.hypotheses.count) hypotheses pre-loaded")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .italic()
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.55))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Seed View
// On-device LLM (Apple FoundationModels, iOS 26+) takes a paragraph describing a
// situation and proposes 3-4 hypotheses + 4-5 weighted observations + initial cell
// ratings. The user reviews + confirms — what they get is an editable starter board,
// not an authoritative verdict.
//
// Privacy: nothing leaves the device. The model runs locally on Apple Intelligence
// hardware. On older devices the feature shows an unavailable state instead of
// silently degrading.

import FoundationModels

struct AISeedView: View {
    let onAccept: (Board) -> Void
    let onCancel: () -> Void

    @State private var prompt: String = ""
    @State private var isThinking = false
    @State private var result: Board?
    @State private var errorMessage: String?
    @FocusState private var promptFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "0A0A12").ignoresSafeArea()
            RadialGradient(colors: [Color(hex: "1A1426").opacity(0.55), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            StarfieldView(starCount: 110, seed: 91)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                    Text("Describe your situation")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(Theme.textDim)
                }
                .padding(.top, 12)

                Text("A paragraph or two. Mention the question, what you've already considered, and any evidence on hand. The model proposes a starting matrix — you'll edit before saving.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .lineSpacing(2)

                TextEditor(text: $prompt)
                    .font(.system(.body, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Theme.textPrimary)
                    .focused($promptFocused)
                    .padding(12)
                    .frame(minHeight: 160, maxHeight: 240)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(promptFocused ? Theme.accent.opacity(0.5) : Theme.border, lineWidth: 1)
                    )

                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(Theme.negative)
                }

                if let board = result {
                    seedPreview(board: board)
                }

                Spacer()

                primaryButton
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 22)
        }
        .preferredColorScheme(.dark)
    }

    private var primaryButton: some View {
        Button {
            if let board = result {
                onAccept(board)
            } else {
                Task { await runSeed() }
            }
        } label: {
            HStack(spacing: 8) {
                if isThinking {
                    ProgressView().tint(Color(hex: "0A0A12"))
                } else {
                    Image(systemName: result == nil ? "sparkles" : "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                Text(isThinking ? "Reading the sky…" : (result == nil ? "Generate matrix" : "Use this board"))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color(hex: "0A0A12"))
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.accentGradient, in: Capsule())
            .opacity(prompt.trimmingCharacters(in: .whitespaces).count < 10 && result == nil ? 0.4 : 1)
        }
        .disabled(prompt.trimmingCharacters(in: .whitespaces).count < 10 && result == nil)
    }

    private func seedPreview(board: Board) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROPOSED MATRIX")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Theme.accent.opacity(0.85))
            Text(board.question.isEmpty ? "(no question)" : board.question)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.textPrimary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(board.sortedHypotheses) { h in
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(h.color)
                        Text(h.name)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            Text("\(board.evidences.count) observations · \(board.cellRatings.count) initial sightlines")
                .font(.caption2)
                .foregroundStyle(Theme.textDim)
        }
        .padding(14)
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.accent.opacity(0.18), lineWidth: 1)
        )
    }

    @MainActor
    private func runSeed() async {
        errorMessage = nil
        result = nil
        isThinking = true
        defer { isThinking = false }

        guard #available(iOS 26.0, *) else {
            errorMessage = "On-device AI requires iOS 26 or later."
            return
        }

        let availability = SystemLanguageModel.default.availability
        if case .unavailable(let reason) = availability {
            errorMessage = "Apple Intelligence isn't available on this device (\(reason)). Try a different starter example."
            return
        }

        let session = LanguageModelSession(instructions: """
        You help users build a Reckon matrix using the Analysis of Competing Hypotheses (ACH) method.
        Given a user's situation, output STRICT JSON in this shape and nothing else:
        {
          "question": "the central question to investigate",
          "hypotheses": ["3 to 4 distinct competing explanations"],
          "evidence": [
            {
              "text": "one piece of observable evidence",
              "credibility": "high" | "medium" | "low",
              "relevance":   "high" | "medium" | "low"
            }
          ],
          "ratings": [
            {
              "evidence": <0-based index>,
              "hypothesis": <0-based index>,
              "rating": "stronglySupports" | "supports" | "irrelevant" | "contradicts" | "stronglyContradicts"
            }
          ]
        }
        Rules:
        - Hypotheses MUST be genuinely competing, not minor variations.
        - Include at least one hypothesis that runs counter to what the user seems to expect.
        - Evidence should be observable, specific, and short.
        - Provide ratings that demonstrate refutation-first thinking — not all positive.
        - 3-4 hypotheses, 4-5 evidence, 6-10 ratings.
        - Output ONLY the JSON. No prose.
        """)

        do {
            let response = try await session.respond(to: "Situation:\n\n\(prompt)")
            guard let board = parseSeedJSON(response.content) else {
                errorMessage = "The model returned something I couldn't parse. Try rephrasing your paragraph."
                return
            }
            result = board
        } catch {
            errorMessage = "Couldn't generate a matrix: \(error.localizedDescription)"
        }
    }

    /// Parse the LLM's strict JSON response into a Board. Tolerant of stray text
    /// before/after the JSON block.
    private func parseSeedJSON(_ raw: String) -> Board? {
        // Find the first { and the matching last }
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}") else { return nil }
        let jsonText = String(raw[start...end])
        guard let data = jsonText.data(using: .utf8) else { return nil }

        struct SeedJSON: Decodable {
            let question: String
            let hypotheses: [String]
            let evidence: [SeedEvidence]
            let ratings: [SeedRating]
        }
        struct SeedEvidence: Decodable {
            let text: String
            let credibility: String
            let relevance: String
        }
        struct SeedRating: Decodable {
            let evidence: Int
            let hypothesis: Int
            let rating: String
        }

        guard let seed = try? JSONDecoder().decode(SeedJSON.self, from: data) else { return nil }

        let board = Board(question: seed.question)
        board.hypotheses.removeAll()
        board.evidences.removeAll()
        board.cellRatings.removeAll()

        let colors = HypothesisColors.all
        var hypArr: [Hypothesis] = []
        for (i, name) in seed.hypotheses.prefix(7).enumerated() {
            let h = Hypothesis(name: name, colorHex: colors[i % colors.count], sortOrder: i)
            board.hypotheses.append(h)
            hypArr.append(h)
        }

        var evArr: [Evidence] = []
        for (i, ev) in seed.evidence.prefix(8).enumerated() {
            let cred = parseWeight(ev.credibility) ?? .medium
            let rel = parseWeight(ev.relevance) ?? .medium
            let e = Evidence(text: ev.text, credibility: cred, relevance: rel, sortOrder: i)
            board.evidences.append(e)
            evArr.append(e)
        }

        for r in seed.ratings {
            guard r.evidence >= 0, r.evidence < evArr.count,
                  r.hypothesis >= 0, r.hypothesis < hypArr.count,
                  let rating = Rating(rawValue: r.rating) ?? Rating.named(r.rating)
            else { continue }
            board.cellRatings.append(CellRating(
                evidenceID: evArr[r.evidence].id,
                hypothesisID: hypArr[r.hypothesis].id,
                rating: rating
            ))
        }

        return board
    }

    private func parseWeight(_ s: String) -> Weight? {
        switch s.lowercased() {
        case "high", "h": return .high
        case "medium", "med", "m": return .medium
        case "low", "l": return .low
        default: return nil
        }
    }
}

// Convenience: parse Rating by enum case name (the JSON uses case names, not raw values).
extension Rating {
    static func named(_ s: String) -> Rating? {
        switch s {
        case "stronglySupports":    return .stronglySupports
        case "supports":            return .supports
        case "irrelevant":          return .irrelevant
        case "contradicts":         return .contradicts
        case "stronglyContradicts": return .stronglyContradicts
        default: return nil
        }
    }
}
