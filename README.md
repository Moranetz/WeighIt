# Reckon

> *(formerly Weigh It — internal repo name unchanged)*

[![iOS CI](https://github.com/melmarion/WeighIt/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/melmarion/WeighIt/actions/workflows/ios-ci.yml)
[![Android CI](https://github.com/melmarion/WeighIt/actions/workflows/android-ci.yml/badge.svg)](https://github.com/melmarion/WeighIt/actions/workflows/android-ci.yml)
[![Status](https://img.shields.io/badge/status-native%20ios%20app-0f172a)](https://github.com/melmarion/WeighIt)

**Reckon ranks hypotheses by what hasn't been knocked down — not by what has the most support.**

A star map for decisions. The brightest star isn't always the right one. The steadiest one is.

You don't decide better because you wrote more. You decide better because you couldn't avoid comparing.

Native iOS (SwiftUI + SwiftData) and Android (Kotlin + Jetpack Compose + Room) implementation of Heuer's Analysis of Competing Hypotheses, the technique CIA analysts use to keep wishful thinking out of conclusions. Reckon reframes ACH as an observatory: hypotheses are stars, evidence is observations, every cell in the matrix is a sightline you've pointed (or haven't).

## The metaphor

| | |
|---|---|
| **Hypotheses → stars** | Each candidate explanation. Brightness = stability under observation, not raw support. |
| **Evidence → observations** | Each piece of evidence is one observation in your log. Credibility × relevance is the viewing condition (clear / hazy / cloudy). |
| **Matrix cells → sightlines** | Each cell rates one observation against one star. Empty cells pulse softly — you haven't pointed the telescope there yet. |
| **Bias chip → Pareidolia Alert** | When a column fills with same-direction ratings, the app warns you you're seeing a face in the stars. Find an observation that breaks the pattern. |
| **Verdict → Constellation Confirmed** | The hypothesis whose star nothing has dimmed, surrounded by its confirming sightlines. |

## Why this matters

Most decision tools let you write a long pros-and-cons list and call it analysis. That doesn't help — you can rationalize anything in prose.

Reckon's value is what it WON'T let you do:

- **You can't avoid the comparison.** The matrix forces every observation against every star. Empty cells are visibly unobserved (dashed sightline, pulsing dot) — your eye is pulled to gaps you'd otherwise skip.
- **You can't avoid your bias.** When a column fills with same-direction ratings, an inline *Pareidolia Alert* appears at the column header. The bias surfaces while you rate, not gated behind a "results" toggle.
- **You see steadiness, not popularity.** Each hypothesis column shows two signals: a red refutation badge (count of contradicting evidence) and a support bar. They're shown distinctly so you stop conflating "lots of support" with "actually right."

## Refutation-first scoring

Heuer's ACH technique: rank hypotheses by **fewest refutations**, not most support. The right answer is the star nothing has dimmed.

This rewires what you hunt for. Most decision tools reward "find more evidence that supports your favorite" — which is exactly the cognitive habit ACH was designed to fight. Reckon ranks by:

1. Lowest refutation count (the primary signal — a hypothesis that nothing has knocked down)
2. Highest support count (tiebreaker)
3. Highest weighted score (final tiebreaker)

The "leading constellation" at the verdict is the steadiest one — not the brightest.

## The decision model

- hypotheses and evidence are first-class domain objects, not loose text blobs
- per-cell ratings (Strong yes / Supports / Irrelevant / Contradicts / Strong no) preserve nuance instead of collapsing everything to yes/no
- weighted evidence (credibility × relevance) so trustworthy + relevant data carries more weight
- diagnostic evidence detection — which evidence actually distinguishes between hypotheses (vs. supports/contradicts everything equally)
- inline Pareidolia Alerts at the column level — the app names the bias you're fighting
- refutation-count + support-count tracked separately, so users see the two signals as distinct
- structured exports to markdown for journaling and review

## Onboarding

First launch presents a 3-page tutorial in the same observatory aesthetic:
1. **The premise** — why most decision tools fail (rationalization-friendly)
2. **The metaphor** — stars, observations, sightlines
3. **The cognitive twist** — refutation-first scoring + Pareidolia Alert

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
