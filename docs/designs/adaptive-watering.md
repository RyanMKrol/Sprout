# Design — Adaptive watering from measurable check-ins

Authoritative spec for Sprout's care database and its scheduling/adaptation engine. Tasks
**T004** (care DB), **T009** (schedule engine), **T010** (adaptive update) build to this.

## Philosophy

We do **not** model abstract "plant health." We learn each plant's true cadence from quick,
**measurable** observations the user makes at check-in time, and we only ever give an
**indication** ("water now" / "skip, come back in 3 days"), never a diagnosis. Every rule
below is a **pure function** — deterministic, no I/O — so it is asserted directly in unit
tests. Inject "now" (a `Clock`/date provider); never read the wall clock inside the engine.

## Care database (bundled JSON, decoded in T004)

A **local, bundled** dataset of the **~300 most common UK houseplants** — produced by a
**one-time research effort** (sources + methodology in
[`docs/research/uk-houseplants.md`](../research/uk-houseplants.md)) and shipped in the app, so
there is **no live lookup**. UK-targeted, grounded in authoritative guidance (Royal
Horticultural Society and reputable growers).

> **The numbers are adaptive *seeds*, not gospel.** `baseIntervalDays` only needs to be a
> sensible starting point for a species/category — the per-plant `adj` learned from check-ins
> (below) personalises it. This is what makes 300 plants tractable: most inherit their
> watering shape from their category (succulent/cactus → `driesOut`, long; fern → `staysMoist`,
> short; aroid like pothos/monstera → `evenlyMoist`, medium), refined where a species is known
> to differ. Scaling beyond this set, or user-added plants, is explicitly out of scope for now.

One record per species:

| Field | Type | Meaning |
|---|---|---|
| `species` | String | Display name (e.g. "Snake Plant"). |
| `baseIntervalDays` | Int | Starting cadence in typical indoor conditions. |
| `minIntervalDays` | Int | Floor — never recommend watering more often than this. |
| `maxIntervalDays` | Int | Ceiling. |
| `moisture` | enum | `driesOut` \| `evenlyMoist` \| `staysMoist` (below). |

**`moisture` preference** — drives what a given soil reading *means*:
- **`driesOut`** (succulents, cacti, snake plant): wants to dry fully between waterings.
  Target soil at due = **Dry**. **Wet ⇒ definitely skip.**
- **`evenlyMoist`** (pothos, monstera, most foliage): water when the top inch is dry. Target
  at due = **Moist**, Dry is acceptable. Wet ⇒ skip.
- **`staysMoist`** (ferns, calathea): keep lightly moist. Target at due = **Moist**;
  **Dry ⇒ overdue** (shorten).

## Inputs

```
enum SoilMoisture { dry, moist, wet }
enum LeafState    { fine, droopy }

struct CheckIn { date: Date; soil: SoilMoisture; leaves: LeafState; watered: Bool }
```

Per plant we persist a learned multiplier `adj` (Double, default **1.0**), `lastWatered`, and
the current `nextDue`.

## Schedule (T009 — pure)

```
effectiveInterval = clamp( round(baseIntervalDays × weatherFactor × adj),
                           minIntervalDays, maxIntervalDays )
nextDue           = lastWatered + effectiveInterval days
```

- `weatherFactor` defaults to **1.0** and is injected; T016 maps the forecast to it (hot/dry
  `< 1.0` ⇒ water more often, cold `> 1.0` ⇒ less). Until T015/T016 land it stays 1.0.
- `adj` is clamped to **[0.5, 2.0]** before use.

## Adaptive update (T010 — pure)

`update(species, plantState, checkIn, now) -> (newAdj, recommendation, didWater)`

Let **timing** = how `checkIn.date` compares to `nextDue`: **early** (before due by more than
~20% of the interval), **on-time**, or **late**. Suggested nudges (multiply `adj`, then clamp
to [0.5, 2.0]) — these are *starting values, tune them in the tests*:

| Soil | Leaves | Timing / species note | Nudge `adj` | Indication |
|---|---|---|---|---|
| **Wet** | any | any (esp. `driesOut`) | ×1.15 | "Skip — soil's still wet. Back in 3 days." (don't water) |
| **Dry** | fine | **early** | ×0.85 | "Water now — dried out faster than expected." |
| **Dry** | fine | on-time, `driesOut`/`evenlyMoist` | ×1.0 (hold) | "Water now." (on target) |
| **Dry** | fine | on-time/late, `staysMoist` | ×0.90 | "Water now — let's not let it dry out next time." |
| **Moist** | fine | on-time | ×1.0 (hold) | "Water lightly." (on target) |
| **Moist** | fine | early | ×1.05 | "A touch early — fine to top up." |
| any | **droopy** + Dry | — | ×0.80 | "Water now — leaves are drooping." |
| any | **droopy** + Wet | — | ×1.20 | "Leaves droop but soil's wet — let it dry out, may be overwatered." (don't water) |
| any | **droopy** + Moist | — | ×0.95 | "Keep an eye on it." |

Then:
- **didWater = true** (recommended water & user watered) ⇒ set `lastWatered = checkIn.date`,
  recompute `nextDue` from the new `adj`.
- **didWater = false** (skip) ⇒ set next reminder to `checkIn.date + recheckDays`, where
  `recheckDays = 3` (named constant, tunable). `lastWatered` unchanged.

`recommendation` is a small value (an enum case + computed day count) so the UI text and the
unit tests assert the *decision*, not a brittle string. The human-readable sentence is built
in T012 from this value + the schedule inputs ("every 9 days — shortened from 12 because it
dried out early").

## Why this is testable

- T009/T010 are pure: a table of `(species, adj, checkIn, timing) → (newAdj, recommendation)`
  cases covers every row above with exact assertions, including the min/max clamps.
- The UI tasks (T011/T012) only wire these results into views, verified by XCUITest +
  `simctl` screenshots (the harness from T002).
