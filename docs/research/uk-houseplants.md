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
