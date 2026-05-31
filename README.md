# Sprout 🌱

An iOS app for tracking plant care. You add the plants you own; Sprout proposes a **per-plant
watering schedule** seeded from a bundled database of common UK houseplants, then personalises
it from quick **check-ins** — a soil knuckle-test (dry / moist / wet) and a glance at the
leaves (drooping?) — and from local weather (hot/cold spells). It reminds you when a plant is
due, at the time of day you prefer (e.g. an evening when you're likely home), and always
explains *why* the schedule is what it is.

> **How this project is built:** Sprout is developed by the autonomous **Ralph build harness**
> — a single sequential loop that builds the [`TASKS.md`](./TASKS.md) backlog one
> fully-verified task at a time. Verification is **local-only** (no GitHub CI): each task must
> pass the local format/lint/test suite and, for UI work, an iOS-Simulator screenshot check
> before the loop integrates it. See [`docs/HARNESS.md`](./docs/HARNESS.md) for the design and
> [`CLAUDE.md`](./CLAUDE.md) for the working conventions.

## Planned features

- Add and manage the plants you own.
- A **bundled local database** of ~300 common UK houseplants seeding each plant's watering needs.
- Quick **check-ins** (soil moisture knuckle-test + leaf droop) that adapt the schedule and give
  an in-the-moment indication ("skip — soil's still wet, back in 3 days" / "water now").
- A per-plant watering schedule that personalises over time and adjusts for **local weather**.
- Watering-due **notifications**, delivered at a user-preferred time window.
- A plain-language **"why this schedule"** explanation on every plant.
- Settings for notification timing, units, and weather.

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

See [`TASKS.md`](./TASKS.md) for the full specs. Status (the checkbox in `TASKS.md` is the
source of truth):

| Task | Status | Description |
|---|---|---|
| T001 | ⏳ pending | Project scaffold + local Definition of Done passes on an empty build |
| T002 | ⏳ pending | Verification harness — XCUITest target + simulator screenshot helper |
| T003 | ⏳ pending | Domain model types (Plant, CareProfile, CheckIn) |
| T004 | ⏳ pending | Care database loader, schema & validator |
| T005 | ⏳ pending | SwiftData persistence + repository protocol |
| T006 | ⏳ pending | My Plants list + empty state |
| T007 | ⏳ pending | Add / Edit Plant (species picker) |
| T008 | ⏳ pending | Plant Detail + check-in history |
| T009 | ⏳ pending | Schedule engine — effective interval (pure) |
| T010 | ⏳ pending | Adaptive update from a check-in (pure) |
| T011 | ⏳ pending | Check-in flow UI (soil / leaves / watered) |
| T012 | ⏳ pending | "Why this schedule" explanation text |
| T013 | ⏳ pending | Local watering notifications |
| T014 | ⏳ pending | Settings — preferred reminder time, units, weather toggle |
| T015 | ⏳ pending | Weather provider (Open-Meteo + CoreLocation) |
| T016 | ⏳ pending | Feed weather into the schedule engine |
| T101–T130 | ⏳ pending | Care DB build-out — 30 batches × 10 researched UK houseplants (→ ~300) |
| T131 | ⏳ pending | Care database complete — deduped & reviewed |
| T200 | ⏳ pending | Final review — compile key decisions for sign-off |

The loop runs **unattended — no mid-loop gates**; the final task **T200** compiles a review
packet (`docs/REVIEW.md`) of the key decisions for you to check and tweak once everything is
built. Full specs + the per-batch plant categories are in [`TASKS.md`](./TASKS.md) and
[`docs/research/uk-houseplants.md`](./docs/research/uk-houseplants.md).
