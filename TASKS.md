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
- This backlog uses **no** mid-loop review gates — it runs unattended. The one human checkpoint
  is the final review task **T200**, which prepares a key-decision packet for sign-off at the end.

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

**No mid-loop gates.** This backlog is built to run unattended for days, so it uses no review
stops — every key judgement is the builder's to make. They are all gathered for you to review at
the end by the final task **T200**, after which the backlog is complete and ready for your
sign-off and tweaks.

---

## Status index

> The checkbox is the **only** source of done/not-done. **This backlog runs unattended — no
> mid-loop gates.** The single human touchpoint is the final task **T200**, which compiles a
> review packet of the key decisions for you to check and tweak once everything is built.

**Phase 0 — Foundations**
- [x] T001 Project scaffold + local Definition of Done passes on an empty build
- [x] T002 Verification baseline — demo-seed hook + screenshot convention
**Phase 1 — Domain & data**
- [x] T003 Domain model types (Plant, CareProfile, CheckIn) — pure Swift
- [x] T004 Care database loader, schema & validator (data grows via T101–T130)
- [x] T005 SwiftData persistence + repository protocol

**Phase 2 — Core screens**
- [x] T006 My Plants list + empty state
- [x] T007 Add / Edit Plant (species picker from care DB)
- [x] T008 Plant Detail + check-in history

**Phase 3 — Check-ins & adaptive scheduling**
- [x] T009 Schedule engine — effective interval (pure)
- [x] T010 Adaptive update from a check-in (pure)
- [x] T011 Check-in flow UI (soil / leaves / watered → recommendation)
- [x] T012 "Why this schedule" explanation text

**Phase 4 — Reminders & settings**
- [x] T013 Local watering notifications
- [x] T014 Settings — preferred reminder time, units, weather toggle

**Phase 5 — Weather adaptation**
- [x] T015 Weather provider (Open-Meteo + CoreLocation)
- [x] T016 Feed weather into the schedule engine

**Phase 6 — Care database build-out (30 × 10 plants → ~300)**
> Each batch researches & adds 10 new unique UK houseplants per `docs/research/uk-houseplants.md`.
> Depends only on T004, so this whole phase can be moved earlier if you want the data sooner.
- [x] T101 Care DB batch 01 — add 10 UK houseplants (pothos / Epipremnum)
- [x] T102 Care DB batch 02 — add 10 UK houseplants (Philodendron)
- [x] T103 Care DB batch 03 — add 10 UK houseplants (Monstera / Syngonium)
- [x] T104 Care DB batch 04 — add 10 UK houseplants (Anthurium / Aglaonema / peace lily)
- [x] T105 Care DB batch 05 — add 10 UK houseplants (Alocasia / Caladium)
- [x] T106 Care DB batch 06 — add 10 UK houseplants (ZZ / Dracaena / Cordyline)
- [x] T107 Care DB batch 07 — add 10 UK houseplants (Sansevieria)
- [x] T108 Care DB batch 08 — add 10 UK houseplants (Echeveria / rosette succulents)
- [x] T109 Care DB batch 09 — add 10 UK houseplants (Crassula / Sedum / Sempervivum)
- [x] T110 Care DB batch 10 — add 10 UK houseplants (Haworthia / Gasteria / Aloe)
- [x] T111 Care DB batch 11 — add 10 UK houseplants (Kalanchoe / trailing succulents)
- [x] T112 Care DB batch 12 — add 10 UK houseplants (cacti I)
- [x] T113 Care DB batch 13 — add 10 UK houseplants (cacti II / Euphorbia)
- [x] T114 Care DB batch 14 — add 10 UK houseplants (ferns)
- [x] T115 Care DB batch 15 — add 10 UK houseplants (Calathea / Maranta)
- [x] T116 Care DB batch 16 — add 10 UK houseplants (Ctenanthe / Fittonia / Pilea)
- [x] T117 Care DB batch 17 — add 10 UK houseplants (Peperomia)
- [x] T118 Care DB batch 18 — add 10 UK houseplants (Begonia)
- [x] T119 Care DB batch 19 — add 10 UK houseplants (Tradescantia / Ceropegia)
- [x] T120 Care DB batch 20 — add 10 UK houseplants (spider plant / Aspidistra)
- [x] T121 Care DB batch 21 — add 10 UK houseplants (palms)
- [x] T122 Care DB batch 22 — add 10 UK houseplants (Ficus)
- [x] T123 Care DB batch 23 — add 10 UK houseplants (Schefflera / Dieffenbachia / Pachira)
- [x] T124 Care DB batch 24 — add 10 UK houseplants (Hoya)
- [x] T125 Care DB batch 25 — add 10 UK houseplants (orchids)
- [x] T126 Care DB batch 26 — add 10 UK houseplants (bromeliads / air plants)
- [x] T127 Care DB batch 27 — add 10 UK houseplants (flowering: African violet / cyclamen)
- [x] T128 Care DB batch 28 — add 10 UK houseplants (carnivorous)
- [x] T129 Care DB batch 29 — add 10 UK houseplants (herbs / edibles / citrus)
- [ ] T130 Care DB batch 30 — add 10 UK houseplants (catch-all to ~300)
- [ ] T131 Care database complete — ~300 plants, deduped & reviewed

**Phase 7 — Final review**
- [ ] T200 Compile key-decision review packet for human sign-off

**Phase 8 — Streamlined add plants (basket multi-add + photo capture)**
- [x] T201 Photo blob on the model (Plant/StoredPlant.photoData + PlantPhoto encode)
- [x] T202 Random nickname provider (curated English names + injectable RNG)
- [x] T203 Basket add view model (multi-add state, auto-naming, batch commit)
- [x] T204 Basket add view + "+" rewiring (basket replaces single-add)
- [x] T205 Camera seam + stub + camera permission
- [x] T206 Photo-capture coordinator (sequential capture→save→advance)
- [x] T207 Camera overlay view + AVFoundation capture
- [x] T208 Wire post-create photo flow ("take photos?" → sequential camera)

**Phase 9 — Rooms, room-driven schedules, tile home & guided watering**
- [x] T209 Balanced ~300-name pool (gender-split, testable)
- [x] T210 Room domain model + environment factor (sunlight × humidity, pure)
- [x] T211 Room persistence + plant→room link (StoredRoom, schema, room CRUD)
- [ ] T212 Drive schedule from rooms; retire phone weather; initial cadence at add-time
- [ ] T213 Rooms UI + room assignment (rooms screen, basket/edit room picker)
- [ ] T214 Tile home page (Plants/Rooms/Water) + show plant photos
- [ ] T215 Guided watering walkthrough (two modes, photo + report → water/skip)
---

## Tasks

> The data model, care-DB schema, and the scheduling/adaptation rules are specified in
> [`docs/designs/adaptive-watering.md`](./docs/designs/adaptive-watering.md) — tasks that build
> to it point at it via `Design:`. **Out of scope for this backlog:** running on a physical
> device / App Store distribution (needs a paid Apple Developer account + signing — a future
> 🔒 needs-human task). Everything here runs and verifies on the **iOS Simulator**.

### T001 — Project scaffold + local Definition of Done passes on an empty build
- **Depends on:** (none)
- **Scope:** `Sources/` (app skeleton, `Info.plist`, `Assets.xcassets`), `Tests/`, `README.md`
- **Verify:** simulator-screenshot
- **Do:** Flesh out the SwiftUI app skeleton so the **already-present** `project.yml` /
  `build_run.sh` (XcodeGen, mirroring `../basket`) build green: create `Sources/SproutApp.swift`
  (the `@main` App), a minimal `ContentView`, `Sources/Info.plist`, an `Assets.xcassets` with
  `AppIcon` + `AccentColor`, and `Tests/SproutTests.swift` with one trivial passing XCTest. No
  SwiftData/persistence yet (that's T005). Then run `./build_run.sh` and the XCTest command and
  make both green; **read `screenshots/latest.png`** to confirm the default screen renders, and
  record the observation in `worklog/T001.md`.
- **Done-when:** `./build_run.sh` reaches `** BUILD SUCCEEDED **` and saves a screenshot; `xcodegen
  generate && xcodebuild test … -scheme Sprout -destination 'platform=iOS Simulator,name=iPhone 17
  Pro'` passes on a clean tree; the screenshot observation is in `worklog/T001.md`; `README.md`
  reflects how to build/run; the T001 index box and README row are flipped in the same commit.

### T002 — Verification baseline — demo-seed hook + screenshot convention
- **Depends on:** T001
- **Scope:** `Sources/` (debug seed hook), `CLAUDE.md`
- **Verify:** simulator-screenshot
- **Do:** Establish the convention every later UI task verifies against (Basket-style: XCTest +
  `build_run.sh` screenshot, **no XCUITest**). Add a **debug-only launch hook** — `-seedDemoData
  YES` launch argument (and/or a `SPROUT_SCREEN=<name>` env var) read at startup in DEBUG builds
  — that populates the app with a small in-memory demo dataset (and can deep-link to a named
  screen) so screenshots show real content. Document in `CLAUDE.md` how a task drives a specific
  screen/state for its screenshot via `./build_run.sh "iPhone 17 Pro" -seedDemoData YES`.
- **Done-when:** `./build_run.sh "iPhone 17 Pro" -seedDemoData YES` launches into a populated
  screen and `screenshots/latest.png` shows it (agent reads it back); the hook is DEBUG-only (no
  effect on release); the convention is documented in `CLAUDE.md` for later tasks to reuse.

### T003 — Domain model types (Plant, CareProfile, CheckIn) — pure Swift
- **Depends on:** T001
- **Scope:** `Sources/Model/*.swift`, `Tests/Model*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Define pure value types — `Plant`, `CareProfile` (species, base/min/max interval,
  `moisture` preference), `CheckIn` (date, soil, leaves, watered), and the `SoilMoisture` /
  `LeafState` / `MoisturePreference` enums — with **no** SwiftUI/SwiftData imports.
- **Done-when:** the types compile, are `Codable`/`Equatable` where needed, and unit tests
  cover construction + invariants (e.g. `min ≤ base ≤ max`); the module imports no UI/persistence.

### T004 — Care database loader, schema & validator (data grows via T101–T130)
- **Depends on:** T003
- **Scope:** `Sources/Resources/care_database.json`, `Sources/Model/CareDatabase.swift`,
  `Tests/CareDatabase*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Create `care_database.json` (starting as a small **valid seed** of ~5 example plants)
  and a loader that decodes it into `[CareProfile]` with search/sort for the species picker.
  Implement a **reusable validator** — used here *and* by every T101–T130 batch — enforcing valid
  `moisture`, `min ≤ base ≤ max`, and unique species. The full ~300 plants are added by the
  Phase 6 batches (T101–T130); **this task does not research plants**, it builds the pipeline.
- **Done-when:** the JSON decodes; the loader + validator are unit-tested (a valid file passes; a
  deliberately malformed/duplicate row fails); the picker lists/searches whatever plants are
  present. (Final count is checked by T131.)

### T005 — SwiftData persistence + repository protocol
- **Depends on:** T003
- **Scope:** `Sources/Persistence/*`, `Tests/Persistence*`
- **Do:** Add SwiftData `@Model` store types mapping the domain model, plus a
  `PlantRepository` protocol with a SwiftData implementation (CRUD for plants + appended
  check-ins). The UI/view-models depend on the **protocol**, not SwiftData directly.
- **Done-when:** an in-memory `ModelContainer` round-trips a plant with check-ins in
  integration tests; CRUD works; nothing outside this module imports SwiftData.

### T006 — My Plants list + empty state
- **Depends on:** T002, T005
- **Scope:** `Sources/Views/PlantList*`, `Sources/ViewModels/PlantList*`, `Tests/*`
- **Verify:** simulator-screenshot
- **Do:** Build the home list from the repository — cards (name, species, next-due pill,
  water-drop indicator) and a first-run empty state — behind a testable view model.
- **Done-when:** the list view-model is unit-tested (empty → empty state; seeded → cards in
  due-order); `./build_run.sh "iPhone 17 Pro" -seedDemoData YES` renders the populated list and
  `screenshots/latest.png` (read back) confirms it; observation in `worklog/T006.md`.

### T007 — Add / Edit Plant (species picker from care DB)
- **Depends on:** T006, T004
- **Scope:** `Sources/Views/PlantEdit*`, `Sources/ViewModels/PlantEdit*`, `Tests/*`
- **Verify:** simulator-screenshot
- **Do:** A form to add/edit a plant — nickname, species picked from the care DB (T004),
  location, pot size, optional photo — saved via the repository.
- **Done-when:** the add/edit view-model is unit-tested (save → repository has it; species list
  sourced from the care DB); launching the seeded list after a save shows the plant in
  `screenshots/latest.png` (read back); observation in `worklog/T007.md`.

### T008 — Plant Detail + check-in history
- **Depends on:** T006
- **Scope:** `Sources/Views/PlantDetail*`, `Sources/ViewModels/PlantDetail*`, `Tests/*`
- **Verify:** simulator-screenshot
- **Do:** A detail screen showing the plant, its current schedule (placeholder until T009),
  and a chronological check-in history, reachable from a list card.
- **Done-when:** the detail view-model is unit-tested (loads the plant + its check-in history);
  launching into the detail screen (seeded) shows it in `screenshots/latest.png` (read back);
  observation in `worklog/T008.md`.

### T009 — Schedule engine — effective interval (pure)
- **Depends on:** T003
- **Scope:** `Sources/Engine/Schedule*`, `Tests/Schedule*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Implement the pure effective-interval / next-due function
  (`base × weatherFactor × adj`, clamped to species `min`/`max`) with an **injected** clock and
  `weatherFactor` defaulting to `1.0`.
- **Done-when:** unit tests assert intervals + clamping across species and `adj` values; the
  function is pure (no I/O; "now" is injected).

### T010 — Adaptive update from a check-in (pure)
- **Depends on:** T009, T004
- **Scope:** `Sources/Engine/Adapt*`, `Tests/Adapt*`
- **Design:** docs/designs/adaptive-watering.md
- **Do:** Implement the pure check-in update returning `(newAdj, recommendation, didWater)` per
  the design's decision table — including early/on-time/late timing and the droopy overrides.
- **Done-when:** a unit-test table covers **every** row of the design table (incl.
  wet → skip+lengthen, dry-early → shorten, droopy+wet → lengthen + overwater indication) and the
  `[0.5, 2.0]` `adj` clamp; `recommendation` is a structured value, not a brittle string.

### T011 — Check-in flow UI (soil / leaves / watered → recommendation)
- **Depends on:** T008, T010, T005
- **Scope:** `Sources/Views/CheckIn*`, `Sources/ViewModels/CheckIn*`, `Tests/*`
- **Verify:** simulator-screenshot
- **Do:** From a plant, run the check-in (soil `Dry/Moist/Wet`, leaves `Fine/Droopy`,
  watered?), persist the `CheckIn`, apply the adaptive update, and show the recommendation +
  updated next-due.
- **Done-when:** the check-in view-model is unit-tested end-to-end (each soil/leaf combo →
  persisted `CheckIn` + updated `adj`/next-due + recommendation per the design table); launching
  into the check-in screen (seeded) shows the controls + recommendation in
  `screenshots/latest.png` (read back); observation in `worklog/T011.md`.

### T012 — "Why this schedule" explanation text
- **Depends on:** T009, T008
- **Scope:** `Sources/Engine/Explanation*`, `Sources/Views/*`, `Tests/*`
- **Verify:** simulator-screenshot
- **Do:** Build a plain-language explanation from the schedule inputs (base, weather, `adj`,
  last check-in) — e.g. *"every 9 days — shortened from 12 because it dried out early"* — shown
  on detail and summarised on the list pill.
- **Done-when:** a unit-tested builder maps inputs → sentence; detail shows it; screenshot recorded.

### T013 — Local watering notifications
- **Depends on:** T005
- **Scope:** `Sources/Notifications/*`, `Tests/Notifications*`
- **Do:** A `NotificationScheduling` protocol + `UNUserNotificationCenter` implementation that
  schedules a per-plant watering reminder at the next-due date and reschedules on check-in;
  request authorization on first use.
- **Done-when:** integration tests with a **stub** center assert a reminder is
  scheduled/rescheduled for the right date; the app requests permission and degrades gracefully
  if denied (record the degraded behaviour in `docs/LIMITATIONS.md`).

### T014 — Settings — preferred reminder time, units, weather toggle
- **Depends on:** T013, T006
- **Scope:** `Sources/Views/Settings*`, `Sources/ViewModels/Settings*`, `Tests/*`
- **Verify:** simulator-screenshot
- **Do:** A settings screen for the preferred reminder time-of-day window, °C/°F units, and a
  weather toggle; persisted and wired so reminders fire in the chosen window.
- **Done-when:** the settings view-model is unit-tested (preferred time changes scheduled
  reminders' time; values persist across launches); launching the seeded Settings screen shows
  it in `screenshots/latest.png` (read back); observation in `worklog/T014.md`.

### T015 — Weather provider (Open-Meteo + CoreLocation)
- **Depends on:** T001
- **Scope:** `Sources/Weather/*`, `Tests/Weather*`, `Tests/Fixtures/openmeteo_*.json`
- **Do:** A `WeatherProviding` protocol + Open-Meteo implementation (no API key) decoding a
  forecast for a lat/lon, plus an **injectable** CoreLocation wrapper; handle permission and
  fall back to a neutral factor when location/forecast is unavailable.
- **Done-when:** decoding is unit-tested from a saved Open-Meteo **fixture**; location is
  injectable/stubbable; a denied/unavailable location yields `weatherFactor = 1.0`; **no network
  in tests**.

### T016 — Feed weather into the schedule engine
- **Depends on:** T015, T009, T012
- **Scope:** `Sources/Engine/*`, `Sources/Views/*`, `Tests/*`, `Tests/*`
- **Verify:** simulator-screenshot
- **Do:** Map the forecast (temperature, plus precipitation for outdoor plants) to
  `weatherFactor` and feed it into the schedule engine; surface the weather influence in the
  "why" explanation (T012).
- **Done-when:** unit tests cover the forecast → factor mapping (hot → `<1`, cold → `>1`) and an
  end-to-end recompute; the explanation mentions weather when it moved the interval; screenshot
  recorded.

### T101 — Care DB batch 01 — add 10 UK houseplants ()
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 01** (category: ) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T102 — Care DB batch 02 — add 10 UK houseplants (pothos / Epipremnum)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 02** (category: pothos / Epipremnum) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T103 — Care DB batch 03 — add 10 UK houseplants (Philodendron)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 03** (category: Philodendron) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T104 — Care DB batch 04 — add 10 UK houseplants (Monstera / Syngonium)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 04** (category: Monstera / Syngonium) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T105 — Care DB batch 05 — add 10 UK houseplants (Anthurium / Aglaonema / peace lily)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 05** (category: Anthurium / Aglaonema / peace lily) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T106 — Care DB batch 06 — add 10 UK houseplants (Alocasia / Caladium)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 06** (category: Alocasia / Caladium) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T107 — Care DB batch 07 — add 10 UK houseplants (ZZ / Dracaena / Cordyline)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 07** (category: ZZ / Dracaena / Cordyline) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T108 — Care DB batch 08 — add 10 UK houseplants (Echeveria / Graptopetalum / Pachyphytum & rosette succulents)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 08** (category: Sansevieria) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T109 — Care DB batch 09 — add 10 UK houseplants (Crassula / Sedum / Sempervivum)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 09** (category: Crassula / Sedum / Sempervivum) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T110 — Care DB batch 10 — add 10 UK houseplants (Crassula / Sedum / Sempervivum)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 10** (category: Crassula / Sedum / Sempervivum) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T111 — Care DB batch 11 — add 10 UK houseplants (Haworthia / Gasteria / Aloe)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 11** (category: Haworthia / Gasteria / Aloe) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T112 — Care DB batch 12 — add 10 UK houseplants (Kalanchoe / trailing succulents)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 12** (category: Kalanchoe / trailing succulents) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T113 — Care DB batch 13 — add 10 UK houseplants (cacti I)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 13** (category: cacti I) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T114 — Care DB batch 14 — add 10 UK houseplants (cacti II / Euphorbia)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 14** (category: cacti II / Euphorbia) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T115 — Care DB batch 15 — add 10 UK houseplants (ferns)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 15** (category: ferns) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T116 — Care DB batch 16 — add 10 UK houseplants (Calathea / Maranta)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 16** (category: Calathea / Maranta) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T117 — Care DB batch 17 — add 10 UK houseplants (Ctenanthe / Fittonia / Pilea)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 17** (category: Ctenanthe / Fittonia / Pilea) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T118 — Care DB batch 18 — add 10 UK houseplants (Peperomia)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 18** (category: Peperomia) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T119 — Care DB batch 19 — add 10 UK houseplants (Begonia)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 19** (category: Begonia) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T120 — Care DB batch 20 — add 10 UK houseplants (Tradescantia / Ceropegia)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 20** (category: Tradescantia / Ceropegia) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T121 — Care DB batch 21 — add 10 UK houseplants (spider plant / Aspidistra)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 21** (category: spider plant / Aspidistra) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T122 — Care DB batch 22 — add 10 UK houseplants (palms)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 22** (category: palms) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T123 — Care DB batch 23 — add 10 UK houseplants (Ficus)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 23** (category: Ficus) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T124 — Care DB batch 24 — add 10 UK houseplants (Schefflera / Dieffenbachia / Pachira)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 24** (category: Schefflera / Dieffenbachia / Pachira) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T125 — Care DB batch 25 — add 10 UK houseplants (Hoya)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 25** (category: Hoya) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T126 — Care DB batch 26 — add 10 UK houseplants (orchids)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 26** (category: orchids) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T127 — Care DB batch 27 — add 10 UK houseplants (bromeliads / air plants)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 27** (category: bromeliads / air plants) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T128 — Care DB batch 28 — add 10 UK houseplants (flowering: African violet / cyclamen)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 28** (category: flowering: African violet / cyclamen) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T129 — Care DB batch 29 — add 10 UK houseplants (carnivorous)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 29** (category: carnivorous) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T130 — Care DB batch 30 — add 10 UK houseplants (herbs / edibles / citrus)
- **Depends on:** T004
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`
- **Design:** docs/research/uk-houseplants.md
- **Do:** Research **batch 30** (category: herbs / edibles / citrus) per `docs/research/uk-houseplants.md` and add **10 new unique** UK houseplants not already present — each a real `CareProfile` (moisture + base/min/max) grounded in an authoritative source where reachable (else the genus-anchor defaults) — appending a row per plant to that doc's Provenance index.
- **Done-when:** the dataset gains **exactly 10** new unique species (no duplicate scientific names); every new row passes the T004 validator (`min ≤ base ≤ max`, valid `moisture`); each new plant has a Provenance-index row recording its source (or, if web research isn't available in the run, the genus-anchor rationale used); unit tests green.

### T131 — Care database complete — ~300 plants, deduped & reviewed
- **Depends on:** T101, T102, T103, T104, T105, T106, T107, T108, T109, T110, T111, T112, T113, T114, T115, T116, T117, T118, T119, T120, T121, T122, T123, T124, T125, T126, T127, T128, T129, T130
- **Scope:** `Sources/Resources/care_database.json`, `docs/research/uk-houseplants.md`, `Tests/CareDatabase*`
- **Do:** Verify the assembled dataset end to end: ~300 unique species, no duplicate scientific names, every record valid; reconcile the Provenance index against the JSON and fill any gaps.
- **Done-when:** the file holds **≥ 290 unique** species; the T004 validator passes on the whole dataset; the Provenance index has a row per plant; README status updated.

### T200 — Compile key-decision review packet for human sign-off
- **Depends on:** T007, T011, T014, T016, T131
- **Scope:** `docs/REVIEW.md`, `README.md`
- **Do:** With the whole backlog built, compile `docs/REVIEW.md` — a single packet of the key
  judgement calls made along the way, each with **where it lives** and **how to tweak it**: the
  adaptive-engine constants (nudge factors, the `adj` clamp, `recheckDays`), the schedule formula
  and the weather→`weatherFactor` mapping, notification defaults (the preferred-time window), the
  verification approach (`build_run.sh` screenshots + XCTest), the check-in UX, and any **low-confidence
  care-database entries** (species whose interval/moisture was a judgement call). Call out
  anything you were genuinely unsure about.
- **Done-when:** `docs/REVIEW.md` lists each key decision with a file/line pointer and the knob to
  change it, plus an explicit **"low-confidence / please check"** section; `README.md` links to it.
  This is the final task — when it merges, the backlog is complete and ready for your end-to-end
  review and tweaks.

---

## Phase 8 — Streamlined add plants (basket multi-add + photo capture)

> A post-backlog feature added interactively (not by the unattended loop): make adding plants
> fast and batch-oriented. "+" opens a **basket** where you tap to add many plants at once
> (auto-named with random English names, editable + re-rollable), then optionally walk through a
> **sequential square camera** that photographs each new plant one at a time. Built bottom-up as
> atomic branches `t201`–`t208`. The full design is in the approved plan; specs below.

### T201 — Photo blob on the model
- **Depends on:** T005
- **Scope:** `Sources/Model/Plant.swift`, `Sources/Model/PlantPhoto.swift`, `Sources/Persistence/StoredModels.swift`, `Tests/PlantPhotoTests.swift`, `Tests/PersistenceTests.swift`
- **Do:** Add `photoData: Data?` to the domain `Plant` and the SwiftData `StoredPlant`
  (`@Attribute(.externalStorage)`), threading it through `init(domain:)`/`toDomain()`/`applyScalars`.
  Add a UIKit-aware `PlantPhoto.encode(_:maxDimension:jpegQuality:)` that centre-crops square,
  downscales, and JPEG-compresses.
- **Done-when:** photo round-trips through the repository (set, update, clear → nil); a plant added
  without a photo reads back `nil` (additive, no migration); `PlantPhoto.encode` returns a square
  JPEG within `maxDimension` and `nil` for an image with no `CGImage`; unit tests green.

### T202 — Random nickname provider
- **Depends on:** (none)
- **Scope:** `Sources/Model/RandomNicknameProvider.swift`, `Tests/RandomNicknameProviderTests.swift`
- **Do:** A pure value type holding a curated list of common English first names with an injectable
  `RandomNumberGenerator`; `next(avoiding: Set<String>) -> String` returns an unused name where
  possible, falling back gracefully (suffix) when the pool is exhausted.
- **Done-when:** seeded RNG yields deterministic names; `next` never returns a name in `avoiding`
  until the pool is exhausted; exhaustion never loops/crashes; unit tests green.

### T203 — Basket add view model
- **Depends on:** T202
- **Scope:** `Sources/ViewModels/BasketAddViewModel.swift`, `Tests/BasketAddViewModelTests.swift`
- **Do:** `@MainActor` view model holding a basket of `{species, auto nickname}` entries; species
  search via the care DB; `add`/`remove`/`rename`/`reroll`; `commit() throws -> [Plant]` inserts
  each via `repository.add` and returns them in basket order. Auto-names are unique across existing
  repo nicknames ∪ current basket.
- **Done-when:** adding the same species twice yields two entries with distinct names; `canCommit`
  is false for an empty basket or an unknown species; `commit` creates exactly N plants in order;
  unit tests green.

### T204 — Basket add view + "+" rewiring 🚦
- **Depends on:** T203
- **Scope:** `Sources/Views/BasketAddView.swift`, `Sources/Views/PlantListView.swift`, `Sources/ContentView.swift`, `Sources/DemoSeed.swift`, `Tests/*`
- **Do:** Build `BasketAddView` (species search + editable basket list with reroll/remove). Re-point
  the list "+" button from the single-add sheet to the basket; keep `PlantEditView` for the
  edit-swipe path only. Add a `makeBasket` factory in `ContentView` against the shared repository,
  and a `SPROUT_SCREEN=basket` deep-link with a fixed RNG seed for stable screenshot names.
- **Verify:** simulator-screenshot.
- **Done-when:** "+" opens the basket; committing adds the plants and the list refreshes; the
  `SPROUT_SCREEN=basket` screenshot shows the basket with stable names; edit-swipe still opens the
  single-plant form; unit tests green.

### T205 — Camera seam + stub + permission
- **Depends on:** T201
- **Scope:** `Sources/Camera/PhotoCapturing.swift`, `Sources/Camera/StubPhotoCapturing.swift`, `Sources/ContentView.swift`, `project.yml`
- **Do:** Define the `PhotoCapturing` protocol (`isAvailable`, `capture() async -> UIImage?`) and a
  `StubPhotoCapturing` returning a placeholder square image. Add `makeCamera()` in `ContentView`
  returning the stub on simulator/DEBUG and the real camera (T207) otherwise. Add
  `NSCameraUsageDescription` to `project.yml`.
- **Done-when:** the seam + stub compile and are usable from tests; the camera-permission string is
  present in the generated Info.plist; unit tests green.

### T206 — Photo-capture coordinator
- **Depends on:** T201, T205
- **Scope:** `Sources/ViewModels/PhotoCaptureCoordinator.swift`, `Tests/PhotoCaptureCoordinatorTests.swift`
- **Do:** `@MainActor` coordinator over an ordered list of targets `{id, nickname, species}`;
  `captureCurrent()` captures via the seam, encodes via `PlantPhoto`, saves to the plant
  (`plant(id:)` → set `photoData` → `update`), and advances; `skip()` advances without saving;
  reaching the end sets `isFinished`. Exposes the banner text for the current target.
- **Done-when:** capture saves the photo to the current plant and advances; skip advances without
  saving; the end sets `isFinished`; banner names the current plant; unit tests green (via the stub
  + in-memory repo).

### T207 — Camera overlay view + AVFoundation capture
- **Depends on:** T205, T206
- **Scope:** `Sources/Camera/AVFoundationCamera.swift`, `Sources/Views/PhotoCaptureView.swift`, `Sources/DemoSeed.swift`, `Sources/Views/PlantListView.swift`
- **Do:** Real `AVFoundationCamera` (square `AVCaptureSession` + `AVCaptureVideoPreviewLayer`
  preview) implementing `PhotoCapturing`. `PhotoCaptureView`: square preview (or stub placeholder
  when the camera is unavailable), top overlay banner naming the current plant, a large shutter
  (tap → capture → auto-advance) and a Skip button. Add a `SPROUT_SCREEN=camera` deep-link.
- **Verify:** simulator-screenshot (renders via the stub; the camera is unavailable on the sim).
- **Done-when:** the `SPROUT_SCREEN=camera` screenshot shows the overlay banner + shutter; capturing
  the stub image advances through the targets; the real on-device camera path is left for human
  verification (🔒 — recorded, not auto-completed); unit tests green.

### T208 — Wire post-create photo flow
- **Depends on:** T204, T207
- **Scope:** `Sources/Views/PlantListView.swift`, `Sources/ContentView.swift`
- **Do:** After a basket commit, show a "Want to take photos of these plants?" dialog; on Yes,
  present `PhotoCaptureView` (full-screen) over a coordinator seeded with the just-created plants in
  basket order; refresh the list on finish.
- **Verify:** simulator-screenshot.
- **Done-when:** committing the basket prompts for photos; choosing Yes walks the new plants through
  the camera and saves each photo; choosing Not now returns to the refreshed list; unit tests green.

---

## Phase 9 — Rooms, room-driven schedules, tile home & guided watering

> A second interactive feature round. Replaces the phone-weather schedule input with **Rooms**
> (sunlight + humidity drive the cadence, including a plant's initial schedule at add-time), adds a
> **tile home page** (Plants / Rooms / Water), surfaces plant **photos**, and adds an **interactive
> guided-watering** walkthrough. Branches `t209`–`t215`. Full design in the approved plan.

### T209 — Balanced ~300-name pool
- **Depends on:** T202
- **Scope:** `Sources/Model/RandomNicknameProvider.swift`, `Tests/RandomNicknameProviderTests.swift`, `docs/LIMITATIONS.md`
- **Do:** Split `EnglishNames` into testable `girls`/`boys`/`unisex` sub-lists and expand to a balanced
  ~300 (no duplicates); `all = girls + boys + unisex`.
- **Done-when:** ≥300 unique names; girls/boys within ~10%; tests green.

### T210 — Room domain model + environment factor
- **Depends on:** (none)
- **Scope:** `Sources/Model/Room.swift`, `Sources/Engine/RoomEnvironment.swift`, `Tests/RoomEnvironmentTests.swift`
- **Do:** `Room {id,name,sunlight,humidity}` with `SunlightLevel{low,indirect,direct}` +
  `RoomHumidity{dry,normal,moist}`; pure `RoomEnvironment.factor(sunlight:humidity:)` (3×3 table, clamped
  to the engine's `[0.7,1.3]`).
- **Done-when:** factor maps each combo as specified, clamps, neutral at indirect+normal; tests green.

### T211 — Room persistence + plant→room link
- **Depends on:** T210, T005
- **Scope:** `Sources/Persistence/StoredModels.swift`, `PlantRepository.swift`, `SwiftDataPlantRepository.swift`, `Sources/Model/Plant.swift`, `Tests/PersistenceTests.swift`
- **Do:** `StoredRoom @Model` + mapping; `Plant.roomID`/`StoredPlant.roomID` (additive, migration-free);
  schema adds `StoredRoom`; room CRUD on the repository (delete-room nils plants' `roomID`).
- **Done-when:** room + roomID round-trip; delete-room nils plants; tests green.

### T212 — Drive the schedule from rooms; retire weather
- **Depends on:** T211
- **Scope:** `Sources/ContentView.swift`, `Sources/Engine/ScheduleExplanation.swift`, `Sources/ViewModels/{BasketAddViewModel,PlantEditViewModel,PlantListViewModel,CheckInViewModel,PlantDetailViewModel,SettingsViewModel}.swift`, `Sources/Views/SettingsView.swift`, `Tests/*`
- **Do:** Resolve a **per-plant** environment factor from its room (replacing the global weather factor);
  compute initial `nextDue` at add-time; swap weather causes for `driesFaster`/`driesSlower` in the
  explanation; remove the weather toggle + temperature unit from Settings; unwire the weather/GPS path.
- **Done-when:** schedule uses the room factor end-to-end; new plants get an initial cadence; no weather
  toggle; explanation names the room environment; tests green.

### T213 — Rooms UI + room assignment · Verify: simulator-screenshot
- **Depends on:** T212
- **Scope:** `Sources/Views/RoomsView.swift`, `Sources/ViewModels/RoomsViewModel.swift`, `Sources/Views/BasketAddView.swift`, `Sources/ViewModels/BasketAddViewModel.swift`, `Sources/Views/PlantEditView.swift`, `Sources/ViewModels/PlantEditViewModel.swift`, `Sources/ContentView.swift`, `Sources/DemoSeed.swift`, `Tests/*`
- **Do:** Rooms list/add/edit/delete screen; room picker in the basket (batch) + edit; `makeRooms` factory;
  demo rooms + `SPROUT_SCREEN=rooms`.
- **Done-when:** can create/edit/delete rooms and assign plants; the rooms screenshot renders; tests green.

### T214 — Tile home page + show photos · Verify: simulator-screenshot
- **Depends on:** T213
- **Scope:** `Sources/Views/HomeView.swift`, `Sources/ContentView.swift`, `Sources/Views/PlantListView.swift`, `Sources/Views/PlantDetailView.swift`, `Tests/*`
- **Do:** `HomeView` with Plants/Rooms/Water tiles (Water shows a due count) + a Settings gear; it owns the
  `NavigationStack` (de-nest `PlantListView`); show plant photos on cards + detail header.
- **Done-when:** home tiles navigate correctly; photos display; `SPROUT_SCREEN=home` screenshot renders; tests green.

### T215 — Guided watering walkthrough · Verify: simulator-screenshot
- **Depends on:** T214
- **Scope:** `Sources/ViewModels/GuidedWateringCoordinator.swift`, `Sources/Views/GuidedWateringView.swift`, `Sources/ContentView.swift`, `Sources/Views/HomeView.swift`, `Tests/GuidedWateringCoordinatorTests.swift`
- **Do:** Sequential coordinator over a mode-selected `[Plant]` (full check-in vs due-only): per plant show
  photo + report soil/leaves → preview recommendation (no persist) → confirm watered/skip (persist + advance).
  Mode chooser on the Water tile; `SPROUT_SCREEN=water`.
- **Done-when:** both modes walk the right plants; preview doesn't persist; confirm waters + advances; skip
  advances; empty state; the water screenshot renders; tests green.
