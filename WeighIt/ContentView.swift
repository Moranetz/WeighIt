import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]
    @State private var activeBoard: Board?
    @State private var showBoardList = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Theme.bg.ignoresSafeArea()
                RadialGradient(colors: [Theme.accent.opacity(0.05), .clear],
                               center: .top, startRadius: 0, endRadius: 400)
                    .ignoresSafeArea()
                RadialGradient(colors: [Theme.positive.opacity(0.03), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 300)
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
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Weigh It")
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
