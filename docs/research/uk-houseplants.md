# Research — UK common houseplant watering database

Provenance + method for `Sources/Resources/care_database.json`, the bundled local dataset of the
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
| 01 ✅ | T101 | Pothos & Epipremnum cultivars (golden, marble, neon, satin/Scindapsus…) |
| 02 ✅ | T102 | Philodendron — climbing & upright (heartleaf, brasil, birkin, congo…) |
| 03 ✅ | T103 | Monstera, Rhaphidophora, Syngonium |
| 04 ✅ | T104 | Aroids — Anthurium, Aglaonema, Spathiphyllum |
| 05 ✅ | T105 | Alocasia, Colocasia, Caladium |
| 06 ✅ | T106 | ZZ, Dracaena (marginata, fragrans, lucky bamboo), Cordyline |
| 07 ✅ | T107 | Sansevieria / snake plants & cultivars |
| 08 ✅ | T108 | Echeveria, Graptopetalum, Pachyphytum & rosette succulents |
| 09 ✅ | T109 | Crassula (jade), Sedum, Sempervivum |
| 10 ✅ | T110 | Haworthia, Gasteria, Aloe |
| 11 ✅ | T111 | Kalanchoe, Senecio & trailing succulents (string-of-pearls/hearts/dolphins) |
| 12 | T112 | Cacti I — Mammillaria, Gymnocalycium, Echinopsis, Opuntia |
| 13 ✅ | T113 | Cacti II + holiday cacti (Schlumbergera), Euphorbia (trigona, milii) |
| 14 ✅ | T114 | Ferns — Boston, maidenhair, bird's nest, blue star, button |
| 15 ✅ | T115 | Calathea / Goeppertia & Maranta (prayer plants) |
| 16 ✅ | T116 | Ctenanthe, Stromanthe, Fittonia, Pilea (incl. peperomioides) |
| 17 ✅ | T117 | Peperomia — common cultivars |
| 18 ✅ | T118 | Begonia — rex, maculata, rhizomatous |
| 19 ✅ | T119 | Tradescantia, Callisia & inch plants; Ceropegia |
| 20 ✅ | T120 | Spider plant, Chlorophytum, Asparagus fern, Aspidistra (cast-iron) |
| 21 ✅ | T121 | Palms — parlour, areca, kentia, majesty, ponytail |
| 22 ✅ | T122 | Ficus — rubber, fiddle-leaf, weeping fig, ginseng |
| 23 ✅ | T123 | Large foliage — Schefflera, Dieffenbachia, Yucca, Pachira (money tree) |
| 24 ✅ | T124 | Hoya — common wax plants |
| 25 ✅ | T125 | Orchids — Phalaenopsis & common houseplant orchids |
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
| Golden Pothos | Epipremnum aureum | evenlyMoist | 8 / 6–14 | The Sill / Happy Houseplants (UK) — water every 1–2 weeks, let top 2" dry |
| Marble Queen Pothos | Epipremnum aureum 'Marble Queen' | evenlyMoist | 9 / 6–14 | Genus anchor (aroid) + heavy white variegation → slower growth, slightly longer interval |
| Neon Pothos | Epipremnum aureum 'Neon' | evenlyMoist | 8 / 5–12 | Genus anchor (aroid); full-chlorophyll cultivar, standard pothos cadence |
| Jade Pothos | Epipremnum aureum 'Jade' | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); solid-green pothos, standard cadence |
| Pearls and Jade Pothos | Epipremnum aureum 'Pearls and Jade' | evenlyMoist | 9 / 6–14 | Genus anchor (aroid) + variegation → slightly longer interval |
| Manjula Pothos | Epipremnum aureum 'Manjula' | evenlyMoist | 9 / 6–14 | Genus anchor (aroid) + heavy variegation → slightly longer interval |
| Snow Queen Pothos | Epipremnum aureum 'Snow Queen' | evenlyMoist | 10 / 7–14 | Genus anchor (aroid); near-white leaves, least chlorophyll → longest pothos interval |
| Cebu Blue Pothos | Epipremnum pinnatum 'Cebu Blue' | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); standard pothos cadence |
| Satin Pothos | Scindapsus pictus 'Argyraeus' | evenlyMoist | 10 / 7–16 | The Sill / Smart Garden Guide — semi-succulent leaves, tolerant of under-watering → longer interval |
| Silver Satin Pothos | Scindapsus pictus 'Exotica' | evenlyMoist | 10 / 7–16 | Smart Garden Guide / Leafy Place — Scindapsus, let top 2" dry; more drought-tolerant than Epipremnum |
| Heartleaf Philodendron | Philodendron hederaceum | evenlyMoist | 8 / 6–14 | RHS / ukhouseplants.com — allow top third to dry; "consumes relatively little water for its size" |
| Philodendron Brasil | Philodendron hederaceum 'Brasil' | evenlyMoist | 8 / 6–14 | Genus anchor (aroid); variegated heartleaf cultivar, same cadence as the species |
| Velvet Leaf Philodendron | Philodendron hederaceum var. hederaceum 'Micans' | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); velvet-leaf trailing form, standard heartleaf cadence |
| Philodendron Lemon Lime | Philodendron hederaceum 'Lemon Lime' | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); full-chlorophyll chartreuse cultivar, standard heartleaf cadence |
| Philodendron Birkin | Philodendron 'Birkin' | evenlyMoist | 9 / 6–14 | Plant Care for Beginners / Apartment Therapy — let top 2" dry; slower variegated self-header → slightly longer interval |
| Blushing Philodendron | Philodendron erubescens | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); climbing erubescens species, standard aroid cadence |
| Pink Princess Philodendron | Philodendron erubescens 'Pink Princess' | evenlyMoist | 9 / 6–14 | Genus anchor (aroid) + heavy pink variegation → slower growth, slightly longer interval |
| Philodendron Prince of Orange | Philodendron 'Prince of Orange' | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); self-heading erubescens hybrid, standard aroid cadence |
| Philodendron Xanadu | Thaumatophyllum xanadu (syn. Philodendron xanadu) | evenlyMoist | 9 / 6–14 | Genus anchor (aroid); robust upright clump with thicker stems holding water → slightly longer interval |
| Tree Philodendron | Thaumatophyllum bipinnatifidum (syn. Philodendron bipinnatifidum) | evenlyMoist | 9 / 6–14 | Genus anchor (aroid); large self-heading "selloum", robust → slightly longer interval |
| Swiss Cheese Vine | Monstera adansonii | evenlyMoist | 8 / 5–12 | Lively Root / Joy Us Garden — water no more than ~weekly, every 7–9 days in warm months; let top inch dry, prone to root rot |
| Variegated Monstera | Monstera deliciosa 'Thai Constellation' | evenlyMoist | 10 / 7–16 | Genus anchor (aroid) + heavy cream variegation → much less chlorophyll, slower growth → longest Monstera interval |
| Silver Monstera | Monstera siltepecana | evenlyMoist | 9 / 6–14 | Genus anchor (aroid); semi-succulent silvery juvenile leaves tolerate drying → slightly longer interval |
| Shingle Plant | Monstera dubia | evenlyMoist | 8 / 5–12 | Genus anchor (aroid); shingling climber, standard Monstera cadence |
| Five Holes Plant | Monstera standleyana | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); standard Monstera cadence |
| Mini Monstera | Rhaphidophora tetrasperma | evenlyMoist | 8 / 5–12 | Our House Plants / Patch — water every 1–2 weeks (~7 days in warm months); let top half dry, root rot if kept soggy |
| Dragon Tail Plant | Rhaphidophora decursiva | evenlyMoist | 8 / 6–12 | Genus anchor (aroid); vigorous Rhaphidophora climber, standard aroid cadence |
| Arrowhead Plant | Syngonium podophyllum | evenlyMoist | 7 / 5–10 | RHS / Happy Houseplants (UK) — keep slightly moist in growth, water ~weekly in summer, let top inch dry |
| Syngonium White Butterfly | Syngonium podophyllum 'White Butterfly' | evenlyMoist | 7 / 5–10 | Genus anchor (aroid); pale-leaved arrowhead cultivar, same cadence as the species |
| Pink Syngonium | Syngonium podophyllum 'Pink Allusion' | evenlyMoist | 8 / 5–12 | Genus anchor (aroid) + pink variegation → slightly less chlorophyll → marginally longer interval |
| Flamingo Flower | Anthurium andraeanum | evenlyMoist | 7 / 5–11 | RHS — water freely spring–autumn (~weekly in growth), let top inch dry, water sparingly in winter |
| Pigtail Anthurium | Anthurium scherzerianum | evenlyMoist | 7 / 5–11 | Genus anchor (Anthurium) — flowering species, same evenly-moist cadence as A. andraeanum |
| Velvet Cardboard Anthurium | Anthurium clarinervium | evenlyMoist | 8 / 6–12 | Smart Garden Guide / Rooted Hues — let top 1–2" (~80%) dry, never bone-dry nor soggy; velvet-leaf → slightly longer/drier than flowering anthuriums |
| Crystal Anthurium | Anthurium crystallinum | evenlyMoist | 8 / 6–12 | Odd Leaf (UK) — velvet-leaf, keep lightly moist and let top dry between waterings; same cadence as clarinervium |
| Chinese Evergreen | Aglaonema commutatum | evenlyMoist | 9 / 7–14 | Gardenia / Chelsea Garden Center — water every 7–10 days; thick stems store moisture, somewhat drought-tolerant → longer interval |
| Aglaonema Silver Bay | Aglaonema 'Silver Bay' | evenlyMoist | 9 / 7–14 | Genus anchor (Aglaonema) — robust variegated cultivar, standard Chinese-evergreen cadence |
| Aglaonema Silver Queen | Aglaonema 'Silver Queen' | evenlyMoist | 9 / 7–14 | Genus anchor (Aglaonema) — classic cultivar, standard Chinese-evergreen cadence |
| Red Aglaonema | Aglaonema 'Siam Aurora' | evenlyMoist | 9 / 7–14 | Genus anchor (Aglaonema) — pink/red cultivar with moisture-storing stems, standard Chinese-evergreen cadence |
| Sensation Peace Lily | Spathiphyllum 'Sensation' | evenlyMoist | 6 / 4–9 | Love That Leaf — giant peace lily; keep evenly moist, good drench every 1–2 weeks, droops when thirsty |
| Domino Peace Lily | Spathiphyllum 'Domino' | evenlyMoist | 6 / 4–9 | Genus anchor (Spathiphyllum) — variegated peace lily, same keep-evenly-moist cadence as the species |
| Alocasia Polly | Alocasia × amazonica 'Polly' | evenlyMoist | 7 / 5–11 | The Little Botanical / Plant Care for Beginners — water ~every 5–7 days, let top 2.5 cm dry; thick stems store moisture so don't keep soggy |
| Kris Plant | Alocasia sanderiana | evenlyMoist | 7 / 5–11 | Genus anchor (Alocasia) — parent species of 'Polly', same let-top-inch-dry cadence |
| Giant Taro | Alocasia macrorrhizos | evenlyMoist | 7 / 5–11 | Genus anchor (Alocasia) — large upright elephant ear; thirsty in growth but let top inch dry, robust storage stem |
| Alocasia Zebrina | Alocasia zebrina | evenlyMoist | 7 / 5–12 | Genus anchor (Alocasia) — let top of soil dry between waterings; zebra-stem storage tolerates slight drying → wider max |
| Alocasia Dragon Scale | Alocasia baginda 'Dragon Scale' | evenlyMoist | 9 / 6–14 | Genus anchor (jewel Alocasia) — let top 50–75% dry (cf. Black Velvet guidance); slower-growing jewel → longer interval |
| Alocasia Black Velvet | Alocasia reginula | evenlyMoist | 9 / 6–14 | Smart Garden Guide / Soltech — allow top 50–75% of soil to dry between waterings; small slow jewel alocasia → longest Alocasia interval |
| Taro | Colocasia esculenta | staysMoist | 4 / 2–7 | Gardeners' World / Gardenia — bog plant, loves wet soil, "never allow to dry out"; keep constantly moist, may need daily water in heat |
| Black Magic Elephant Ear | Colocasia esculenta 'Black Magic' | staysMoist | 4 / 2–7 | Genus anchor (Colocasia) — dark-leaved esculenta cultivar, same keep-wet bog cadence as the species |
| Angel Wings | Caladium bicolor | evenlyMoist | 5 / 3–8 | Patch / ukhouseplants — keep evenly/lightly moist in growth, water when top 2–3 cm dry; tubers rot if waterlogged, drier in winter dormancy |
| Caladium White Christmas | Caladium 'White Christmas' | evenlyMoist | 5 / 3–8 | Genus anchor (Caladium) — white-leaved cultivar, same keep-lightly-moist cadence as C. bicolor |
| ZZ Plant | Zamioculcas zamiifolia | driesOut | 14 / 10–24 | Lively Root / The Sill — rhizomes store water, let soil dry ~100%, water every 2–3 weeks; root rot if overwatered |
| Raven ZZ | Zamioculcas zamiifolia 'Raven' | driesOut | 14 / 10–24 | Genus anchor (ZZ) — black-leaved cultivar, same drought-tolerant rhizome cadence as the species |
| ZZ Zenzi | Zamioculcas zamiifolia 'Zenzi' | driesOut | 14 / 10–24 | Genus anchor (ZZ) — compact dwarf cultivar, same store-water-and-dry-out cadence as the species |
| Dragon Tree | Dracaena marginata | driesOut | 12 / 8–21 | House Plant Resource Center / Soltech — let top 50% dry, water every 2–3 weeks; overwatering is the #1 killer |
| Corn Plant | Dracaena fragrans | driesOut | 11 / 7–18 | Healthy Houseplants / Leafy Place — keep slightly moist but tolerates under-watering, water when top 2.5–5 cm dry (~1–2 weeks) |
| Janet Craig Dracaena | Dracaena fragrans 'Janet Craig' | driesOut | 11 / 7–18 | Genus anchor (Dracaena fragrans) — dark-green cultivar, same let-top-inch-dry cadence as the species |
| Lemon Lime Dracaena | Dracaena fragrans 'Lemon Lime' | driesOut | 11 / 7–18 | Genus anchor (Dracaena fragrans) — variegated cultivar, same let-top-inch-dry cadence as the species |
| Song of India | Dracaena reflexa | driesOut | 12 / 8–21 | Genus anchor (Dracaena) — woody cane shrub, let top half dry between waterings like D. marginata |
| Lucky Bamboo | Dracaena sanderiana | evenlyMoist | 7 / 5–10 | Genus anchor (Dracaena, water-grown form) — usually grown in water; in soil keep consistently moist, never let dry fully |
| Hawaiian Ti Plant | Cordyline fruticosa | evenlyMoist | 6 / 4–10 | Almanac / Bouqs — likes consistently/evenly moist soil (not soggy), water when top 1–2" dry; chlorine-sensitive |
| Variegated Snake Plant | Sansevieria trifasciata 'Laurentii' | driesOut | 14 / 10–28 | Greenery Unlimited / Bloomscape — water every ~2 weeks, only when soil dry all through; overwatering is the #1 killer |
| Moonshine Snake Plant | Sansevieria trifasciata 'Moonshine' | driesOut | 14 / 10–24 | Genus anchor (Sansevieria) — silvery trifasciata cultivar, same let-soil-dry-fully every 2–3 weeks cadence |
| Bird's Nest Snake Plant | Sansevieria trifasciata 'Hahnii' | driesOut | 14 / 10–24 | Genus anchor (Sansevieria) — compact rosette trifasciata, same dry-out cadence; less leaf mass but same drought tolerance |
| Golden Birds Nest Snake Plant | Sansevieria trifasciata 'Golden Hahnii' | driesOut | 14 / 10–24 | Genus anchor (Sansevieria) — gold-margined dwarf rosette, same trifasciata dry-out cadence |
| Cylindrical Snake Plant | Sansevieria cylindrica | driesOut | 16 / 12–30 | Joy Us Garden / Bloomscape — thick cylindrical leaves store water, very drought-tolerant; water every 2–4 weeks, dry out fully |
| Starfish Snake Plant | Sansevieria cylindrica 'Boncel' | driesOut | 16 / 12–30 | Genus anchor (S. cylindrica) — fan-shaped cylindrical cultivar, same thick-leaf dry-out cadence as the species |
| Whale Fin Snake Plant | Sansevieria masoniana | driesOut | 16 / 12–30 | Plant Orbit / Ohio Tropics — single thick paddle leaf stores water, dry out completely, water every 2–3 weeks (monthly in winter) |
| Ceylon Bowstring Hemp | Sansevieria zeylanica | driesOut | 14 / 10–28 | Genus anchor (Sansevieria) — dark-banded upright species, same trifasciata-type dry-out cadence |
| White Snake Plant | Sansevieria trifasciata 'Bantel's Sensation' | driesOut | 14 / 10–24 | Genus anchor (Sansevieria) — slim white-striped cultivar; less chlorophyll but same dry-out cadence |
| Black Coral Snake Plant | Sansevieria trifasciata 'Black Coral' | driesOut | 14 / 10–28 | Genus anchor (Sansevieria) — dark-green trifasciata cultivar, same every-2-weeks dry-out cadence as the species |
| Mexican Snowball | Echeveria elegans | driesOut | 12 / 9–21 | Succulents Box / Plant Orbit — soak-and-dry; water every ~10–14 days in growth, sparingly in winter; rosette stores water, root rot if soggy |
| Black Prince Echeveria | Echeveria 'Black Prince' | driesOut | 12 / 9–21 | Genus anchor (leaf succulent) — dark hybrid rosette, standard echeveria soak-and-dry cadence |
| Perle von Nurnberg Echeveria | Echeveria 'Perle von Nürnberg' | driesOut | 12 / 9–21 | Genus anchor (leaf succulent) — classic pastel hybrid rosette, standard echeveria soak-and-dry cadence |
| Lipstick Echeveria | Echeveria agavoides | driesOut | 13 / 9–21 | Genus anchor (leaf succulent) — thick agave-like leaves store extra water → slightly longer base than the genus anchor |
| Echeveria Lola | Echeveria 'Lola' | driesOut | 12 / 9–21 | Genus anchor (leaf succulent) — compact agavoides×lilacina hybrid, standard echeveria soak-and-dry cadence |
| Plush Plant | Echeveria pulvinata | driesOut | 12 / 9–21 | Genus anchor (leaf succulent) — fuzzy-leaved shrubby echeveria, standard soak-and-dry cadence |
| Topsy Turvy Echeveria | Echeveria runyonii 'Topsy Turvy' | driesOut | 12 / 9–21 | Genus anchor (leaf succulent) — recurved-leaf runyonii cultivar, standard echeveria soak-and-dry cadence |
| Ghost Plant | Graptopetalum paraguayense | driesOut | 13 / 9–24 | Succulent Plant Care / Garden Beast — especially drought-resistant, soak-and-dry; can wait until leaves slightly shrivel → wider max |
| Ghost Plant Debbie | × Graptoveria 'Debbie' | driesOut | 12 / 9–21 | Genus anchor (leaf succulent) — Graptopetalum × Echeveria hybrid rosette, standard soak-and-dry cadence |
| Moonstones | Pachyphytum oviferum | driesOut | 12 / 9–21 | Succulents Box / World of Succulents — soak-and-dry, every ~1–2 weeks in growth; plump leaves store water, water when they soften/wrinkle |
| Jade Plant | Crassula ovata | driesOut | 14 / 10–24 | Soltech / Joy Us Garden — soak-and-dry; water every 2–3 weeks in warm months, ~monthly in winter; thick water-storing leaves, overwatering is the #1 killer |
| Gollum Jade | Crassula ovata 'Gollum' | driesOut | 14 / 10–24 | Genus anchor (C. ovata cultivar) — tubular-leaved jade, same soak-and-dry cadence as the species |
| Silver Dollar Jade | Crassula arborescens | driesOut | 14 / 10–24 | Genus anchor (jade, Crassula) — thick rounded water-storing leaves, same soak-and-dry cadence as C. ovata |
| String of Buttons | Crassula perforata | driesOut | 12 / 9–18 | Succulent Plant Care / Living House — soak-and-dry; water every 10–14 days in spring/autumn (7–10 in summer), let soil dry fully, root rot if overwatered |
| Watch Chain | Crassula muscosa | driesOut | 12 / 9–18 | Genus anchor (Crassula leaf succulent) — fine stacked foliage, soak-and-dry cadence like other small crassulas |
| Burro's Tail | Sedum morganianum | driesOut | 14 / 10–24 | Healthy Houseplants / Joy Us Garden — water when soil fully dry, ~every 2–3 weeks; plump leaves store water and pucker when thirsty |
| Jelly Bean Plant | Sedum rubrotinctum | driesOut | 13 / 10–21 | Genus anchor (Sedum leaf succulent) — bean-like water-storing leaves, soak-and-dry like S. morganianum |
| Coppertone Stonecrop | Sedum nussbaumerianum | driesOut | 13 / 9–21 | Genus anchor (Sedum leaf succulent) — fleshy rosettes store water, soak-and-dry cadence |
| Common Houseleek | Sempervivum tectorum | driesOut | 14 / 10–24 | Almanac / Gardenia — water every 1–2 weeks in growth (let dry ~an inch deep), every 4–6 weeks in winter; exceptionally drought-tolerant, rots if kept wet |
| Cobweb Houseleek | Sempervivum arachnoideum | driesOut | 14 / 10–24 | Genus anchor (Sempervivum) — alpine rosette storing water in cobwebbed leaves, same infrequent soak-and-dry cadence as S. tectorum |
| Zebra Haworthia | Haworthiopsis fasciata | driesOut | 14 / 10–24 | Joy Us Garden / Ottershaw Cacti — soak-and-dry, water every 2–3 weeks in growth, sparingly in winter; thick leaves store water, far more tolerant of under- than over-watering |
| Zebra Cactus | Haworthiopsis attenuata | driesOut | 14 / 10–24 | Genus anchor (hard-leaved Haworthia) — near-identical care to H. fasciata, soak-and-dry every 2–3 weeks |
| Window Haworthia | Haworthia cooperi | driesOut | 13 / 9–21 | Genus anchor (soft-leaved Haworthia) — translucent window leaves store water but tolerate slightly more frequent watering than hard-leaf types; soak-and-dry |
| Star Window Plant | Haworthia cymbiformis | driesOut | 13 / 9–21 | Genus anchor (soft-leaved Haworthia) — fleshy window-leaf rosette, soak-and-dry like H. cooperi |
| Pearl Plant | Haworthiopsis pumila | driesOut | 14 / 10–24 | Genus anchor (hard-leaved Haworthia) — pearly-tubercled rosette, soak-and-dry every 2–3 weeks like H. fasciata |
| Ox Tongue | Gasteria bicolor | driesOut | 14 / 10–24 | ukhouseplants.com / Gardener's Path — water every 2–3 weeks in growth, monthly in winter; thick fleshy leaves, overwatering is the primary threat |
| Warty Aloe | Gasteria carinata var. verrucosa | driesOut | 14 / 10–24 | Genus anchor (Gasteria) — rough thick-leaved succulent, same soak-and-dry every 2–3 weeks as G. bicolor |
| Aloe Vera | Aloe vera | driesOut | 14 / 10–28 | Old Farmer's Almanac / Joy Us Garden — water every 2–3 weeks spring/summer, every 4–6 weeks in winter; let top third dry, leaves store water (wider max) |
| Lace Aloe | Aristaloe aristata (syn. Aloe aristata) | driesOut | 14 / 10–24 | Genus anchor (aloe relative) — rosette succulent, soak-and-dry every 2–3 weeks like Aloe vera |
| Tiger Tooth Aloe | Aloe juvenna | driesOut | 14 / 10–24 | Genus anchor (Aloe) — small stacking aloe storing water in toothed leaves, soak-and-dry every 2–3 weeks |
| Panda Plant | Kalanchoe tomentosa | driesOut | 14 / 10–24 | Succulents Box / Healthy Houseplants — soak-and-dry, water every 2–3 weeks only when soil is dry; fuzzy leaves store water, overwatering is the #1 killer |
| Paddle Plant | Kalanchoe luciae | driesOut | 14 / 10–24 | Planet Desert / Succulents Box — soak-and-dry, let soil dry out completely between waterings; thick paddle leaves store water, reduce in winter |
| Mother of Thousands | Kalanchoe daigremontiana | driesOut | 14 / 10–24 | Genus anchor (Kalanchoe leaf succulent) — fleshy water-storing leaves, soak-and-dry every 2–3 weeks like K. tomentosa |
| Chandelier Plant | Kalanchoe delagoensis | driesOut | 14 / 10–24 | Genus anchor (Kalanchoe leaf succulent) — tubular water-storing leaves, soak-and-dry every 2–3 weeks |
| Lavender Scallops | Kalanchoe fedtschenkoi | driesOut | 14 / 10–24 | Genus anchor (Kalanchoe leaf succulent) — scalloped fleshy leaves store water, soak-and-dry every 2–3 weeks |
| Felt Bush | Kalanchoe beharensis | driesOut | 14 / 10–24 | Genus anchor (Kalanchoe leaf succulent) — large velvety drought-tolerant leaves, soak-and-dry every 2–3 weeks |
| String of Pearls | Senecio rowleyanus | driesOut | 14 / 10–21 | Between Two Thorns / Gardenia (Curio rowleyanus) — soak-and-dry, every 2–3 weeks in summer, monthly in winter; bead leaves store water, root rot if kept wet |
| String of Bananas | Senecio radicans | driesOut | 14 / 10–21 | Genus anchor (trailing Senecio/Curio) — banana-shaped water-storing leaves, soak-and-dry like string of pearls; slightly more vigorous |
| String of Dolphins | Senecio peregrinus | driesOut | 13 / 9–21 | Succulents Box — soak-and-dry, ~weekly in active growth and monthly in winter; dolphin leaves store water, slightly thirstier hybrid → marginally shorter base |
| Blue Chalksticks | Senecio serpens | driesOut | 14 / 10–24 | Genus anchor (chalk Senecio/Curio) — waxy blue water-storing finger leaves, exceptionally drought-tolerant, soak-and-dry every 2–3 weeks |
| Christmas Cactus | Schlumbergera × buckleyi | evenlyMoist | 10 / 7–21 | Planet Desert / Old Farmer's Almanac — epiphytic forest cactus, water every 7–10 days in growth (more than desert cacti), every 2–3 weeks at winter rest; keep evenly moist when budding or it drops buds |
| Thanksgiving Cactus | Schlumbergera truncata | evenlyMoist | 10 / 7–21 | Bulb Society / genus anchor (Schlumbergera) — epiphytic forest cactus, same 7–10 day growth cadence as Christmas cactus, reduce to 2–3 weeks at winter rest |
| Easter Cactus | Rhipsalidopsis gaertneri (Hatiora gaertneri) | evenlyMoist | 10 / 7–18 | Genus anchor (forest cactus) — epiphytic, keep lightly moist in growth (~weekly), drier between waterings than tropicals but thirstier than desert cacti |
| Mistletoe Cactus | Rhipsalis baccifera | evenlyMoist | 9 / 6–16 | Genus anchor (epiphytic Rhipsalis) — jungle cactus from humid forests, likes more even moisture and humidity than desert cacti; water when top inch dries |
| Bunny Ears Cactus | Opuntia microdasys | driesOut | 21 / 14–35 | Planet Desert / Epic Gardening — desert cactus, soak-and-dry every 2–3 weeks in growth, monthly or less in winter dormancy; root rot if overwatered |
| Golden Barrel Cactus | Echinocactus grusonii | driesOut | 21 / 14–42 | Botanical Boys / Nick's Garden Center — soak-and-dry, water deeply ~twice a month in summer and every 6–8 weeks in winter; very drought-tolerant globular cactus (wider max) |
| Old Lady Cactus | Mammillaria hahniana | driesOut | 18 / 12–35 | Genus anchor (Mammillaria) — globular desert cactus storing water in its body, soak-and-dry every 2–3 weeks in growth, sparingly in winter |
| Powder Puff Cactus | Mammillaria bocasana | driesOut | 18 / 12–35 | Genus anchor (Mammillaria) — clustering globular desert cactus, same soak-and-dry every 2–3 weeks cadence as M. hahniana |
| Bishop's Cap Cactus | Astrophytum myriostigma | driesOut | 21 / 14–35 | Genus anchor (desert cactus) — slow ribbed globular cactus, soak-and-dry every ~3 weeks in growth, very sparingly in winter |
| Peruvian Apple Cactus | Cereus repandus | driesOut | 21 / 14–35 | Genus anchor (columnar desert cactus) — thick water-storing stem, soak-and-dry every ~3 weeks in growth, monthly or less in winter |
| Moon Cactus | Gymnocalycium mihanovichii | driesOut | 16 / 10–28 | Gardenia / Succulents & Sunshine — water ~every 2 weeks and let soil dry out completely; grafted onto a tropical Hylocereus rootstock that rots if overwatered → slightly thirstier base than pure desert globulars |
| Fairy Castle Cactus | Acanthocereus tetragonus | driesOut | 18 / 12–35 | Genus anchor (columnar desert cactus) — branching water-storing stems, soak-and-dry every ~3 weeks in growth, very sparingly in winter |
| Rat Tail Cactus | Disocactus flagelliformis | evenlyMoist | 10 / 7–18 | Genus anchor (epiphytic/forest cactus) — trailing jungle cactus wanting more even moisture than desert cacti; water ~weekly in growth, let top inch dry, reduce at winter rest |
| Star Cactus | Astrophytum asterias | driesOut | 21 / 14–35 | Genus anchor (Astrophytum, cf. A. myriostigma) — slow flattened ribbed globular cactus, soak-and-dry every ~3 weeks in growth, very sparingly in winter |
| Ladyfinger Cactus | Mammillaria elongata | driesOut | 18 / 12–35 | Genus anchor (Mammillaria, cf. M. hahniana/bocasana) — clustering finger-like desert cactus storing water in its bodies, soak-and-dry every 2–3 weeks in growth |
| African Milk Tree | Euphorbia trigona | driesOut | 14 / 10–24 | BBC Gardeners' World / Healthy Houseplants — succulent euphorbia, water only when compost dries out completely (~every 2–3 weeks in summer), once a month or less in winter; thick fleshy stems, rots if soggy |
| Crown of Thorns | Euphorbia milii | driesOut | 10 / 7–21 | RHS / Gardening Know How — soak-and-dry but thirstier flowering euphorbia: water ~every 7–10 days in summer when top inch dry, every 2–4 weeks in winter; water sparingly when in growth |
| Firestick Plant | Euphorbia tirucalli | driesOut | 16 / 12–30 | Genus anchor (succulent euphorbia / pencil cactus) — exceptionally drought-tolerant water-storing stems, soak-and-dry every 2–4 weeks in growth, very sparingly in winter |
| Baseball Plant | Euphorbia obesa | driesOut | 21 / 14–35 | Gardening Know How / World of Succulents — very sparing; water roughly once a month in the growing season and every few months in winter, always letting soil dry out completely (overwatering is the #1 killer) |
| Medusa's Head | Euphorbia flanaganii | driesOut | 18 / 12–30 | Genus anchor (caudiciform succulent euphorbia) — water-storing caudex + finger-like arms, soak-and-dry every ~3 weeks in growth, very sparingly in winter |
| Maidenhair Fern | Adiantum raddianum | staysMoist | 4 / 2–6 | BBC Gardeners' World / Gardening Know How — keep soil consistently moist, never let it dry out (not drought-tolerant; deteriorates fast if neglected); thirstiest fern in the batch |
| Bird's Nest Fern | Asplenium nidus | staysMoist | 5 / 3–8 | RHS / Clemson HGIC — water when the top inch feels dry (~weekly), keep compost moist but not soggy; water along the pot edge to avoid rotting the crown; slightly more forgiving than maidenhair |
| Blue Star Fern | Phlebodium aureum | evenlyMoist | 6 / 4–10 | Gardens Illustrated / Patch — epiphytic rainforest fern; keep consistently moist but never wet, water once the top inch dries; use a loose, well-draining mix |
| Button Fern | Pellaea rotundifolia | evenlyMoist | 6 / 4–10 | Soltech / Gardenia — slightly more drought-tolerant than other ferns; let the top inch dry between waterings, forgiving of the odd missed watering but still wants consistent moisture |
| Staghorn Fern | Platycerium bifurcatum | evenlyMoist | 7 / 5–14 | Pistils Nursery / Almanac — epiphytic; soak ~weekly in warm months and every 1–2 weeks when cooler, letting the substrate dry slightly between soakings (absorbs water through fronds and roots) |
| Kangaroo Paw Fern | Microsorum diversifolium | evenlyMoist | 6 / 4–10 | Genus anchor (epiphytic fern, cf. Phlebodium) — leathery-fronded epiphyte; keep evenly moist and water when the top inch dries, never waterlogged |
| Rabbit's Foot Fern | Davallia fejeensis | staysMoist | 5 / 3–8 | Genus anchor (epiphytic Davallia) — lacy fronds on furry surface rhizomes; keep evenly moist, water once the surface is barely dry; dislikes drying out fully |
| Crocodile Fern | Microsorum musifolium | staysMoist | 5 / 3–8 | Genus anchor (tropical epiphytic Microsorum) — broad textured fronds; keep soil consistently moist with high humidity, never let it dry out |
| Lemon Button Fern | Nephrolepis cordifolia | staysMoist | 4 / 2–6 | Genus anchor (Nephrolepis, cf. Boston Fern) — dwarf Boston relative; keep consistently moist, same thirsty cadence as its larger cousin |
| Cretan Brake Fern | Pteris cretica | staysMoist | 4 / 3–7 | Genus anchor (ribbon/brake fern, Pteris) — keep soil consistently moist and never let it dry out fully; tolerates a touch more variability than maidenhair |
| Prayer Plant | Maranta leuconeura | staysMoist | 4 / 3–6 | RHS / Garden Betty — water moderately keeping soil consistently lightly moist (water when top ~25% dry, roughly weekly in spring/summer), never waterlogged; reduce in winter, likes high humidity |
| Herringbone Prayer Plant | Maranta leuconeura var. erythroneura | staysMoist | 4 / 3–6 | Genus anchor (Maranta, cf. M. leuconeura) — red-veined herringbone cultivar, same keep-lightly-moist prayer-plant cadence as the species |
| Rabbit's Tracks Prayer Plant | Maranta leuconeura var. kerchoveana | staysMoist | 4 / 3–6 | Genus anchor (Maranta, cf. M. leuconeura) — green rabbit's-tracks cultivar, same keep-lightly-moist prayer-plant cadence as the species |
| Rose Painted Calathea | Goeppertia roseopicta (syn. Calathea roseopicta) | staysMoist | 4 / 3–6 | Genus anchor (Calathea/Goeppertia) — fussy prayer plant; keep evenly moist (never dry, never soggy), water ~weekly with filtered/rainwater, sensitive to tap-water salts |
| Peacock Plant | Goeppertia makoyana (syn. Calathea makoyana) | staysMoist | 4 / 3–6 | Genus anchor (Calathea/Goeppertia) — thin peacock-patterned leaves; keep consistently lightly moist, water ~weekly, never let dry out fully |
| Pinstripe Calathea | Goeppertia ornata (syn. Calathea ornata) | staysMoist | 4 / 3–6 | Genus anchor (Calathea/Goeppertia) — pink-pinstriped foliage; keep evenly moist with rain/distilled water, water when top barely dries, prone to leaf-edge browning if dry |
| Rattlesnake Plant | Goeppertia insignis (syn. Calathea lancifolia) | staysMoist | 5 / 3–7 | Genus anchor (Calathea/Goeppertia) — one of the more forgiving calatheas; keep evenly moist but tolerates the top inch drying slightly → marginally longer base/max |
| Zebra Plant Calathea | Goeppertia zebrina (syn. Calathea zebrina) | staysMoist | 4 / 3–6 | Genus anchor (Calathea/Goeppertia) — velvety zebra-striped leaves; keep consistently lightly moist, water ~weekly, never waterlogged nor bone-dry |
| Calathea Orbifolia | Goeppertia orbifolia (syn. Calathea orbifolia) | staysMoist | 4 / 3–7 | Garden Betty / Smart Garden Guide — keep top inch slightly damp (never bone-dry or soggy), water ~weekly and reduce to every 2–3 weeks in winter; use filtered/distilled/rainwater to avoid tip browning |
| Furry Feather Calathea | Goeppertia rufibarba (syn. Calathea rufibarba) | staysMoist | 5 / 3–7 | Genus anchor (Calathea/Goeppertia) — wavy fuzzy leaves, one of the tougher calatheas; keep evenly moist but tolerates the surface drying a touch → marginally longer base/max |
| Never Never Plant | Ctenanthe oppenheimiana 'Tricolor' | staysMoist | 4 / 3–6 | Genus anchor (Ctenanthe, prayer-plant relative cf. Calathea/Maranta) — variegated tricolour foliage; keep soil consistently lightly moist (never dry, never soggy), water ~weekly with filtered/rainwater, high humidity |
| Fishbone Prayer Plant | Ctenanthe burle-marxii | staysMoist | 4 / 3–6 | Genus anchor (Ctenanthe, prayer-plant relative) — fishbone-banded leaves; keep evenly moist, water when the surface barely dries, never let it dry out fully |
| Golden Mosaic Ctenanthe | Ctenanthe lubbersiana | staysMoist | 4 / 3–6 | Genus anchor (Ctenanthe, prayer-plant relative) — yellow-mottled foliage (Bamburanta); keep consistently lightly moist, water ~weekly, dislikes drying out |
| Stromanthe Triostar | Stromanthe sanguinea 'Triostar' (syn. Stromanthe thalia) | staysMoist | 4 / 3–6 | Genus anchor (Stromanthe, prayer-plant relative cf. Calathea/Maranta) — pink-variegated triostar; keep evenly moist with filtered/rainwater, never dry nor waterlogged, high humidity |
| Nerve Plant | Fittonia albivenis | staysMoist | 4 / 2–6 | RHS — keep soil moist, water when the top ~inch dries (~weekly in spring/summer, every 10–14 days in winter); droops/wilts dramatically when dry but recovers once watered; never waterlogged. Notably thirsty → low min |
| Silver Nerve Plant | Fittonia albivenis (Argyroneura Group) | staysMoist | 4 / 2–6 | Genus anchor (Fittonia, cf. F. albivenis per RHS) — silver-veined nerve plant; keep consistently moist, water when top inch dries, recovers fast from a thirst-wilt; same thirsty cadence as the species |
| Red Nerve Plant | Fittonia albivenis (Verschaffeltii Group) | staysMoist | 4 / 2–6 | Genus anchor (Fittonia, cf. F. albivenis per RHS) — red/pink-veined nerve plant; keep consistently moist, water when top inch dries; same thirsty keep-moist cadence as the species |
| Chinese Money Plant | Pilea peperomioides | evenlyMoist | 7 / 5–14 | Greenery Unlimited / The Sill — let the top 2–3 inches dry between waterings, water every 1–2 weeks; more prone to over- than under-watering, so allow drying to avoid root rot |
| Aluminium Plant | Pilea cadierei | evenlyMoist | 6 / 4–10 | Genus anchor (Pilea, cf. P. peperomioides) — silver-splashed foliage; keep evenly moist, water when the top inch dries, ease off in winter; avoid waterlogging |
| Moon Valley Pilea | Pilea involucrata 'Moon Valley' | evenlyMoist | 6 / 4–10 | Genus anchor (Pilea, friendship plant) — quilted bronze-green leaves; keep evenly moist, water when the top inch dries, never bone-dry nor soggy |
| Watermelon Peperomia | Peperomia argyreia | evenlyMoist | 9 / 7–14 | RHS / The Sill — let the top 1–2" dry, water roughly weekly to fortnightly; thick succulent-ish petioles store water, prone to overwatering / root rot if kept soggy |
| Baby Rubber Plant | Peperomia obtusifolia | evenlyMoist | 10 / 7–16 | The Sill / Costa Farms — thick succulent-like leaves store water; let the top 2" dry between waterings, every 1–2 weeks → slightly longer interval than the genus anchor |
| Emerald Ripple Peperomia | Peperomia caperata | evenlyMoist | 9 / 7–14 | RHS — keep lightly/evenly moist, water when the top inch dries; never waterlogged, ease off in winter (genus anchor cadence) |
| String of Turtles | Peperomia prostrata | evenlyMoist | 10 / 8–16 | Genus anchor (Peperomia) — semi-succulent trailing leaves store water; let the soil dry between waterings (every 1–2 weeks), root rot if kept wet → longer interval, higher min |
| Raindrop Peperomia | Peperomia polybotrya | evenlyMoist | 10 / 7–16 | Genus anchor (Peperomia) — thick coin/raindrop leaves store water; let the top 2" dry between waterings → slightly longer interval than the genus anchor |
| Cupid Peperomia | Peperomia scandens | evenlyMoist | 9 / 7–14 | Genus anchor (Peperomia) — trailing variegated species; keep lightly moist, water when the top inch dries, standard peperomia cadence |
| Trailing Jade Peperomia | Peperomia rotundifolia | evenlyMoist | 10 / 7–16 | Genus anchor (Peperomia) — round succulent jade-like leaves store water; let the soil dry between waterings → slightly longer interval |
| Ruby Cascade Peperomia | Peperomia 'Ruby Cascade' | evenlyMoist | 11 / 8–18 | Genus anchor (succulent trailing Peperomia) — fleshy water-storing leaves, notably drought-tolerant; soak then let dry well → longest interval in the batch |
| Beetle Peperomia | Peperomia quadrangularis (syn. P. angulata) | evenlyMoist | 10 / 7–14 | Genus anchor (Peperomia) — semi-succulent trailing striped leaves; keep lightly moist, let the top dry between waterings |
| Happy Bean Peperomia | Peperomia ferreyrae | evenlyMoist | 11 / 8–18 | Genus anchor (succulent Peperomia) — very succulent bean-shaped leaves store ample water; water sparingly, let the soil dry well between waterings → longest interval in the batch |
| Rex Begonia | Begonia rex-cultorum | evenlyMoist | 6 / 4–9 | RHS — rhizomatous foliage begonia; keep the compost moist but never waterlogged, let the surface dry slightly between waterings, water from below to keep crown/leaves dry (genus anchor cadence) |
| Polka Dot Begonia | Begonia maculata 'Wightii' | evenlyMoist | 7 / 5–10 | RHS / Hortology — cane (wing-leaf) begonia; let the top 2–3 cm dry before watering, more drought-tolerant fleshy stems → slightly longer interval than the genus anchor; avoid soggy roots |
| Angel Wing Begonia | Begonia coccinea | evenlyMoist | 7 / 5–10 | Genus anchor (cane begonia) — bamboo-like water-storing stems; water when the top few cm dry, slightly longer interval than rhizomatous types; dislikes waterlogging |
| Iron Cross Begonia | Begonia masoniana | evenlyMoist | 6 / 5–10 | RHS — rhizomatous begonia; keep evenly moist in growth, let the surface dry slightly, water from below to protect the hairy leaves; never sit in water |
| Escargot Begonia | Begonia 'Escargot' | evenlyMoist | 6 / 4–9 | Genus anchor (rhizomatous Rex-type) — spiral-leaf foliage begonia; keep lightly moist, let the top dry between waterings, avoid wetting the leaves (genus anchor cadence) |
| Beefsteak Begonia | Begonia × erythrophylla | evenlyMoist | 7 / 5–11 | Genus anchor (rhizomatous begonia) — thick rounded fleshy leaves store water and tolerate drying; let the top 2–3 cm dry well → slightly longer, more drought-tolerant interval |
| Wax Begonia | Begonia × semperflorens-cultorum | evenlyMoist | 5 / 4–8 | RHS — fibrous-rooted bedding/houseplant begonia; keep the compost evenly moist in growth, water when the surface starts to dry; shorter interval than the cane/rhizomatous types |
| Tuberous Begonia | Begonia × tuberhybrida | evenlyMoist | 5 / 4–8 | RHS — tuberous begonia; keep evenly moist while in active growth/flower, water when the surface dries, avoid waterlogging the tuber; reduce sharply as it dies back |
| Dragon Wing Begonia | Begonia 'Dragon Wing' | evenlyMoist | 6 / 4–9 | Genus anchor (cane × fibrous hybrid) — vigorous angel-wing-type; keep evenly moist in growth, let the surface dry slightly between waterings (genus anchor cadence) |
| Palm-leaf Begonia | Begonia luxurians | evenlyMoist | 6 / 4–9 | Genus anchor (cane begonia) — tall palmate-leaved species; keep evenly moist in growth, water when the top few cm dry, dislikes both drying out fully and waterlogging |
| Silver Inch Plant | Tradescantia zebrina | evenlyMoist | 7 / 5–10 | RHS / The Sill — vigorous trailing spiderwort; keep evenly moist in growth, water when the top inch dries (~weekly), reduce in winter; fast grower, droops/browns if left dry |
| Small-leaf Spiderwort | Tradescantia fluminensis | evenlyMoist | 7 / 5–10 | Genus anchor (Tradescantia) — fast trailing inch plant; keep lightly moist, water when the top inch dries, same ~weekly cadence as T. zebrina |
| Tradescantia Nanouk | Tradescantia 'Nanouk' (albiflora hybrid) | evenlyMoist | 7 / 5–12 | Genus anchor (Tradescantia) — robust thick-stemmed variegated cultivar storing a little more water → slightly longer max than the species; keep evenly moist, let the top inch dry |
| Purple Heart | Tradescantia pallida (syn. Setcreasea purpurea) | evenlyMoist | 9 / 6–14 | RHS / Gardening Know How — fleshy semi-succulent purple stems store water and tolerate drying; water when the top 2–3 cm dry, more drought-tolerant → longer interval than the trailing species |
| Moses-in-the-Cradle | Tradescantia spathacea (syn. Rhoeo spathacea) | evenlyMoist | 9 / 6–14 | Genus anchor (Tradescantia) — semi-succulent rosette (oyster plant) storing water in thick leaves; let the top 2–3 cm dry between waterings, more drought-tolerant than the trailing inch plants |
| White Velvet Tradescantia | Tradescantia sillamontana | driesOut | 12 / 8–18 | World of Succulents / Gardenia — xeric woolly-leaved spiderwort, the most succulent of the genus; soak-and-dry, water only when the soil has dried out, sparingly in winter |
| Tahitian Bridal Veil | Gibasis pellucida (syn. Tradescantia multiflora) | evenlyMoist | 6 / 4–9 | Genus anchor (inch-plant relative, Commelinaceae) — fine-leaved trailing veil; keep consistently lightly moist, water when the surface starts to dry, dislikes drying out fully → shorter interval |
| Turtle Vine | Callisia repens | evenlyMoist | 8 / 5–12 | Genus anchor (Callisia, inch-plant relative) — small semi-succulent creeping leaves store some water; keep lightly moist but let the top inch dry, more forgiving of missed waterings than Tradescantia |
| Basket Plant | Callisia fragrans | evenlyMoist | 9 / 6–14 | Genus anchor (Callisia) — larger fleshy rosette/runner storing water; let the top 2–3 cm dry between waterings, more drought-tolerant → longer interval than the small turtle vine |
| String of Hearts | Ceropegia woodii | driesOut | 14 / 10–21 | RHS / The Sill — semi-succulent trailing chain of hearts with water-storing tubers; soak-and-dry, water every 2–3 weeks only when the soil is dry, very prone to root rot if kept wet |
| Spider Plant | Chlorophytum comosum 'Vittatum' | evenlyMoist | 7 / 5–10 | RHS — water moderately in growth, keeping the compost lightly moist; thick fleshy tuberous roots store water so it tolerates the top inch drying, reduce in winter |
| Bonnie Spider Plant | Chlorophytum comosum 'Bonnie' | evenlyMoist | 7 / 5–10 | Genus anchor (Chlorophytum comosum) — curly-leaved spider plant cultivar; same water-storing-root, keep-lightly-moist cadence as the species |
| Variegated Spider Plant | Chlorophytum comosum 'Variegatum' | evenlyMoist | 7 / 5–10 | Genus anchor (Chlorophytum comosum) — white-margined cultivar; water when the top inch dries (~weekly), tuberous roots store water, reduce in winter |
| Fire Flash | Chlorophytum orchidastrum | evenlyMoist | 7 / 5–12 | Genus anchor (Chlorophytum) — clumping orange-stemmed "Mandarin Plant"; keep evenly moist in growth, let the top inch dry between waterings; less tuberous than C. comosum but still forgiving |
| Asparagus Fern | Asparagus densiflorus 'Sprengeri' | evenlyMoist | 7 / 5–12 | RHS — not a true fern; keep the compost moist in growth and water when the top inch dries; fleshy water-storing tuberous roots tolerate occasional drying, reduce watering in winter |
| Foxtail Fern | Asparagus densiflorus 'Myers' | evenlyMoist | 8 / 6–14 | Genus anchor (Asparagus densiflorus) — dense plumed stems on chunky water-storing tubers; more drought-tolerant than 'Sprengeri', let the top 2–3 cm dry → slightly longer interval |
| Lace Fern | Asparagus setaceus | evenlyMoist | 6 / 4–10 | Genus anchor (Asparagus, cf. A. densiflorus) — fine feathery climber that likes more consistent moisture and humidity than the tuberous types; water when the surface starts to dry → shorter interval |
| Ming Fern | Asparagus retrofractus | evenlyMoist | 8 / 5–14 | Genus anchor (Asparagus) — woody-stemmed, very drought-tolerant with thick water-storing roots; let the top few cm dry well between waterings → longer interval |
| Cast Iron Plant | Aspidistra elatior | driesOut | 12 / 8–21 | RHS — famously tough; water moderately and let the top half of the compost dry out between waterings (every 2–3 weeks), reduce in winter; rots if kept waterlogged |
| Variegated Cast Iron Plant | Aspidistra elatior 'Variegata' | driesOut | 13 / 9–21 | Genus anchor (Aspidistra elatior) — white-striped cultivar with less chlorophyll → slower growth, slightly longer interval; same let-it-dry, never-soggy cadence as the species |
| Parlour Palm | Chamaedorea elegans | evenlyMoist | 7 / 5–10 | RHS — keep the compost evenly moist in growth, watering when the surface starts to dry; never waterlogged. Sits on the palm genus anchor (base 7, 5–10) |
| Areca Palm | Dypsis lutescens | evenlyMoist | 6 / 4–9 | RHS / Hortology — thirsty palm that likes consistently moist (not soggy) compost; let only the very top dry → slightly shorter interval than the palm anchor |
| Kentia Palm | Howea forsteriana | evenlyMoist | 9 / 6–14 | RHS — tolerant, slow-growing palm that copes with some drying out; water when the top 2–3 cm are dry → longer interval than the palm anchor |
| Majesty Palm | Ravenea rivularis | evenlyMoist | 6 / 4–9 | Hortology / RHS — a riverbank species that likes plentiful, consistent moisture; keep evenly moist → shorter interval than the palm anchor |
| Ponytail Palm | Beaucarnea recurvata | driesOut | 18 / 12–30 | RHS — not a true palm; a swollen-caudex succulent that stores water and must dry out fully between drinks → long interval, treated under the sansevieria/caudex anchor |
| Sago Palm | Cycas revoluta | driesOut | 14 / 10–24 | RHS — a cycad, not a palm; water moderately and let the top half of the compost dry between waterings, much reduced in winter; rots if kept wet |
| Cat Palm | Chamaedorea cataractarum | evenlyMoist | 6 / 4–9 | Genus anchor (Chamaedorea) + Hortology — moisture-loving clumping palm from stream banks; keep evenly moist → slightly shorter interval than the palm anchor |
| Bamboo Palm | Chamaedorea seifrizii | evenlyMoist | 7 / 5–11 | Genus anchor (Chamaedorea) — reed-stemmed palm; keep evenly moist, letting only the surface dry; sits on the palm anchor |
| Lady Palm | Rhapis excelsa | evenlyMoist | 9 / 6–14 | RHS — tough, slow fan palm that tolerates some drying; water when the top few cm are dry → longer interval than the palm anchor |
| Pygmy Date Palm | Phoenix roebelenii | evenlyMoist | 8 / 6–12 | RHS / Hortology — compact date palm; keep evenly moist in growth, allowing the top 2–3 cm to dry between waterings |
| Rubber Plant | Ficus elastica | evenlyMoist | 9 / 6–14 | RHS — water when the top 2–3 cm of compost are dry (roughly weekly in summer, less in winter); never leave standing in water. Fig genus anchor (evenlyMoist, base 9, 6–14) |
| Fiddle-Leaf Fig | Ficus lyrata | evenlyMoist | 9 / 6–14 | RHS / Hortology — let the top few cm dry, then water thoroughly; dislikes both drought and waterlogging. Sits on the fig anchor |
| Weeping Fig | Ficus benjamina | evenlyMoist | 8 / 6–12 | RHS — keep evenly moist in growth; erratic watering (or letting it dry too far) triggers leaf drop → slightly shorter, steadier interval than the fig anchor |
| Ginseng Ficus | Ficus microcarpa | evenlyMoist | 7 / 5–11 | Genus anchor (Ficus) + Hortology — sold as bonsai in a small, fast-draining pot that dries quicker → shorter interval; keep evenly moist, letting the surface dry |
| Variegated Rubber Plant 'Tineke' | Ficus elastica 'Tineke' | evenlyMoist | 10 / 7–15 | Genus anchor (Ficus elastica) — cream/green variegated cultivar with less chlorophyll → slower growth, slightly longer interval; same let-top-dry cadence |
| Burgundy Rubber Plant | Ficus elastica 'Abidjan' | evenlyMoist | 9 / 6–14 | Genus anchor (Ficus elastica) — dark-leaved cultivar; standard rubber-plant cadence, water when the top 2–3 cm are dry |
| Creeping Fig | Ficus pumila | staysMoist | 6 / 4–9 | RHS — thin-leaved trailing fig that resents drying out; keep the compost consistently moist (not soggy) → shorter interval under the moisture-loving anchor |
| Audrey Fig | Ficus benghalensis | evenlyMoist | 9 / 6–14 | Hortology / RHS — banyan fig grown for velvety leaves; water when the top few cm dry, then drench. Sits on the fig anchor |
| Mistletoe Fig | Ficus deltoidea | evenlyMoist | 8 / 6–12 | Genus anchor (Ficus) + Hortology — compact fig that likes steady moisture in growth; let the surface dry, never waterlogged → slightly shorter than the fig anchor |
| Triangle Fig | Ficus triangularis | evenlyMoist | 9 / 6–13 | Genus anchor (Ficus) — triangular-leaved fig; standard fig cadence, water when the top 2–3 cm of compost are dry |
| Umbrella Tree | Schefflera actinophylla (syn. Heptapleurum actinophyllum) | evenlyMoist | 9 / 6–14 | RHS / Hortology — water when the top third of compost dries, then drench; prone to root rot if kept wet, drops leaves if overwatered |
| Dwarf Umbrella Tree | Schefflera arboricola (syn. Heptapleurum arboricola) | evenlyMoist | 9 / 6–14 | RHS / Hortology — the common houseplant umbrella; let the top 2–3 cm dry between waterings, never soggy → same cadence as the genus anchor |
| Variegated Dwarf Umbrella Tree | Schefflera arboricola 'Gold Capella' | evenlyMoist | 10 / 7–15 | Genus anchor (Schefflera) + gold variegation → less chlorophyll, slightly slower growth → marginally longer interval |
| Schefflera Janine | Schefflera arboricola 'Janine' | evenlyMoist | 10 / 7–15 | Genus anchor (Schefflera) + heavy cream variegation → slower growth → slightly longer interval |
| Dumb Cane | Dieffenbachia seguine | evenlyMoist | 8 / 6–12 | RHS — water moderately, keep evenly moist in growth and let the top 2–3 cm dry; thick stems resent waterlogging |
| Dieffenbachia Camille | Dieffenbachia 'Camille' | evenlyMoist | 8 / 6–12 | Genus anchor (Dieffenbachia) — popular cream-centred cultivar, same keep-evenly-moist cadence as the species |
| Dieffenbachia Tropic Snow | Dieffenbachia seguine 'Tropic Snow' | evenlyMoist | 8 / 6–12 | Genus anchor (Dieffenbachia) — large variegated seguine cultivar, same let-top-inch-dry cadence as the species |
| Spineless Yucca | Yucca elephantipes (syn. Yucca gigantea) | driesOut | 14 / 10–24 | RHS / Hortology — woody desert plant; let the soil dry out fully, water sparingly every 2–3 weeks; overwatering rots the cane |
| Adam's Needle | Yucca aloifolia | driesOut | 14 / 10–24 | Genus anchor (Yucca) — drought-hardy rosette yucca; same dry-out-fully, water-every-2–3-weeks cadence as the species |
| Money Tree | Pachira aquatica | evenlyMoist | 10 / 7–15 | Hortology / RHS — water when the top 50–75% of compost dries; the swollen trunk stores water, so let it dry well between drenches → slightly longer than the moist-loving anchor |
| Wax Plant | Hoya carnosa | evenlyMoist | 11 / 8–18 | RHS / Hortology — semi-succulent epiphyte; water when the top two-thirds of compost has dried, ~every 1–2 weeks in growth, sparingly in winter; thick waxy leaves store water → longer than the foliage anchor |
| Krimson Queen Hoya | Hoya carnosa 'Krimson Queen' | evenlyMoist | 12 / 9–18 | Genus anchor (Hoya carnosa) + cream-margined variegation → less chlorophyll, slower growth → slightly longer interval than the species |
| Krimson Princess Hoya | Hoya carnosa 'Krimson Princess' | evenlyMoist | 12 / 9–18 | Genus anchor (Hoya carnosa) + cream-centred variegation → slower growth → slightly longer interval than the species |
| Hindu Rope Plant | Hoya carnosa 'Compacta' | evenlyMoist | 12 / 9–21 | Genus anchor (Hoya carnosa) — densely curled thick leaves hold extra water and dry slowly → longer/wider interval than the species |
| Sweetheart Hoya | Hoya kerrii | driesOut | 14 / 10–24 | Hortology / Patch — very thick succulent heart-shaped leaves store abundant water; treat like a succulent, let the soil dry out fully, water every 2–3 weeks |
| Hoya Pubicalyx | Hoya pubicalyx | evenlyMoist | 11 / 8–18 | Genus anchor (Hoya) — vigorous waxy-leaved climber, same let-top-two-thirds-dry cadence as H. carnosa |
| Hoya Linearis | Hoya linearis | evenlyMoist | 9 / 6–14 | Genus anchor (Hoya) — fine soft trailing leaves hold less water than typical Hoyas → shorter interval; keep lightly moist, don't let it dry fully |
| Miniature Wax Plant | Hoya bella | evenlyMoist | 9 / 6–14 | Genus anchor (Hoya, Hoya lanceolata subsp. bella) — small thin-leaved miniature, less drought-tolerant than carnosa → shorter interval |
| Hoya Obovata | Hoya obovata | evenlyMoist | 12 / 9–18 | Genus anchor (Hoya) — large round thick succulent leaves store plenty of water → longer interval, let top two-thirds dry |
| Common Waxflower | Hoya australis | evenlyMoist | 11 / 8–18 | Genus anchor (Hoya) — robust waxy-leaved climber, same let-top-two-thirds-dry cadence as H. carnosa |
| Moth Orchid | Phalaenopsis hybrid | evenlyMoist | 7 / 5–10 | RHS — the commonest UK houseplant orchid; water about once a week, letting the bark mix almost dry out, never leave standing in water. Orchid genus anchor (evenlyMoist, base 7, 5–10) |
| Dendrobium Orchid | Dendrobium nobile | evenlyMoist | 7 / 5–12 | RHS / Gardeners' World — water freely (~weekly) during active growth in summer, then much more sparingly through the cool winter rest that triggers flowering → wider max |
| Cymbidium Orchid | Cymbidium hybrid | evenlyMoist | 7 / 5–12 | RHS — keep the compost evenly moist and water ~weekly while in growth, reducing once flower spikes form/over winter; pseudobulbs store some water → wider max |
| Dancing Lady Orchid | Oncidium hybrid | evenlyMoist | 6 / 4–9 | American Orchid Society / RHS — thin pseudobulbs and fine roots dry out quickly in bark; water roughly every 4–7 days, more often than Phalaenopsis → shorter interval |
| Cattleya Orchid | Cattleya hybrid | evenlyMoist | 9 / 6–14 | American Orchid Society — plump pseudobulbs store water; let the bark dry appreciably between waterings (every ~7–10 days), so a longer interval than the thinner-bulbed orchids |
| Vanda Orchid | Vanda hybrid | evenlyMoist | 4 / 2–7 | RHS / American Orchid Society — usually grown bare-root in open baskets; thick aerial roots need very frequent soaking (near-daily when warm) → shortest orchid interval |
| Slipper Orchid | Paphiopedilum hybrid | staysMoist | 6 / 4–9 | RHS — has no pseudobulbs, so it cannot store water; keep the compost consistently lightly moist and never let it dry out fully, water ~weekly |
| Jewel Orchid | Ludisia discolor | evenlyMoist | 6 / 4–9 | RHS / Gardeners' World — terrestrial orchid grown for its velvety foliage; keep the compost evenly moist (never soggy), watering when the surface starts to dry |
| Pansy Orchid | Miltoniopsis hybrid | staysMoist | 5 / 3–8 | American Orchid Society / RHS — fine roots and no water-storing pseudobulbs to speak of; keep evenly moist at all times, never allowing it to dry out → short, moisture-loving interval |
| Zygopetalum Orchid | Zygopetalum hybrid | evenlyMoist | 7 / 5–10 | American Orchid Society / RHS — keep evenly moist during active growth, watering ~weekly and letting the surface barely dry; reduce a little once growth matures |
