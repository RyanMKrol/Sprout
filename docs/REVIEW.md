# REVIEW — key-decision packet for sign-off (T200)

This is the single packet of the **judgement calls** Sprout's backlog baked in: each adaptive
constant, the schedule formula, the environment→factor mapping, the notification defaults, the
check-in UX, the verification approach, and the care-database entries that were a genuine guess.
For every decision: **what it is**, **where it lives** (file/line), and **the knob to turn** to
change it. The numbers are deliberate but not sacred — they are starting points tuned by hand and
meant for you to override. Anything I was genuinely unsure about is collected under
[Low-confidence / please check](#low-confidence--please-check).

> Pointers are `file:line` at the time of writing — if a file has shifted, search the named symbol.
> Design rationale for the engine lives in [`designs/adaptive-watering.md`](./designs/adaptive-watering.md);
> the care-DB method + per-species provenance in [`research/uk-houseplants.md`](./research/uk-houseplants.md).

---

## 1. The schedule formula

```
effectiveInterval = clamp( round(baseIntervalDays × envFactor × adj),  minIntervalDays, maxIntervalDays )
nextDue           = lastWatered + effectiveInterval days
```

- **Where:** `Sources/Engine/ScheduleEngine.swift:56` (`effectiveInterval`), `:84` (`nextDue`).
- **The decision:** a plant's interval is its species' **base** cadence, multiplied by two
  independent dials — the **environment factor** (room conditions, §3) and the learned **`adj`**
  (personalisation from check-ins, §2) — then **clamped to the species' own min/max band** so it
  can never recommend watering more often than `min` or stretch past `max`. Rounding is to the
  nearest whole day.
- **Knob to turn:** the per-species `base`/`min`/`max` live in the care DB (§6); the two
  multipliers are §2 and §3. The clamp itself is the species band — widen a species' `min..max`
  in `care_database.json` to let the dials move it further.

## 2. The adaptive engine — how a check-in nudges the schedule

All in `Sources/Engine/AdaptiveEngine.swift`. The engine is a **pure decision table**: a check-in's
(soil, leaves, timing, species-moisture) selects exactly one row, which carries a **multiplicative
nudge** to `adj`, an **action**, and a **reason**.

| Constant | Value | Where | What it controls |
|---|---|---|---|
| `recheckDays` | **3** | `AdaptiveEngine.swift:95` | When we say *skip/monitor*, the next reminder lands this many days out. |
| `timingBand` | **0.20** | `AdaptiveEngine.swift:99` | A check-in more than ±20% of the interval before/after due counts as `early`/`late` (vs `onTime`). |
| `adj` clamp (`Plant.adjRange`) | **0.5 … 2.0** | `Sources/Model/Plant.swift:14` | Hard limit on how far personalisation can stretch/shrink an interval (±2×). Applied in both engines (`AdaptiveEngine.swift:244`, `ScheduleEngine.swift:61`). |

### The nudge factors (decision table — `AdaptiveEngine.swift:198`–`240`)

Each row multiplies `adj` by a factor `<1.0` to **shorten** future intervals (plant wants water
sooner) or `>1.0` to **lengthen** them. `1.0` = on target, hold.

| Situation | Factor | Action | Reason |
|---|---|---|---|
| Droopy + dry | **0.80** | water now | `droopyDry` |
| Droopy + wet | **1.20** | skip | `droopyWet` |
| Droopy + moist | **0.95** | monitor | `droopyMoist` |
| Fine + wet | **1.15** | skip | `stillWet` |
| Fine + dry + early | **0.85** | water now | `driedEarly` |
| Fine + dry + on-time/late, `staysMoist` species | **0.90** | water now | `dontDryOut` |
| Fine + dry + on-time/late, other species | **1.0** | water now | `onTargetDry` |
| Fine + moist + early | **1.05** | water lightly | `touchEarly` |
| Fine + moist + on-time/late | **1.0** | water lightly | `onTargetMoist` |

- **Knob to turn:** edit the literals in `decide(...)` for the nudges, the two `static let`s for
  `recheckDays`/`timingBand`, and `Plant.adjRange` for the clamp. Because each row is an enum
  `Reason`, the unit tests (`Tests/AdaptiveEngineTests*`) assert the *decision*, not prose — change
  a factor and the test for that row is where you re-pin the expectation.
- **What I weighed:** droopy leaves **override** soil-timing entirely (a drooping plant is the
  strongest signal). The nudges are intentionally gentle (±5–20%) so the schedule converges over
  several check-ins rather than lurching on one reading. The asymmetry — drying-early shortens hard
  (0.85) but a touch-early-and-moist only lengthens a little (1.05) — biases toward *not* under-watering.

## 3. Environment → factor mapping (rooms replaced live weather)

**Heads-up on history:** the backlog originally fed **weather** into the schedule (T015/T016,
`Sources/Weather/…`, `Sources/Engine/WeatherFactor.swift`). Phase 9 (**T212**) **retired the live
weather path** in favour of a per-**room** environment factor. The weather code still compiles and
is unit-tested, but **nothing live calls it** — the schedule's second dial is now the room.

### Live path — `Sources/Engine/RoomEnvironment.swift`

`factor = sunlightFactor × humidityFactor`, clamped to **[0.7, 1.3]** (±30%). Neutral `1.0` when a
plant has no room.

| Sunlight | factor | | Humidity | factor |
|---|---|---|---|---|
| low | **1.15** (water less often) | | dry | **0.90** (water more often) |
| indirect | 1.00 | | normal | 1.00 |
| direct | **0.85** (water more often) | | moist | **1.10** (water less often) |

- **Where / knob:** the 3×3 is `RoomEnvironment.swift:27`–`41`; clamp band at `:12`. These are
  hand-tuned anchors — a sunny dry room (`0.85×0.90 ≈ 0.77`) waters ~30% sooner; a dim humid room
  (`1.15×1.10 ≈ 1.27`) ~27% later.

### Retired path — `Sources/Engine/WeatherFactor.swift` (still tested, not wired)

If you ever re-enable weather: temperature-led, neutral band **16–24 °C** (`:26`), slope **0.02/°C**
(`:30`), clamp **[0.7, 1.3]** (`:33`), plus an outdoor-only rain term (`:37`–`44`) that is
implemented and tested but never called (no indoor/outdoor flag — see `docs/LIMITATIONS.md`).

## 4. Notification defaults — the preferred-time window

- **Default reminder hour:** **09:00** local — `WateringNotificationScheduler.defaultReminderHour`
  (`Sources/Notifications/WateringNotificationScheduler.swift:32`).
- **User override:** Settings exposes the hour (T014); valid band **0–23** —
  `SettingsViewModel.reminderHourRange` (`Sources/ViewModels/SettingsViewModel.swift:17`). Changing
  it reschedules every plant's pending reminder.
- **The decision:** one pending reminder per plant, keyed by a stable id, fired by a *calendar*
  trigger on the due **day** at the chosen hour (minute 0) so it survives DST. Only the **hour** is
  user-configurable — minutes are pinned to 0 (`SettingsViewModel.swift:103`). Authorization is
  lazy and denial degrades to a silent no-op.
- **Knob to turn:** the default hour constant above; to expose minute-granularity you'd widen the
  Settings model. (The CLAUDE.md framing of "evenings when they're home" suggests you may want to
  move the default later than 09:00 — that's a one-line change.)

## 5. The check-in UX and verification approach

### Check-in UX (T011 — `Sources/ViewModels/CheckInViewModel.swift`, `Sources/Views/CheckInView.swift`)

- **Three measurable inputs only:** soil (`Dry`/`Moist`/`Wet`), leaves (`Fine`/`Droopy`), and a
  *did-you-water* toggle. No free text, no numeric moisture — the engine asserts on enums, not
  prose. Defaults: soil = **moist**, leaves = **fine**, watered = **false** (`CheckInViewModel.swift:18`–`22`).
- **The decision:** we only advance the schedule when we **recommended** water **and** the user
  actually watered (`didWater`); otherwise next-due is `checkIn.date + recheckDays`. A plant with no
  resolvable care profile **blocks** check-in rather than guessing (`canCheckIn`).
- **Knob:** add/relabel the option enums in `Sources/Model/CheckIn.swift`; the "why this schedule"
  copy is `Sources/Engine/ScheduleExplanation.swift` (T012).

### Verification approach (project-wide)

- **No XCUITest, no SwiftLint.** The gate is: `./build_run.sh` reaching `BUILD SUCCEEDED` +
  installing/launching + saving `screenshots/latest.png`, then **XCTest** on the simulator. UI tasks
  are verified by **reading the screenshot** driven through the DEBUG `-seedDemoData YES` /
  `SPROUT_SCREEN=<name>` hook (`Sources/DemoSeed.swift`), not by tapping.
- **The trade-off:** fast and deterministic for pure logic (every engine rule is a directly-asserted
  pure function), but **UI regressions are caught by eye, not assertion** — a screenshot proves the
  screen rendered, not that every interaction works. This and the stale-binary screenshot caveat are
  logged in [`LIMITATIONS.md`](./LIMITATIONS.md).

## 6. The care database

- **Where:** `Sources/Resources/care_database.json` — **305 species**, each `{species,
  baseIntervalDays, minIntervalDays, maxIntervalDays, moisture}`. Loaded/validated by
  `Sources/Model/CareDatabase.swift` (invariant `min ≤ base ≤ max`).
- **Method:** UK homes, spring/summer baseline, watering only. Per-species provenance (common +
  scientific name, the numbers chosen, the source) is the 1:1 index in
  [`research/uk-houseplants.md`](./research/uk-houseplants.md). Genus/type **default anchors** are
  tabulated there for species without a specific source.
- **Knob to turn:** edit a row in the JSON. `moisture` (`driesOut`/`evenlyMoist`/`staysMoist`)
  changes which adaptive rows fire (§2); `base` sets the cadence; `min`/`max` set how far the dials
  can move it.

---

## Low-confidence / please check

The honest list of what was a **judgement call**. None of these are wrong-by-construction — they're
the places where a real grower's opinion would carry more weight than mine.

### Care-DB entries grounded in genus anchors, not species sources

Of the 305 species, **176 rows** were set from the **genus/type default anchors**, not a
species-specific citation (rationale column reads *"Genus anchor …"* in
[`research/uk-houseplants.md`](./research/uk-houseplants.md)). They're plausible but are the genus's
cadence, not the cultivar's. The shakiest sub-classes:

- **Heavy-variegation cultivars bumped longer on a heuristic.** Where a cultivar has much less
  chlorophyll (e.g. *Monstera* 'Thai Constellation' at 10/7–16, 'Snow Queen' pothos at 10/7–14,
  Pink Princess philodendron at 9/6–14), I lengthened the interval ~1–2 days on the reasoning
  "less chlorophyll → slower growth → drinks less." That direction is right; the **magnitude is a
  guess**.
- **Jewel Alocasias** (e.g. 'Dragon Scale' at 9/6–14) — notoriously fussy, anchored on
  general-Alocasia guidance plus a "let it dry more" nudge. Real-world results vary a lot by home.
- **Carnivorous plants** (flytrap/sundew/pitcher, anchor 2/1–4, `staysMoist`) — these really want
  the tray/rainwater method, which Sprout's interval model can't express. The cadence is a coarse
  proxy.

If you only spot-check one thing, **sort the provenance index by the "Genus anchor" rationale** and
sanity-check the ~10 species you actually own.

### Engine constants I'd most want a second opinion on

- **`recheckDays = 3`** (§2) — picked as "a few days, not a week." If skipped-plant nudging feels
  too frequent/infrequent, this is the dial.
- **`timingBand = 0.20`** (§2) — the ±20% early/late window is intuition, not data; a fast-drying
  species might deserve a tighter band.
- **The nudge magnitudes** (§2) — gentle by design so `adj` converges over several check-ins. If
  personalisation feels *too slow* to adapt, scale the off-`1.0` factors away from 1.0.
- **`RoomEnvironment` 3×3** (§3) — entirely hand-tuned; the corners (sunny+dry, dim+humid) are the
  least validated. The clamp keeps any error to ±30%, but the *shape* is a guess.

### Structural limitations (full list in `LIMITATIONS.md`)

- **Weather is retired** (§3) — outdoor plants get no live-weather adjustment; the room factor is
  the only environmental input. The weather code is dormant, not deleted.
- **No indoor/outdoor flag** — the implemented rain term never runs.
- **UI verified by screenshot, not assertion** (§5) — interaction regressions can slip through.
