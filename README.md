# Weigh It

[![iOS CI](https://github.com/melmarion/WeighIt/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/melmarion/WeighIt/actions/workflows/ios-ci.yml)
[![Android CI](https://github.com/melmarion/WeighIt/actions/workflows/android-ci.yml/badge.svg)](https://github.com/melmarion/WeighIt/actions/workflows/android-ci.yml)
[![Status](https://img.shields.io/badge/status-native%20ios%20app-0f172a)](https://github.com/melmarion/WeighIt)

Native decision-analysis app with:

- iOS 17 build in SwiftUI + SwiftData
- Android build in Kotlin + Jetpack Compose + Room

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
