# Weigh It

Native iOS 17 decision-analysis app built with SwiftUI and SwiftData.

`WeighIt` translates the CIA's Analysis of Competing Hypotheses method into a tactile mobile tool. Instead of keeping a messy grid in notes or a spreadsheet, the user builds a live board of hypotheses, evidence, ratings, exclusions, and notes inside a purpose-built interface that computes signal strength as the board fills in.

## Why This Repo Matters

The value here is not just CRUD around a list of ideas. The interesting layer is the decision model:

- hypotheses and evidence are first-class domain objects, not loose text blobs
- per-cell ratings preserve nuance instead of collapsing everything to yes/no
- exclusion and diagnostic evidence logic help the user see what actually changes the ranking
- completion state, confetti, export, and bias warnings turn an analytical method into an app people will actually use

This repo is a good example of taking a dense cognitive framework and mechanizing it into an iOS-native workflow.

## Running Locally

1. Open [WeighIt.xcodeproj](/Users/infiniteupside/WeighIt/WeighIt.xcodeproj) in Xcode 15 or later.
2. Select an iPhone simulator running iOS 17.0 or later.
3. Build and run.

The project already contains the app target and SwiftData configuration. No manual project scaffolding is required.

## File Structure

| File | Purpose |
|------|---------|
| `WeighItApp.swift` | App entry point, SwiftData container config |
| `Models.swift` | SwiftData models: Board, Hypothesis, Evidence, CellRating, Rating enum, Weight enum |
| `Theme.swift` | Color palette, card style modifier, shared design tokens |
| `ContentView.swift` | Root view, board switching, navigation, progress ring |
| `BoardView.swift` | Main scrolling board: question, hypotheses, evidence, matrix, results toggle, conclusion |
| `Components.swift` | HypothesisRow, EvidenceRow, WeightPicker, NotePanel |
| `MatrixView.swift` | Matrix grid with horizontal scroll, cells, rating popover picker |
| `ResultsView.swift` | Ranked results, diagnostic evidence, bias warnings, animated scores |
| `ConfettiView.swift` | Celebration animation on 100% matrix completion |

## Product Surface

- **SwiftData persistence** — boards save automatically, survive app restarts
- **Multiple boards** — create, switch, delete boards from the header menu
- **Undo** — built-in via SwiftUI's UndoManager
- **Popover rating picker** — tap a cell, pick from a menu (no cycling)
- **Per-cell notes** — record your reasoning on every rating
- **Rule out hypotheses** — strike through explanations, exclude from scoring
- **Reorderable evidence** — move items up/down
- **Diagnostic analysis** — identifies which evidence actually helps you decide
- **Bias warnings** — flags confirmation bias patterns
- **Confetti** — celebration on 100% completion with haptic feedback
- **Export** — share as markdown via share sheet
- **Dark mode** — warm espresso palette, glass cards, glow accents
- **iOS 17 native** — @Observable, SwiftData, .contentTransition, sensory feedback

## What To Look At First

- [ContentView.swift](/Users/infiniteupside/WeighIt/WeighIt/ContentView.swift)
- [BoardView.swift](/Users/infiniteupside/WeighIt/WeighIt/BoardView.swift)
- [MatrixView.swift](/Users/infiniteupside/WeighIt/WeighIt/MatrixView.swift)
- [ResultsView.swift](/Users/infiniteupside/WeighIt/WeighIt/ResultsView.swift)
- [Models.swift](/Users/infiniteupside/WeighIt/WeighIt/Models.swift)

## Requirements

- Xcode 15+
- iOS 17.0+
- Swift 5.9+
