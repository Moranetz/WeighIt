# Weigh It — SwiftUI + SwiftData

A native iOS 17 thinking tool based on the CIA's Analysis of Competing Hypotheses technique.

## Xcode Setup

1. **Create a new Xcode project:**
   - File → New → Project
   - Choose **App** (iOS)
   - Product Name: `WeighIt`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** ← important
   - Uncheck "Include Tests" unless you want them

2. **Replace the generated files:**
   - Delete the auto-generated `ContentView.swift`, `Item.swift`, and `WeighItApp.swift`
   - Drag all 9 `.swift` files from the `WeighIt/` folder into your Xcode project
   - Make sure "Copy items if needed" is checked

3. **Set deployment target:**
   - Select your project in the navigator
   - Under General → Minimum Deployments → **iOS 17.0**

4. **Build & Run** (⌘R)

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

## Features

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

## Requirements

- Xcode 15+
- iOS 17.0+
- Swift 5.9+
