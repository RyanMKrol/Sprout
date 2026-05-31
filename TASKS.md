# TASKS — implementation backlog

This is the execution backlog for **Sprout**. Each task is atomic, ordered by dependency, and
bounded by explicit acceptance criteria so it is achievable by a single build pass of the
pinned model. It is executed by a **single sequential loop** — the next eligible task, one at
a time — described in [`docs/HARNESS.md`](./docs/HARNESS.md).

See [`CLAUDE.md`](./CLAUDE.md) for the repo conventions (branch + self-merge, no PRs; docs in
lockstep) and [`docs/HARNESS.md`](./docs/HARNESS.md) for the autonomous build harness.

## How the loop works

The build harness is a **single sequential loop** — one `claude -p` per task, fresh context,
all durable state in the repo (this file's statuses, `worklog/`, git). The authoritative
design is [`docs/HARNESS.md`](./docs/HARNESS.md); this section is just how to *read this
file*. Each iteration the loop:

1. **Picks the next eligible task** — the first not-done task (per the Status index) whose
   `Depends on:` are all `done` **and merged into `main`**.
2. **Resumes, never restarts.** If a `tNNN` branch or uncommitted work exists from an
   interrupted attempt, it continues that — reads `worklog/TNNN.md`, inspects the working
   tree, and reconciles the delta against the task's `Done-when:` before coding.
3. **Implements only the outstanding delta**, within the task's `Scope:`, and verifies
   prerequisites are real (deps present in code, not just a ticked box).
4. **Passes the LOCAL Definition of Done** ([`docs/HARNESS.md`](./docs/HARNESS.md) §5): the
   project's format/lint/test plus the empirical simulator-screenshot check where the task's
   `Verify:` asks for it — flipping the index box and the `README.md` row in the **same
   commit**. (This project is local-only: `REQUIRE_CI=0`, no GitHub Actions.)
5. **Branches off `main`, pushes; the loop fast-forwards `main`** once the local DoD passes,
   and records the result. On failure it appends a `worklog/TNNN.md` entry (what failed, why,
   what's left) and stops.

Rules:
- **One task per iteration.** Do not batch.
- **Finish completely.** Never mark `done` with a failing `Done-when:` or partial scope.
- Tasks tagged **🔒 needs-human** need a one-time manual step (credentials, provisioning);
  author + validate as far as possible, then record `failed:blocked` — do **not** mark done.
  Tasks tagged **🚦 Gate** additionally need an explicit human review of the deliverable.

### Work log & retries

Loops must never spin forever burning tokens. The mechanics:

- **Status vocabulary:** `pending` → `done`, or `failed` (carries an **attempt count** and a
  **reason**). `failed` is written by the loop at runtime; the index/specs below start
  everything `pending`.
- **Per-task work log `worklog/TNNN.md`** (append-only): every attempt appends a dated entry —
  what it tried, what passed/failed, the reason/blocker, and what's left. **Read it before
  every (re)attempt.**
- **Failure taxonomy:**
  - `failed:soft` — transient (token/quota exhaustion, flaky network, partial progress
    checkpointed) → eligible for retry.
  - `failed:blocked` — hard blocker (🔒 needs-human, unmet/abandoned prerequisite, missing
    gate decision) → **not** retried; surface to the human.
- **Caps:** `MAX_ATTEMPTS` per task (default 3) of `failed:soft` → then `failed:blocked`. A
  global iteration/wall-clock cap bounds total spend (and naturally handles running out of
  tokens — `claude -p` simply can't run). Waiting on deps consumes no attempt.

---

## Execution order & gates

There are no tracks, waves, or parallel worktrees — the loop walks the backlog in
**dependency order**, one task at a time ([`docs/HARNESS.md`](./docs/HARNESS.md)). A task
becomes eligible once its `Depends on:` are merged into `main`.

**Gates (the loop must not skip them).** A task marked **🚦 Gate** needs its `Done-when:` met
**and** an explicit human review of the deliverable before any dependent task proceeds. A
task marked **🔒 needs-human** needs a one-time human step (credentials, provisioning, a live
go/no-go) and is recorded `failed:blocked`, never auto-completed.

---

## Status index

> The checkbox is the **only** source of done/not-done. Markers: **🚦 Gate** (a human reviews
> the deliverable before dependents proceed) · **🔒 needs-human** (one-time manual step).

**Phase 0 — Foundations**
- [ ] T001 Project scaffold + local Definition of Done passes on an empty build
- [ ] T002 Verification harness — XCUITest target + simulator screenshot helper 🚦 Gate

**Phase 1 — Domain & data**
- [ ] T003 Domain model types (Plant, CareProfile, CheckIn) — pure Swift
- [ ] T004 Load & validate the bundled ~300-plant UK care database
- [ ] T005 SwiftData persistence + repository protocol

**Phase 2 — Core screens**
- [ ] T006 My Plants list + empty state
- [ ] T007 Add / Edit Plant (species picker from care DB)
- [ ] T008 Plant Detail + check-in history

**Phase 3 — Check-ins & adaptive scheduling**
- [ ] T009 Schedule engine — effective interval (pure)
- [ ] T010 Adaptive update from a check-in (pure)
- [ ] T011 Check-in flow UI (soil / leaves / watered → recommendation) 🚦 Gate
- [ ] T012 "Why this schedule" explanation text

**Phase 4 — Reminders & settings**
- [ ] T013 Local watering notifications
- [ ] T014 Settings — preferred reminder time, units, weather toggle

**Phase 5 — Weather adaptation**
- [ ] T015 Weather provider (Open-Meteo + CoreLocation)
- [ ] T016 Feed weather into the schedule engine

---

## Tasks

> The data model, care-DB schema, and the scheduling/adaptation rules are specified in
> [`docs/designs/adaptive-watering.md`](./docs/designs/adaptive-watering.md) — tasks that build
> to it point at it via `Design:`. **Out of scope for this backlog:** running on a physical
> device / App Store distribution (needs a paid Apple Developer account + signing — a future
> 🔒 needs-human task). Everything here runs and verifies on the **iOS Simulator**.

### T001 — Project scaffold + local Definition of Done passes on an empty build
- **Depends on:** (none)
- **Scope:** `Sprout.xcodeproj`, `Sprout/` app sources, `SproutTests/`, `.swiftlint.yml`,
  `.swiftformat`, `README.md`
- **Verify:** simulator-screenshot
- **Do:** Create a minimal SwiftUI iOS app named **Sprout** as an Xcode project (deployment
  target **iOS 17.0**, for SwiftData in T005 — no persistence yet) with a `Sprout` app target
  and a `SproutTests` unit-test target containing one trivial passing test. Add baseline
  `.swiftlint.yml` and `.swiftformat` configs and make the sources pass `swiftformat --lint .`
  and `swiftlint --strict`. Confirm the test `-destination`
  (`platform=iOS Simulator,name=iPhone 17`) resolves against the local Xcode install; if not,
  pick a simulator that exists and update `CLAUDE.md`, `README.md`, and `docs/HARNESS.md` §5
  together. Empirically verify per the `Verify:` recipe in `CLAUDE.md`: boot the simulator,
  build/install/launch the app, capture `worklog/T001-verify.png`, and confirm the default
  SwiftUI screen renders.
- **Done-when:** `swiftformat --lint .`, `swiftlint --strict`, and `xcodebuild test` (iPhone 17
  simulator) all pass locally on a clean tree; the screenshot observation is recorded in
  `worklog/T001.md`; `README.md` documents how to open/build/run with the exact local DoD
  commands; the DoD commands in `docs/HARNESS.md` §5 match; the T001 index box and README
  status row are flipped to done in the same commit.

### T002 — Verification harness — XCUITest target + simulator screenshot helper 🚦 Gate
- **Depends on:** T001
- **Scope:** `SproutUITests/`, `scripts/shot.sh`, `CLAUDE.md`
- **Verify:** simulator-screenshot
- **Do:** Add a `SproutUITests` XCUITest target with a smoke test that launches the app,
  asserts the root screen's accessibility identifier exists, and saves a screenshot as a test
  attachment. Add `scripts/shot.sh` wrapping `xcrun simctl io booted screenshot` (booting the
  sim if needed) so any later task can capture `worklog/TNNN-verify.png` in one command.
- **Done-when:** `xcodebuild test` runs **both** the unit and UI test targets green on the
  iPhone 17 simulator; `scripts/shot.sh` produces a PNG the agent reads back; the
  XCUITest-plus-screenshot recipe is documented in `CLAUDE.md` for later tasks to reuse.
  **🚦 A human reviews that this verification approach is trustworthy before dependents build on it.**

### T003 — Domain model types (Plant, CareProfile, CheckIn) — pure Swift
- **Depends on:** T001
- **Scope:** `Sprout/Model/*.swift`, `SproutTests/Model*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Define pure value types — `Plant`, `CareProfile` (species, base/min/max interval,
  `moisture` preference), `CheckIn` (date, soil, leaves, watered), and the `SoilMoisture` /
  `LeafState` / `MoisturePreference` enums — with **no** SwiftUI/SwiftData imports.
- **Done-when:** the types compile, are `Codable`/`Equatable` where needed, and unit tests
  cover construction + invariants (e.g. `min ≤ base ≤ max`); the module imports no UI/persistence.

### T004 — Load & validate the bundled ~300-plant UK care database
- **Depends on:** T003
- **Scope:** `Sprout/Model/CareDatabase.swift`, `SproutTests/CareDatabase*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Wire up `Sprout/Resources/care_database.json` — the bundled ~300-plant UK dataset
  produced by the one-time research effort (provenance: `docs/research/uk-houseplants.md`) — with
  a loader that decodes it into `[CareProfile]` for the species picker, plus search/sort. The
  dataset file is committed to the repo before this task runs; **this task does not re-research it.**
- **Done-when:** the bundled JSON decodes into ~300 `CareProfile`s; unit tests assert the count is
  in range, spot-check several known species' intervals + moisture preferences, and verify **every**
  record satisfies `min ≤ base ≤ max` and a valid `moisture`; the picker can list/search them.

### T005 — SwiftData persistence + repository protocol
- **Depends on:** T003
- **Scope:** `Sprout/Persistence/*`, `SproutTests/Persistence*`
- **Do:** Add SwiftData `@Model` store types mapping the domain model, plus a
  `PlantRepository` protocol with a SwiftData implementation (CRUD for plants + appended
  check-ins). The UI/view-models depend on the **protocol**, not SwiftData directly.
- **Done-when:** an in-memory `ModelContainer` round-trips a plant with check-ins in
  integration tests; CRUD works; nothing outside this module imports SwiftData.

### T006 — My Plants list + empty state
- **Depends on:** T002, T005
- **Scope:** `Sprout/Views/PlantList*`, `Sprout/ViewModels/PlantList*`, `SproutUITests/*`
- **Verify:** simulator-screenshot
- **Do:** Build the home list from the repository — cards (name, species, next-due pill,
  water-drop indicator) and a first-run empty state — behind a testable view model.
- **Done-when:** the list renders persisted plants and the empty state; a XCUITest launches,
  asserts the empty state, and (seeded) asserts a card appears; `worklog/T006-verify.png` recorded.

### T007 — Add / Edit Plant (species picker from care DB)
- **Depends on:** T006, T004
- **Scope:** `Sprout/Views/PlantEdit*`, `Sprout/ViewModels/PlantEdit*`, `SproutUITests/*`
- **Verify:** simulator-screenshot
- **Do:** A form to add/edit a plant — nickname, species picked from the care DB (T004),
  location, pot size, optional photo — saved via the repository.
- **Done-when:** adding a plant persists it and it shows in the list; a XCUITest drives
  add → list-shows-it; screenshot recorded.

### T008 — Plant Detail + check-in history
- **Depends on:** T006
- **Scope:** `Sprout/Views/PlantDetail*`, `Sprout/ViewModels/PlantDetail*`, `SproutUITests/*`
- **Verify:** simulator-screenshot
- **Do:** A detail screen showing the plant, its current schedule (placeholder until T009),
  and a chronological check-in history, reachable from a list card.
- **Done-when:** tapping a card opens detail with the plant's data + history; a XCUITest
  navigates list → detail; screenshot recorded.

### T009 — Schedule engine — effective interval (pure)
- **Depends on:** T003
- **Scope:** `Sprout/Engine/Schedule*`, `SproutTests/Schedule*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Implement the pure effective-interval / next-due function
  (`base × weatherFactor × adj`, clamped to species `min`/`max`) with an **injected** clock and
  `weatherFactor` defaulting to `1.0`.
- **Done-when:** unit tests assert intervals + clamping across species and `adj` values; the
  function is pure (no I/O; "now" is injected).

### T010 — Adaptive update from a check-in (pure)
- **Depends on:** T009, T004
- **Scope:** `Sprout/Engine/Adapt*`, `SproutTests/Adapt*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Implement the pure check-in update returning `(newAdj, recommendation, didWater)` per
  the design's decision table — including early/on-time/late timing and the droopy overrides.
- **Done-when:** a unit-test table covers **every** row of the design table (incl.
  wet → skip+lengthen, dry-early → shorten, droopy+wet → lengthen + overwater indication) and the
  `[0.5, 2.0]` `adj` clamp; `recommendation` is a structured value, not a brittle string.

### T011 — Check-in flow UI (soil / leaves / watered → recommendation) 🚦 Gate
- **Depends on:** T008, T010, T005
- **Scope:** `Sprout/Views/CheckIn*`, `Sprout/ViewModels/CheckIn*`, `SproutUITests/*`
- **Verify:** simulator-screenshot
- **Do:** From a plant, run the check-in (soil `Dry/Moist/Wet`, leaves `Fine/Droopy`,
  watered?), persist the `CheckIn`, apply the adaptive update, and show the recommendation +
  updated next-due.
- **Done-when:** a due plant can be checked in; schedule/recommendation update **and** persist;
  a XCUITest drives a full check-in and asserts the next-due/recommendation changed; screenshot
  recorded. **🚦 A human reviews the core check-in UX before later phases build on it.**

### T012 — "Why this schedule" explanation text
- **Depends on:** T009, T008
- **Scope:** `Sprout/Engine/Explanation*`, `Sprout/Views/*`, `SproutTests/*`, `SproutUITests/*`
- **Verify:** simulator-screenshot
- **Do:** Build a plain-language explanation from the schedule inputs (base, weather, `adj`,
  last check-in) — e.g. *"every 9 days — shortened from 12 because it dried out early"* — shown
  on detail and summarised on the list pill.
- **Done-when:** a unit-tested builder maps inputs → sentence; detail shows it; screenshot recorded.

### T013 — Local watering notifications
- **Depends on:** T005
- **Scope:** `Sprout/Notifications/*`, `SproutTests/Notifications*`
- **Do:** A `NotificationScheduling` protocol + `UNUserNotificationCenter` implementation that
  schedules a per-plant watering reminder at the next-due date and reschedules on check-in;
  request authorization on first use.
- **Done-when:** integration tests with a **stub** center assert a reminder is
  scheduled/rescheduled for the right date; the app requests permission and degrades gracefully
  if denied (record the degraded behaviour in `docs/LIMITATIONS.md`).

### T014 — Settings — preferred reminder time, units, weather toggle
- **Depends on:** T013, T006
- **Scope:** `Sprout/Views/Settings*`, `Sprout/ViewModels/Settings*`, `SproutUITests/*`
- **Verify:** simulator-screenshot
- **Do:** A settings screen for the preferred reminder time-of-day window, °C/°F units, and a
  weather toggle; persisted and wired so reminders fire in the chosen window.
- **Done-when:** changing the preferred time changes scheduled reminders' time; settings persist
  across launches; a XCUITest toggles a setting; screenshot recorded.

### T015 — Weather provider (Open-Meteo + CoreLocation)
- **Depends on:** T001
- **Scope:** `Sprout/Weather/*`, `SproutTests/Weather*`, `SproutTests/Fixtures/openmeteo_*.json`
- **Do:** A `WeatherProviding` protocol + Open-Meteo implementation (no API key) decoding a
  forecast for a lat/lon, plus an **injectable** CoreLocation wrapper; handle permission and
  fall back to a neutral factor when location/forecast is unavailable.
- **Done-when:** decoding is unit-tested from a saved Open-Meteo **fixture**; location is
  injectable/stubbable; a denied/unavailable location yields `weatherFactor = 1.0`; **no network
  in tests**.

### T016 — Feed weather into the schedule engine
- **Depends on:** T015, T009, T012
- **Scope:** `Sprout/Engine/*`, `Sprout/Views/*`, `SproutTests/*`, `SproutUITests/*`
- **Verify:** simulator-screenshot
- **Do:** Map the forecast (temperature, plus precipitation for outdoor plants) to
  `weatherFactor` and feed it into the schedule engine; surface the weather influence in the
  "why" explanation (T012).
- **Done-when:** unit tests cover the forecast → factor mapping (hot → `<1`, cold → `>1`) and an
  end-to-end recompute; the explanation mentions weather when it moved the interval; screenshot
  recorded.
