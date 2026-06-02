# Care DB audit — coverage vs. common UK houseplants → gap list (T224)

Audits the bundled watering dataset (`Sources/Resources/care_database.json`, provenance in
[`uk-houseplants.md`](./uk-houseplants.md)) against the **most common UK houseplants**, then
compiles a **prioritised gap list** to feed the gap-fill batches **T225** (top ~15) and **T226**
(next ~15). Sourcing follows the same rules as `uk-houseplants.md`: prefer authoritative UK
guidance (RHS), reputable nurseries (Patch, Hortology, Beards & Daisies), and the genus/type
**anchors** for intervals; where a source isn't fetchable, fall back to the anchor and record it.

## 1. Current coverage

- **305 unique species** in the shipped dataset (validator-clean under T004: every record has
  `min ≤ base ≤ max` and a valid `moisture`; no normalised-name duplicates).
- **Moisture split:** `evenlyMoist` 172 · `driesOut` 88 · `staysMoist` 45. This matches the
  expected shape of a foliage/aroid-heavy collection with a solid succulent/cactus tail and a
  smaller moisture-loving (fern / calathea / carnivore) group.
- **Depth by category** (well covered — sampled from the species list):
  - **Aroids:** pothos/epipremnum (8+ incl. Marble Queen, Neon, Manjula, Cebu Blue, Satin),
    philodendron (10+ incl. Birkin, Brasil, Pink Princess, Xanadu, Tree), monstera (deliciosa,
    mini, variegated, silver), syngonium, scindapsus, aglaonema, dieffenbachia, alocasia,
    anthurium, ZZ.
  - **Succulents / cacti:** echeveria, haworthia, aloe, jade/crassula, sedum, kalanchoe,
    sansevieria (10+), euphorbia, opuntia (Bunny Ears), Christmas/Easter/Thanksgiving cactus,
    string-of-* (pearls, hearts, bananas, dolphins, turtles, buttons).
  - **Ferns:** Boston, maidenhair, bird's nest, blue star, button, lemon button, crocodile,
    staghorn, rabbit's foot, kangaroo paw, cretan brake, asparagus types.
  - **Calathea / marantas:** orbifolia, rattlesnake, peacock, rose-painted, pinstripe,
    fishbone/herringbone/rabbit's-tracks prayer plants, stromanthe, ctenanthe.
  - **Palms, figs, dracaenas, hoyas, orchids, bromeliads, carnivores, herbs, gesneriads** — all
    have a genus anchor plus several species each.
- **Conclusion:** the common UK core is **already deep**. Genuine gaps are now a modest set of
  (a) high-popularity species that slipped through the batch plan, (b) **search aliases** for
  profiles that ship only under a less-searched name, and (c) trend-popular cultivars.

### Count reconciliation (read before sizing the batches)

The original plan (`uk-houseplants.md`, T101–T131) targeted **~300** species and TASKS.md frames
T225/T226 as reaching **~320**. The loop overshot slightly — the dataset is **already at 305**.
So:

- **Reaching ~320 needs only ~15 additions** → that is exactly **Tier 1** below, and **T225 alone
  takes the dataset to ~320.**
- **T226's "next ~15"** would carry the dataset to **~335**. That's fine, but past ~320 the
  additions are deliberately **secondary gaps / popular cultivars** (Tier 2), not core species —
  flagged honestly so reviewers can choose to **stop at ~320** (Tier 1 only) or continue to ~335.
- No silent cap: Tier 1 is sized to the ~320 target; Tier 2 is the documented overflow.

## 2. Target common-plant set & sources

Sources reached in this run (all fetchable):

- **Patch (patchplants.com)** — "most popular indoor plants" surfaced Snake Plant, Peace Lily,
  Kentia Palm, Swiss Cheese Plant (*Monstera deliciosa*), Boston Fern, Fiddle-Leaf Fig, Marble
  Queen Pothos, Chinese Money Plant, Rubber Plant, plus **Devil's Ivy, *Monstera adansonii*,
  ZZ, Calathea, Anthurium, Echeveria, Sansevieria** — **all already in the dataset** except a
  searchable *Monstera adansonii* alias (see Tier 1 #1).
- **Gardeners' World "25 best house plants"** and **DWH "UK's most-searched houseplants"** —
  top searches are **Aloe Vera, Peace Lily, Snake Plant, Spider Plant, ivies** (Aloe/Peace
  Lily/Snake/Spider already present; **English Ivy is a gap**), plus ZZ, Rubber, Money, Dragon,
  Cast Iron, Monstera — all present.
- **Reddit r/houseplants popularity** (via Apartment Therapy / Homedit round-ups) — **Pothos #1,
  then Monstera and Philodendron**; all three genera are already covered deeply. The community
  long-tail trends (Calathea cultivars, *Philodendron gloriosum*, *Alocasia* 'Frydek',
  Peperomia cultivars, fishbone cactus, *Monstera adansonii*) inform Tiers 1–2.

Where a specific interval couldn't be pinned to a fetched per-species page, the **genus/type
anchor** from `uk-houseplants.md` is used and recorded as the rationale (same rule the existing
dataset follows). Sources column below uses `RHS`, `Patch`, `Hortology`, or `anchor` accordingly.

## 3. Prioritised gap list

`moisture` and `base / min–max` (days) are the proposed `CareProfile` values for T225/T226 to
ship; each must still pass the T004 validator and get a Provenance row in `uk-houseplants.md`.

### Tier 1 — top ~15 (→ dataset ~320, for **T225**; **includes Monstera adansonii**)

| # | Species (display name) | Scientific name | moisture | base / min–max | Source / rationale |
|---|---|---|---|---|---|
| 1 | **Monstera adansonii** | *Monstera adansonii* | evenlyMoist | 8 / 5–12 | **Patch** lists it by this name; the **profile already exists as "Swiss Cheese Vine"** — add the botanical-name **alias** so the picker finds it, mirroring the **Pothos / Golden Pothos** alias precedent. (Required by T224.) |
| 2 | Bird of Paradise | *Strelitzia reginae* | evenlyMoist | 7 / 5–12 | RHS / Patch — large thirsty leaves in growth, keep evenly moist spring–summer, let surface dry, much drier in winter. New genus. |
| 3 | Giant White Bird of Paradise | *Strelitzia nicolai* | evenlyMoist | 8 / 6–14 | Hortology / Patch — bigger, more drought-tolerant than *reginae*; water when top few cm dry. |
| 4 | English Ivy | *Hedera helix* | evenlyMoist | 6 / 4–9 | RHS / DWH most-searched — keep lightly moist, water when surface starts to dry; dislikes both drought and waterlogging. New genus. |
| 5 | Norfolk Island Pine | *Araucaria heterophylla* | evenlyMoist | 7 / 5–12 | RHS — keep evenly moist in growth, let top 2–3 cm dry; resents drying out fully (drops needles). New genus. |
| 6 | Fishbone Cactus | *Disocactus anguliger* (syn. *Epiphyllum anguliger*) | evenlyMoist | 9 / 6–14 | RHS / Hortology — forest (epiphytic) cactus; treat like Christmas cactus — water when top third dries, never bone-dry. |
| 7 | Living Stones | *Lithops* spp. | driesOut | 21 / 14–35 | RHS — extreme xerophyte; water very sparingly only in active growth, none during leaf-renewal dormancy → longest interval in the set. |
| 8 | Calathea Network | *Goeppertia kegeljanii* 'Network' (*Calathea musaica*) | staysMoist | 4 / 3–6 | Patch / Hortology — calathea anchor; keep consistently moist with soft water, never let it dry out. |
| 9 | Calathea White Fusion | *Calathea lietzei* 'White Fusion' | staysMoist | 4 / 3–6 | Hortology — variegated, thirsty and fussy; keep evenly moist, soft water, high humidity. |
| 10 | Calathea Medallion | *Goeppertia veitchiana* 'Medallion' | staysMoist | 4 / 3–6 | Hortology — calathea anchor; keep moist, never soggy or bone-dry. |
| 11 | Philodendron Gloriosum | *Philodendron gloriosum* | evenlyMoist | 8 / 5–12 | Patch — crawling velvet-leaf aroid; aroid anchor, water when top 2–3 cm dry. |
| 12 | Alocasia Frydek | *Alocasia micholitziana* 'Frydek' | evenlyMoist | 7 / 5–10 | Hortology — green-velvet alocasia; keep evenly moist in growth, let surface dry, sensitive to over/under-watering. |
| 13 | Peperomia Hope | *Peperomia tetraphylla* 'Hope' | evenlyMoist | 9 / 7–14 | Hortology — peperomia anchor; semi-succulent trailing leaves, let top half dry between waterings. |
| 14 | Peperomia Rosso | *Peperomia caperata* 'Rosso' | evenlyMoist | 9 / 7–14 | Hortology — peperomia anchor; water when top 2–3 cm dry, store water in fleshy leaves. |
| 15 | Dwarf Banana | *Musa acuminata* 'Dwarf Cavendish' | staysMoist | 5 / 3–8 | RHS — very thirsty fast grower; keep compost consistently moist in growth, never dry out. New genus. |

### Tier 2 — next ~15 (→ ~335 if pursued, for **T226**; secondary gaps / popular cultivars)

| # | Species (display name) | Scientific name | moisture | base / min–max | Source / rationale |
|---|---|---|---|---|---|
| 16 | Aglaonema Pink | *Aglaonema* 'Pink Dalmatian' | evenlyMoist | 9 / 6–14 | Patch — aglaonema anchor; water when top 2–3 cm dry, drought-tolerant. |
| 17 | Philodendron Florida Ghost | *Philodendron pedatum* 'Florida Ghost' | evenlyMoist | 8 / 5–12 | Patch — aroid anchor; climber, let top 2–3 cm dry. |
| 18 | Philodendron Imperial Red | *Philodendron* 'Imperial Red' | evenlyMoist | 9 / 6–14 | Hortology — self-heading aroid; water when top third dries. |
| 19 | Monstera Peru | *Monstera karstenianum* | evenlyMoist | 9 / 6–14 | Hortology — thick puckered leaves store water; aroid anchor, let top half dry. |
| 20 | Alocasia Stingray | *Alocasia macrorrhiza* 'Stingray' | evenlyMoist | 7 / 5–10 | Hortology — alocasia anchor; keep evenly moist, let surface dry. |
| 21 | Calathea Freddie | *Goeppertia concinna* 'Freddie' | staysMoist | 4 / 3–6 | Hortology — calathea anchor; keep consistently moist, soft water. |
| 22 | Calathea Beauty Star | *Goeppertia* 'Beauty Star' | staysMoist | 4 / 3–6 | Hortology — calathea anchor; never dry out, high humidity. |
| 23 | Peperomia Frost | *Peperomia caperata* 'Frost' | evenlyMoist | 9 / 7–14 | Hortology — peperomia anchor; let top half dry. |
| 24 | Hoya Mathilde | *Hoya* × *mathilde* | evenlyMoist | 11 / 8–18 | Hortology — hoya anchor (cf. *H. carnosa*); let top two-thirds dry, semi-succulent leaves. |
| 25 | String of Needles | *Ceropegia linearis* | driesOut | 14 / 10–21 | anchor (Ceropegia, cf. String of Hearts) — semi-succulent trailer with tubers; soak-and-dry, water when dry. |
| 26 | Sansevieria Fernwood | *Dracaena pethera* 'Fernwood' | driesOut | 14 / 10–24 | anchor (Sansevieria/Dracaena) — narrow upright succulent leaves; dry out fully between waterings. |
| 27 | Calathea Dottie | *Goeppertia roseopicta* 'Dottie' | staysMoist | 4 / 3–6 | Hortology — calathea anchor; keep moist, never soggy. |
| 28 | Anthurium Black | *Anthurium* 'Black Beauty' | evenlyMoist | 7 / 5–10 | Hortology — anthurium anchor (cf. Flamingo Flower); water when top third dries. |
| 29 | Tradescantia Lilac | *Tradescantia* 'Lilac' (*T. fluminensis*) | evenlyMoist | 7 / 5–10 | anchor (Tradescantia/inch plant) — vigorous trailer; keep lightly moist, let top inch dry. |
| 30 | Pilea Norfolk | *Pilea spruceana* 'Norfolk' | evenlyMoist | 6 / 4–10 | anchor (Pilea, cf. Friendship Plant) — keep evenly moist, water when surface dries. |

## 4. Validation & notes for the gap-fill tasks (T225/T226)

- **No duplicates:** every Tier-1/2 name above was checked against the 305 shipped species and is
  absent. Monstera adansonii (#1) is the one **deliberate alias** — its care numbers intentionally
  match the existing "Swiss Cheese Vine" profile; this is allowed (it's a distinct display
  **name**, like Pothos / Golden Pothos), not a normalised-key duplicate.
- **Validator:** all proposed `base / min–max` triples satisfy `min ≤ base ≤ max`, and every
  `moisture` is one of `driesOut` / `evenlyMoist` / `staysMoist`.
- **Provenance:** T225/T226 must add one row per plant to `uk-houseplants.md` with the source or
  anchor rationale, exactly as the existing rows do.
- **Sizing:** **Tier 1 → ~320** (the T224 target). Tier 2 is the documented overflow toward ~335
  for T226; reviewers may stop after Tier 1 if ~320 is the firm ceiling.

## 5. Final reconciliation (T227) — gap list closed, dataset validated

End-to-end audit of the assembled dataset after T225 (Tier 1) and T226 (Tier 2), reconciling the
JSON, the Provenance index, and this gap list against each other. **All checks pass:**

- **Count:** **335 unique** species in `care_database.json` — comfortably past the `Done-when`
  floor (**≥ 315**) and the ~320 core target. Final **moisture split:** `evenlyMoist` 192 ·
  `driesOut` 91 · `staysMoist` 52 (the +30 since the T224 baseline of 305 is the Tier-1 + Tier-2
  fill — aroid/calathea/peperomia/succulent-heavy, matching the gap list's shape).
- **No duplicates:** all 335 display names are distinct under the validator's normalised key
  (trim + lowercase) — 0 collisions.
- **Every record valid:** all 335 satisfy the T004 single-record invariant
  (`min ≤ base ≤ max`, `moisture ∈ {driesOut, evenlyMoist, staysMoist}`). The shipped-dataset
  unit test (`testShippedDatabaseDecodesAndValidates`) loads and validates the whole file green.
- **Provenance 1:1:** the Provenance index in [`uk-houseplants.md`](./uk-houseplants.md) holds
  **335 rows**, one per species — **0** JSON species without a row and **0** rows without a JSON
  species. Both the *Monstera adansonii* alias and its "Swiss Cheese Vine" twin carry their own
  rows.
- **Gap list closed:** **all 30** Tier-1 (15) + Tier-2 (15) rows from §3 are present in the JSON
  by display name — including the required *Monstera adansonii* entry (#1), shipped as a
  display-name alias of "Swiss Cheese Vine" with identical care numbers. **No remaining gaps.**

**Residual (justified, not a gap):** a share of cultivar intervals (calatheas, peperomias,
philodendron/alocasia/aglaonema/hoya/anthurium cultivars) are grounded on the **genus anchor**
rather than a per-cultivar citation, recorded as such in each Provenance row — the same
"never block a batch for lack of a fetchable per-species page" convention the original dataset
follows. This is acceptable for a *starting* watering cadence the check-in loop then adapts; see
the care-DB rows in [`../LIMITATIONS.md`](../LIMITATIONS.md).
