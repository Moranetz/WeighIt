# ux-audit — WeighIt
Kind: **ios+web**  ·  Swift files: 11  ·  Web files: 1  ·  LoC: 5,882

Findings: 0 BLOCKER · 2 HIGH · 2 MEDIUM · 1 LOW

## Findings

- **[HIGH] VIBE-1**: Emoji-as-icon (19 occurrences) (instrument-register collision)
  Emoji reads as 'didn't have art.' Replace with bespoke typographic treatment, SF Symbols (semantic), or commissioned illustration.
  - prototypes/ach-board.jsx:7 (💚)
  - prototypes/ach-board.jsx:8 (👍)
  - prototypes/ach-board.jsx:9 (🤷)
  - prototypes/ach-board.jsx:10 (👎)
  - prototypes/ach-board.jsx:11 (🚫) (+14 more)
  Reference: UX/vibecoded_ui_smell_test §3 + memory: vibecoded_to_bespoke_10_moves

- **[HIGH] VIBE-3**: Marketing-scale headlines in app surfaces (6) (instrument-register collision)
  30pt+ headlines belong on landing pages, not in-app screens. Drop straight into content.
  - WeighIt/BoardView.swift:700 (size 84)
  - WeighIt/ContentView.swift:464 (size 64)
  - WeighIt/ContentView.swift:474 (size 38)
  - WeighIt/ContentView.swift:535 (size 56)
  - WeighIt/ContentView.swift:1494 (size 44) (+1 more)
  Reference: UX/10_TYPOGRAPHY_DAILY_USE

- **[MEDIUM] TYPE-RAMP**: Type ramp sprawl — 18 distinct font sizes
  Doc 10 prescribes 3–4 tier ramp (e.g. 13/15/17/22 or 11/13/17/96). Sprawl reads as un-designed. Consolidate to a Typography.swift token set.
  - size 9: WeighIt/BoardView.swift:395
  - size 10: WeighIt/BoardView.swift:154
  - size 11: WeighIt/BoardView.swift:132
  - size 8: WeighIt/BoardView.swift:158
  - size 13: WeighIt/BoardView.swift:317 (+1 more)
  Reference: UX/10_TYPOGRAPHY_DAILY_USE

- **[MEDIUM] VIBE-2**: Color flood — 1 file(s) with 6+ distinct hex literals
  Pinterest-tutorial card kit. Color should be a thin hairline accent, not a flood. Move palette to one Colors.swift / tokens.css file.
  - prototypes/ach-board.jsx (28 distinct hex colors)
  Reference: UX/1_DESIGN_SYSTEM_PROMPT §1 + §11 + UX/8_BIOPHILIA

- **[LOW] VIBE-7**: SwiftUI Lego stack signal — generic chrome density
  NavigationLink + ultraThinMaterial + RoundedRectangle.stroke + chevron + Capsule.fill stacked = vibecoded. Commit to a register (Criterion / NYT Mag / Vanity Fair / Pitchfork) and lean.
  - WeighIt/ContentView.swift (signal density 7)
  Reference: UX/vibecoded_ui_smell_test §7
