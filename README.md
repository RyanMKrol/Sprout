# Sprout 🌱

An iOS app for tracking plant care. You add the plants you own; Sprout proposes a **per-plant
watering schedule** seeded from a bundled database of ~335 common UK houseplants, then
personalises it from quick **check-ins** — a soil knuckle-test (dry / moist / wet) and a glance
at the leaves (drooping?) — and from each plant's **room environment** (sunlight × humidity).
It reminds you when plants are due with a **once-a-day digest notification** at the time of day
you prefer, and always explains *why* the schedule is what it is.

## Features

- **My Plants** — add plants room-first (choose/add a room, then add its plants in a multi-add
  "basket" flow), with photos captured in a guided sequential camera flow, random nicknames,
  swipe-to-delete, and per-plant detail with check-in history.
- **Rooms** — each room carries a light model (direct/indirect sliders) and humidity; the room's
  environment drives its plants' schedules. Adding a room offers a wheel of common presets
  (Living Room, Kitchen, Bathroom, …) with typical defaults.
- **Care database** — 335 researched UK houseplant species (deduped, validated, with provenance)
  seeding each plant's watering needs.
- **Check-ins & adaptive schedule** — quick soil + leaf check-ins adapt each plant's interval;
  a plain-language "why this schedule" explanation is always available, plus a manual
  water-in-N-days override.
- **Guided watering** — a walkthrough of today's due plants (water-only or full check-in).
- **Notifications** — a daily "N plants need watering today" digest at your chosen hour, with
  first-run onboarding, an off-state indicator, and a developer test button.
- **Home** — a status-aware greeting over a bento layout of gradient tiles, with a due-count
  badge and a pulsing Water tile when plants are due.

## Building & running

The project is **generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen)** from
`project.yml` — the `.xcodeproj` is not committed.

- **Requirements:** macOS + Xcode 26.x and `brew install xcodegen swiftlint jq`. An iOS simulator
  runtime matching the SDK (else `xcodebuild test` fails — `xcodebuild -downloadPlatform iOS`).
- **Build / run / screenshot:** `./build_run.sh` — regenerate → build → install → launch →
  save `screenshots/latest.png`. Open in Xcode with `xcodegen generate && open Sprout.xcodeproj`.
- **Verify (mirrors CI):**
  ```sh
  swiftlint lint
  ./tools/loop_sim.sh                              # ensure the dedicated "Sprout-Claude" simulator
  xcodegen generate && xcodebuild test -project Sprout.xcodeproj -scheme Sprout \
    -destination 'platform=iOS Simulator,name=Sprout-Claude'
  ```
  Behaviour is verified by XCTest + the `build_run.sh` screenshot; CI (GitHub Actions, macOS
  runner) runs the same lint + test suite on every push.

## Building this project

This project is built by an autonomous implementation harness. To add work and run it, see
[`.harness/README.md`](.harness/README.md). Project conventions are in [`CLAUDE.md`](./CLAUDE.md);
the v1 design docs and research live in [`docs/designs/`](./docs/designs/) and
[`docs/research/`](./docs/research/), with historical trade-offs in
[`docs/LIMITATIONS.md`](./docs/LIMITATIONS.md).
