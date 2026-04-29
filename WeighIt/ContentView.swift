import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]
    @State private var activeBoard: Board?
    @State private var showBoardList = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

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
                            Button("New Board", systemImage: "plus") { createNewBoard() }
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
            if boards.isEmpty {
                let example = Board(isExample: true)
                context.insert(example)
                activeBoard = example
            } else {
                activeBoard = boards.first
            }
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
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
