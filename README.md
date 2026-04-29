# Reckon

> *(formerly Weigh It — internal repo name unchanged)*

[![iOS CI](https://github.com/melmarion/WeighIt/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/melmarion/WeighIt/actions/workflows/ios-ci.yml)
[![Android CI](https://github.com/melmarion/WeighIt/actions/workflows/android-ci.yml/badge.svg)](https://github.com/melmarion/WeighIt/actions/workflows/android-ci.yml)
[![Status](https://img.shields.io/badge/status-native%20ios%20app-0f172a)](https://github.com/melmarion/WeighIt)

**Reckon forces structure on murky thinking.**

Question → competing hypotheses → weighted evidence → bias warnings → diagnostic view.

You don't decide better because you wrote more — you decide better because you couldn't avoid comparing.

Native iOS (SwiftUI + SwiftData) and Android (Kotlin + Jetpack Compose + Room) implementations of Analysis of Competing Hypotheses, the technique CIA analysts use to keep wishful thinking out of conclusions. Instead of keeping a messy grid in notes or a spreadsheet, you build a live board where every piece of evidence is rated against every hypothesis — and the structure of the matrix makes the gaps visible.

## Why this matters

Most decision tools let you write a long pros/cons list and call it analysis. That doesn't help — you can rationalize anything in prose.

Reckon's value is what it WON'T let you do:

- **You can't avoid the comparison.** The matrix forces every piece of evidence against every hypothesis. Empty cells are visibly incomplete (dashed border, pulsing dot) — your eye is pulled to gaps you'd otherwise skip.
- **You can't avoid your bias.** When a column has 3+ ratings all in the same direction, an inline warning appears at the column header — *"No disconfirming evidence yet."* The bias surfaces while you rate, not gated behind a "results" toggle.
- **You see the verdict shifting in real time.** Each hypothesis column has a thin score bar that fills as you accumulate evidence. The leading hypothesis emerges visually, not just calculated at the end.

The interesting layer is the decision model:

- hypotheses and evidence are first-class domain objects, not loose text blobs
- per-cell ratings (Strong yes / Supports / Irrelevant / Contradicts / Strong no) preserve nuance instead of collapsing everything to yes/no
- weighted evidence (credibility × relevance) so trustworthy + relevant data carries more weight
- diagnostic evidence detection — which evidence actually distinguishes between hypotheses (vs. supports/contradicts everything equally)
- bias warnings inline at the column level
- structured exports to markdown for journaling and review

## Running Locally

1. Open [WeighIt.xcodeproj](/Users/infiniteupside/WeighIt/WeighIt.xcodeproj) in Xcode 15 or later.
2. Select an iPhone simulator running iOS 17.0 or later.
3. Build and run.

The project already contains the app target and SwiftData configuration. No manual project scaffolding is required.

## Running The Android App

1. Open [android-app](/Users/infiniteupside/WeighIt/android-app) in Android Studio Jellyfish or later.
2. Let Gradle sync the wrapper project.
3. Run the `app` configuration on an Android 8.0+ emulator or device.

The Android app mirrors the native decision workflow: multiple boards, Room persistence, evidence matrix scoring, notes, rule-outs, diagnostics, bias checks, and markdown export.

## Proof Signals

- native Xcode project checked in at [WeighIt.xcodeproj](/Users/infiniteupside/WeighIt/WeighIt.xcodeproj)
- native Android Studio / Gradle project checked in at [android-app](/Users/infiniteupside/WeighIt/android-app)
- GitHub Actions build workflow at [.github/workflows/ios-ci.yml](/Users/infiniteupside/WeighIt/.github/workflows/ios-ci.yml)
- GitHub Actions Android workflow at [.github/workflows/android-ci.yml](/Users/infiniteupside/WeighIt/.github/workflows/android-ci.yml)
- source, prototype, and docs layers are all visible in one repo

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
| `android-app/app/src/main/java/io/github/melmarion/weighit/android/ui/WeighItApp.kt` | Compose UI, board editor, matrix, results, notes, board sheet |
| `android-app/app/src/main/java/io/github/melmarion/weighit/android/data/Models.kt` | Android domain model, scoring, diagnostics, export logic |
| `android-app/app/src/main/java/io/github/melmarion/weighit/android/data/WeighItRepository.kt` | Room-backed persistence and board mutations |

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
- **Android native** — Jetpack Compose, Room, Material 3, markdown export intent

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
- Android Studio Jellyfish+
- Android SDK 35
