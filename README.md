# Sprout 🌱

An iOS app for tracking plant care. You add the plants you own, report how each one looks
(healthy or unhealthy), and Sprout proposes and maintains a **per-plant watering schedule** —
adapting it from general watering guidance, local weather (hot/cold spells), and the health
you report — then reminds you when a plant is due, at the time of day you prefer (e.g. an
evening when you're likely home).

> **How this project is built:** Sprout is developed by the autonomous **Ralph build harness**
> — a single sequential loop that builds the [`TASKS.md`](./TASKS.md) backlog one
> fully-verified task at a time. Verification is **local-only** (no GitHub CI): each task must
> pass the local format/lint/test suite and, for UI work, an iOS-Simulator screenshot check
> before the loop integrates it. See [`docs/HARNESS.md`](./docs/HARNESS.md) for the design and
> [`CLAUDE.md`](./CLAUDE.md) for the working conventions.

## Planned features

- Add and manage the plants you own.
- Report each plant's health (healthy / unhealthy).
- A suggested watering schedule per plant, derived from general care guidance.
- Schedule adaptation from observed health and **local weather**.
- Watering-due **notifications**, delivered at a user-preferred time window.
- Settings for notification timing and per-plant preferences.

## Building & running

- **Requirements:** macOS with Xcode (iOS Simulator), plus `swiftlint` and `swiftformat`
  (`brew install swiftlint swiftformat`).
- **Open:** `open Sprout.xcodeproj` and run the `Sprout` scheme on an iOS Simulator.
- **Definition of Done (run locally — there is no remote CI):**
  ```sh
  swiftformat --lint .
  swiftlint --strict
  xcodebuild test -project Sprout.xcodeproj -scheme Sprout \
    -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
  ```
- **Empirical UI check:** boot the Simulator, install/launch the app, and capture a screenshot
  with `xcrun simctl io booted screenshot out.png` — see `CLAUDE.md` "Tooling notes".

> Until **T001** lands, `Sprout.xcodeproj` does not exist yet — the commands above are the
> target state that T001 establishes.

## Implementation status

| Task | Status | Description |
|---|---|---|
| T001 | ⏳ pending | Project scaffold + local Definition of Done passes on an empty build |

_The backlog beyond T001 is still being drafted — run `/ralph-loop-add-to-backlog` to grow it._
