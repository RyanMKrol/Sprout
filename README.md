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

The project is **generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen)** from
`project.yml` — the `.xcodeproj` is not committed. (Mirrors the sibling `../basket` project.)

- **Requirements:** macOS + Xcode (iOS Simulator) and `brew install xcodegen`. An iOS simulator
  runtime matching the SDK (else `xcodebuild test` fails — `xcodebuild -downloadPlatform iOS`).
- **Build / run / screenshot:** `./build_run.sh` — regenerate → build → install → launch →
  save `screenshots/latest.png`. Open in Xcode with `xcodegen generate && open Sprout.xcodeproj`.
- **Definition of Done (run locally — there is no remote CI):**
  ```sh
  ./build_run.sh                                   # ** BUILD SUCCEEDED ** + screenshot
  xcodegen generate && xcodebuild test -project Sprout.xcodeproj -scheme Sprout \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  ```
  No swiftlint/swiftformat and no XCUITest — behaviour is verified by XCTest + the screenshot.

> Until **T001** lands, `Sources/` and the generated `.xcodeproj` don't exist yet — the commands
> above are the target state that T001 establishes (following `project.yml` / `build_run.sh`).

## Implementation status

See [`TASKS.md`](./TASKS.md) for the full specs. Status (the checkbox in `TASKS.md` is the
source of truth):

| Task | Status | Description |
|---|---|---|
| T001 | ✅ done | Project scaffold + local Definition of Done passes on an empty build |
| T002 | ✅ done | Verification baseline — demo-seed hook + screenshot convention |
| T003 | ✅ done | Domain model types (Plant, CareProfile, CheckIn) |
| T004 | ✅ done | Care database loader, schema & validator |
| T005 | ✅ done | SwiftData persistence + repository protocol |
| T006 | ✅ done | My Plants list + empty state |
| T007 | ✅ done | Add / Edit Plant (species picker) |
| T008 | ✅ done | Plant Detail + check-in history |
| T009 | ✅ done | Schedule engine — effective interval (pure) |
| T010 | ✅ done | Adaptive update from a check-in (pure) |
| T011 | ✅ done | Check-in flow UI (soil / leaves / watered → recommendation) |
| T012 | ✅ done | "Why this schedule" explanation text |
| T013 | ✅ done | Local watering notifications |
| T014 | ✅ done | Settings — preferred reminder time, units, weather toggle |
| T015 | ✅ done | Weather provider (Open-Meteo + CoreLocation) |
| T016 | ✅ done | Feed weather into the schedule engine |
| T101–T130 | ✅ done (30/30) | Care DB build-out — 30 batches × 10 researched UK houseplants (305 species) |
| T131 | ✅ done | Care database complete — 305 species, deduped & validated, provenance complete |
| T200 | ✅ done | Final review — [`docs/REVIEW.md`](./docs/REVIEW.md) key-decision packet for sign-off |
| T201 | ✅ done | Photo blob on the model (`Plant`/`StoredPlant.photoData` + `PlantPhoto` encode) |
| T202 | ✅ done | Random nickname provider (curated English names) |
| T203 | ✅ done | Basket add view model (multi-add + auto-naming) |
| T204 | ✅ done | Basket add view + "+" rewiring (basket replaces single-add) |
| T205 | ✅ done | Camera seam + stub + camera permission |
| T206 | ✅ done | Photo-capture coordinator (sequential capture) |
| T207 | ✅ done | Camera overlay view + AVFoundation capture |
| T208 | ✅ done | Wire post-create photo flow ("take photos?" → camera) |
| T209 | ✅ done | Balanced ~300-name pool (gender-split) |
| T210 | ✅ done | Room domain model + environment factor (sunlight × humidity) |
| T211 | ✅ done | Room persistence + plant→room link |
| T212 | ✅ done | Drive schedule from rooms; retire phone weather |
| T213 | ✅ done | Rooms UI + room assignment |
| T214 | ✅ done | Tile home page (Plants/Rooms/Water) + show photos |
| T215 | ✅ done | Guided watering walkthrough (two modes) |
| T216 | ✅ done | Developer settings — delete all plants & rooms |
| T217 | ✅ done | Rename "Name" field label to "Nickname" |
| T218 | ✅ done | My Plants swipe-to-delete + edit rework (drop species) |
| T219 | ✅ done | Edit flow: change a plant's photo |
| T220 | ✅ done | Room light model — direct/indirect sliders → brightness + tooltips |
| T221 | ✅ done | Room-first "Add plants" flow (choose/add room, then add its plants) |
| T222 | ✅ done | Square-tile home redesign + split Water / Full check-in |
| T223 | ✅ done | Fix multi-add photo prompt (decline + connected presentation) |
| T224 | ✅ done | Care DB audit + source research → gap list |
| T225 | ✅ done | Care DB gap-fill batch 1 — 15 species (incl. Monstera adansonii) → 320 |
| T226 | ✅ done | Care DB gap-fill batch 2 — 15 species (Tier 2 cultivars) → 335 |
| T227 | ✅ done | Care DB final audit — 335 unique, deduped, validated, 1:1 provenance |

**Post-backlog polish** (off-loop, device-tested): fixed the camera black screen and the guided-watering
black screen (both were two-`fullScreenCover` conflicts — now single `item:`-driven covers); added
satisfying sequential-capture feedback (flash + green pulse + slide); the Plant Detail screen now has a
larger photo/header, an **Edit** button, and a tappable **manual schedule override** (water-in-N-days
wheel); species and room names display in proper case; and the leaf-glyph placeholder uses a vibrant
per-plant colour instead of a uniform blue.

The loop runs **unattended — no mid-loop gates**; the final task **T200** compiles a review
packet ([`docs/REVIEW.md`](./docs/REVIEW.md)) of the key decisions for you to check and tweak once
everything is built. Full specs + the per-batch plant categories are in [`TASKS.md`](./TASKS.md) and
[`docs/research/uk-houseplants.md`](./docs/research/uk-houseplants.md).
