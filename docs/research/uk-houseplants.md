# Research — UK common houseplant watering database

Provenance + method for `Sprout/Resources/care_database.json`, the bundled local dataset of the
**~300 most common UK houseplants**. Built **by the loop**, 10 plants per task (T101–T130), each
plant given a genuine look-up. T131 reviews the finished set. Schema + how the numbers are used:
[`../designs/adaptive-watering.md`](../designs/adaptive-watering.md).

## Scope

- **Watering only.** Per plant: `baseIntervalDays`, `minIntervalDays`, `maxIntervalDays`,
  `moisture` (`driesOut` / `evenlyMoist` / `staysMoist`). No light/humidity/toxicity for now.
- **UK homes**, typical indoor conditions, a **spring/summer baseline** interval (the engine's
  `weatherFactor` and the per-plant `adj` handle season, weather, and personalisation — so these
  are **starting points**, not precise prescriptions).
- **~300 species**, no duplicates. Scaling further / user-added plants is out of scope.

## Sourcing rules (apply to every plant)

1. Prefer authoritative UK guidance — **RHS (rhs.org.uk)** first, then reputable nurseries/growers
   (e.g. Patch, Hortology, Beards & Daisies) and well-established horticultural references.
2. Map the plant to a **`moisture` preference** from its genus/type and the guidance:
   - `driesOut` — succulents, cacti, sansevieria, ZZ, ponytail palm, most euphorbia.
   - `evenlyMoist` — most foliage/aroids (pothos, monstera, philodendron), figs, palms, peperomia.
   - `staysMoist` — ferns, calatheas/marantas, fittonia, carnivorous, baby's tears.
3. Set `baseIntervalDays` to a sensible indoor spring/summer cadence for that plant, with
   `min`/`max` bracketing the realistic range (always `min ≤ base ≤ max`). When unsure, lean on
   the genus default below and note the uncertainty.
4. **Record each plant** in the Provenance index (one row): common name, scientific name, the
   `moisture`/interval chosen, and the **source** it was grounded in. If web research isn't
   available in the run, ground the plant in the genus/type defaults below and record that as the
   rationale — never block a batch purely for lack of a fetchable citation.

## Genus / type defaults (sanity anchors, days)

| Type | moisture | base | min–max |
|---|---|---|---|
| Cacti / desert succulents | `driesOut` | 14 | 10–28 |
| Leaf succulents (echeveria, jade, haworthia) | `driesOut` | 12 | 9–21 |
| Sansevieria / ZZ / ponytail | `driesOut` | 14 | 10–24 |
| Aroids (pothos, monstera, philodendron, syngonium) | `evenlyMoist` | 8 | 5–12 |
| Peace lily / spathiphyllum | `evenlyMoist` | 6 | 4–9 |
| Figs / ficus (rubber, fiddle-leaf) | `evenlyMoist` | 8 | 6–12 |
| Palms (parlour, areca, kentia) | `evenlyMoist` | 7 | 5–10 |
| Peperomia | `evenlyMoist` | 9 | 7–14 |
| Spider plant / chlorophytum | `evenlyMoist` | 7 | 5–10 |
| Begonia | `evenlyMoist` | 6 | 4–9 |
| Ferns (boston, maidenhair, bird's nest) | `staysMoist` | 4 | 2–6 |
| Calathea / maranta / prayer plants | `staysMoist` | 4 | 3–6 |
| Fittonia / nerve plant / baby's tears | `staysMoist` | 3 | 2–5 |
| Orchids (phalaenopsis) | `evenlyMoist` | 7 | 5–10 |
| Carnivorous (flytrap, sundew, pitcher) | `staysMoist` | 2 | 1–4 |

> These are anchors. A specific species can and should deviate when its guidance says so — that's
> the "real good look in" each plant gets in its batch.

## Batch plan — 30 batches × 10 plants (T101–T130)

Each batch owns a category so coverage is even and duplicates are unlikely. A batch adds **10 new
unique species** in its area that aren't already in the dataset; if its category is exhausted, it
pulls the next-most-common UK houseplants not yet present and notes the spill-over here.

| Batch | Task | Category / genera |
|---|---|---|
| 01 | T101 | Pothos & Epipremnum cultivars (golden, marble, neon, satin/Scindapsus…) |
| 02 | T102 | Philodendron — climbing & upright (heartleaf, brasil, birkin, congo…) |
| 03 | T103 | Monstera, Rhaphidophora, Syngonium |
| 04 | T104 | Aroids — Anthurium, Aglaonema, Spathiphyllum |
| 05 | T105 | Alocasia, Colocasia, Caladium |
| 06 | T106 | ZZ, Dracaena (marginata, fragrans, lucky bamboo), Cordyline |
| 07 | T107 | Sansevieria / snake plants & cultivars |
| 08 | T108 | Echeveria, Graptopetalum, Pachyphytum & rosette succulents |
| 09 | T109 | Crassula (jade), Sedum, Sempervivum |
| 10 | T110 | Haworthia, Gasteria, Aloe |
| 11 | T111 | Kalanchoe, Senecio & trailing succulents (string-of-pearls/hearts/dolphins) |
| 12 | T112 | Cacti I — Mammillaria, Gymnocalycium, Echinopsis, Opuntia |
| 13 | T113 | Cacti II + holiday cacti (Schlumbergera), Euphorbia (trigona, milii) |
| 14 | T114 | Ferns — Boston, maidenhair, bird's nest, blue star, button |
| 15 | T115 | Calathea / Goeppertia & Maranta (prayer plants) |
| 16 | T116 | Ctenanthe, Stromanthe, Fittonia, Pilea (incl. peperomioides) |
| 17 | T117 | Peperomia — common cultivars |
| 18 | T118 | Begonia — rex, maculata, rhizomatous |
| 19 | T119 | Tradescantia, Callisia & inch plants; Ceropegia |
| 20 | T120 | Spider plant, Chlorophytum, Asparagus fern, Aspidistra (cast-iron) |
| 21 | T121 | Palms — parlour, areca, kentia, majesty, ponytail |
| 22 | T122 | Ficus — rubber, fiddle-leaf, weeping fig, ginseng |
| 23 | T123 | Large foliage — Schefflera, Dieffenbachia, Yucca, Pachira (money tree) |
| 24 | T124 | Hoya — common wax plants |
| 25 | T125 | Orchids — Phalaenopsis & common houseplant orchids |
| 26 | T126 | Bromeliads — Guzmania, Aechmea, Vriesea, Neoregelia, Tillandsia (air plants) |
| 27 | T127 | Flowering — African violet, cyclamen, anthurium (if new), kalanchoe blossfeldiana |
| 28 | T128 | Carnivorous — Venus flytrap, sundew, pitcher (Sarracenia/Nepenthes) |
| 29 | T129 | Indoor herbs & edibles — basil, mint, chilli, citrus (calamondin), coffee |
| 30 | T130 | Catch-all — remaining common UK houseplants to reach ~300 (Aeschynanthus, Hypoestes, Coleus, Oxalis, Maranta gaps…) |

## Provenance index (the loop appends here, one row per plant)

> Format: `| Common name | Scientific name | moisture | base/min–max | Source |`
> Each batch task appends its 10 rows below and ticks its row in the batch plan.

| Common name | Scientific name | moisture | base/min–max | Source |
|---|---|---|---|---|
| _(none yet — T101 onward fill this)_ | | | | |
