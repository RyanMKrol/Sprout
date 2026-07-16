# Sprout Redesign Spec — "Botanical Editorial, warmed up (2b)"

**This is the design source of truth for the redesign backlog.** It is distilled from the
designer's canvas (`docs/designs/app-redesign/Sprout App.dc.html`, 28 mockups — authoritative;
`Sprout.dc.html` is exploration history only) plus the as-is product spec
(`docs/designs/SPROUT_DESIGN_SPEC.md`). Tasks cite sections of THIS file; builders should not
need to read the HTML canvas.

Sections marked **⚑ derived** were authored to fill gaps the canvas leaves (approved by the
owner, subject to later feedback) — everything else is taken directly from the canvas.

**Global decisions (owner-approved):**
- **Photo wins where present**: any row/detail that shows a plant token displays the plant's
  photo clipped in the same circular frame when a photo exists, else the gradient+icon token.
  Camera flows stay.
- **Bundle everything**: Bricolage Grotesque + Hanken Grotesk fonts, the 16 Phosphor plant
  glyphs AND the FontAwesome 6 solid chrome icons ship as bundled assets (`Sources/Fonts/`,
  asset catalog). No SF Symbols in redesigned UI.
- **Direct replacement**: each screen task replaces the old styling on merge; no feature flag.
  The app mixes old+new styles mid-run — acceptable.
- **No dark mode** in this wave (only camera/diagnostics/launch are inherently dark). The
  rejected "Night Garden" exploration is NOT a dark-mode spec.
- Navigation model is unchanged: Home hub, push for lists/details, sheets for forms,
  full-screen covers for camera + guided watering. Single-cover and staged-dismissal
  constraints from the as-is spec (§flags 8/9) still hold.

---

## 1. Design tokens

### 1.1 Typography

Families (bundled, see §6): **Bricolage Grotesque** (display, `.disp`, almost always w700) and
**Hanken Grotesk** (body; 400/500/600/700 + italic 400/500). Latin species names are ALWAYS
italic Hanken Grotesk. Monospace (diagnostics only): SF Mono / ui-monospace.

| Token | Size/weight/face | Use | Color |
|---|---|---|---|
| eyebrow | 11 w700 Hanken, +1.4 tracking, UPPERCASE | section labels | `#A79E85` |
| chip | 10.5–11 w700 Hanken | due chips, pills | semantic |
| rowMeta | 11.5 w600 Hanken | "Every 4d · shortened" | `#A79E85` |
| caption | 12–13 Hanken (species italic) | captions | `#7C8173` |
| hint | 12.5–13 Hanken, lh 1.45 | helper copy | `#8A9080` |
| body | 14.5–16 Hanken, lh 1.45–1.5 | sheet body copy | `#6E7A63` |
| control | 15–17 w500–600 Hanken | buttons, rows, nav actions | contextual |
| cardTitle | 16–18 w700 Bricolage | card/row titles | ink |
| sheetTitle | 18 w700 Bricolage | sheet headers | ink |
| plantName | 21–22 w700 Bricolage | check-in/guided plant name | ink |
| recommendation | 20–23 w700 Bricolage, lh 1.25 | outcome headlines | ink |
| emptyHeading | 19–27 w700 Bricolage | empty states, dialogs | ink |
| greeting | 31 w700 Bricolage, −0.6 tracking, lh 1.08 | Home headline | ink |
| pageTitle | 32 w700 Bricolage, −0.5 tracking | list/detail titles | ink |
| heroNumeral | 60 w700 Bricolage, lh 0.9 | "2" to water | white |
| wordmark | 36 w700 Bricolage, −0.7 tracking | splash | `#F4F1E7` |

### 1.2 Palette

Core:
- `paper #F4F1E7` app background (all light screens + sheets); `ink #232821` primary text
- `brandGreen #2F6B4C` buttons/links/selected/FAB/progress/due-later; hero gradient
  `150deg #2F6B4C → #193E2C`; logo/bell/camera-circle gradient `150deg #3C7E58 → #1E4632`;
  launch bg `165deg #2F6B4C → #173726`; deep text-on-cream-in-hero `#1C4330`; cream `#EBE4CF`
- Text ramp: secondary `#7C8173`, muted `#6E7A63`, hint `#8A9080`, tertiary `#9AA090`,
  taupe `#A79E85`
- Chrome: sheet-dim `#D8D3C2` + scrim `rgba(25,40,30,0.28–0.40)`; segmented track `#E7E1D2`;
  toggle-off `#D6D0C0`; progress track `#E1DBCB`; card surface `#fff`

Semantic:
- destructive/overdue `#C4553B` (chip bg `rgba(196,85,59,0.13)`); swipe-edit `#5E8CA8`
- dueToday amber `#B4832F` on `rgba(198,138,46,0.16)`; dueLater `#2F6B4C` on
  `rgba(47,107,76,0.13)`
- warning terracotta `#C4663F` (bell-slash, reminders-off banner; bg `rgba(196,102,63,0.13)`,
  border `rgba(196,102,63,0.32)`)
- sun `#D98B0A`; brightness chip `#C4832A` on `rgba(217,139,10,0.14)`
- soft green fill `rgba(47,107,76,0.10–0.12)` (banners, icon bubbles, picker band, time chip)

Bento surfaces:
- **sage** `#DEE8D0`, border `rgba(47,107,76,0.16)`, title `#1F2A20`, subtitle `#586A4E`
- **oat** `#EEE3CD`, border `rgba(140,108,52,0.16)`, title `#2A2418`, subtitle `#7C6E4E`,
  icon `#B4832F`

Plant token gradients — `radial-gradient(130% 130% at 30% 25%, LIGHT, DARK)`, white glyph,
shadow `0 4 10 rgba(DARK,0.28)`:
green `#79B98C→#3F7E58` · purple `#A98CC0→#6E4E8C` · blue `#8CB0D2→#4E7CA6` ·
gold `#DCC078→#B08A34` · teal `#5FB4A2→#2E7C6B` · pink `#D79BB0→#B05F7E` ·
success `#79B98C→#2E7C4E`. Assignment is deterministic per plant UUID (replaces the old
10-hue `PlantPalette`).

Dark screens: camera bg `#10160E`; capture-success border `#4FC07E` + overlay
`rgba(63,126,88,0.5)`; diagnostics terminal `#232821` bg, text `#C7D0BE`, timestamps
`#7C8570`, success `#8FE0A8`, warning `#E7B36A`.

### 1.3 Geometry, spacing, shadows

Radii: 40 sheet top · 28 hero · 24–26 bento/camera frame · 22 dialogs/big cards · 20 plant
rows · 18 banners/fields/room rows/ghost buttons/stat cards/grid cells · 15–16 primary
buttons/small rows/segmented outer/check-in cards · 11–13 selected pill/chips/bubbles/alert
buttons · 10–12 due chips · circle for tokens/FAB/toolbar buttons.

Spacing: screen gutter 18 (lists) / 20–22 (headers); card padding 13–16; row gap 9–11;
section label ~20 above / 9 below; hero padding 22; grab handle 40×5 `rgba(60,66,58,0.2)`.

Shadows: card `0 3 12 rgba(45,55,38,0.05)` + hairline border `rgba(34,39,31,0.05)`; bento
`0 4 14 rgba(45,55,38,0.06)`; hero `0 18 36 rgba(25,62,44,0.34)`; primary button
`0 12 26 rgba(47,107,76,0.34)`; token `0 4 10 dark@0.28`; dialog `0 24 54 rgba(0,0,0,0.32)`;
sheet `0 -8 40 rgba(0,0,0,0.16)`. In-card dividers: 1px `rgba(60,66,58,0.08)`, inset 16.

### 1.4 Iconography (all bundled — see §6)

- **Chrome: FontAwesome 6 solid** — seedling, gear, bell, bell-slash, droplet, plus,
  list-check, chevron-left/right, pencil, trash, house, couch, bed, bath, sun,
  arrow-trend-up, magnifying-glass, circle-plus, shuffle, camera, circle-check, check,
  arrow-right, lock, arrows-rotate, arrow-up-from-bracket, copy, file-magnifying-glass? (use
  `file-lines` if unavailable), circle-info, xmark.
- **Plant glyphs: Phosphor regular (line)** — the 16 selectable icons: flower, leaf, plant,
  potted-plant, cactus, flower-tulip, flower-lotus, grains, clover, tree-palm, tree,
  tree-evergreen, acorn, cherries, carrot, pepper.
- Room preset icons (FA): Living Room=couch, Bedroom=bed, Bathroom=bath, Kitchen=house
  **⚑ derived**: Kitchen=`fa-utensils` if bundled, Dining Room=`fa-mug-saucer`→ fallback
  house; any custom/other room = house.

## 2. Component library (names frozen in redesign-architecture.md)

1. **PlantToken** — circular radial-gradient + white Phosphor glyph at ≈45% of diameter;
   photo-clipped variant when the plant has a photo. Sizes used: 34 basket · 36–38 avatar
   stacks (+2.5 border, −12 overlap) · 40 room rows · 46 list rows · 60 check-in · 84 empty
   state · 88 icon-picker preview · 100–120 guided · 112 detail header.
2. **DueChip** — r10–12, padding 5×11, 11 w700; overdue red / today amber / later green
   (colors §1.2).
3. **PrimaryButton** — brandGreen r16 p16–17 white 17 w600 + green shadow. **GhostButton** —
   transparent, 1.5px `rgba(47,107,76,0.32)` border, r18 p14, green 15 w600 icon+label.
   **CreamInsetButton** (hero) — `#F4F1E7` fill r15 p14 text `#1C4330` 16 w600 + arrow.
4. **SegmentedPicker** — track `#E7E1D2` r15 p4; selected pill brandGreen r11 white 14–15
   w600 shadow `0 3 8 rgba(47,107,76,0.3)`; idle `#6E7A63` w500.
5. **HeroCard** — r28 green gradient, oversized watermark icon (~150px, white@0.08, bleeding
   off an edge), eyebrow `rgba(235,228,207,0.7)`.
6. **BentoTile** — sage/oat r24 p16; 40×40 white r12 icon bubble OR overlapping token stack;
   Bricolage 18 w700 title + 13 w600 subtitle.
7. **SectionEyebrow**, **InfoBanner** (soft green r16, icon + 13 `#2A6045` text),
   **CircularToolbarButton** (42Ø white, shadow, FA 16–17), **FAB** (40Ø green plus).
8. **SheetScaffold** — r40 top corners, grab handle, Cancel / Bricolage-18 title / Save
   (green 17 w600).
9. **AlertCard** — 286w, `rgba(244,241,231,0.92)`+blur20, r22; 52Ø tinted icon circle;
   Bricolage 19 title; 13.5 body; neutral `rgba(60,66,58,0.08)` + destructive `#C4553B`
   buttons r13.
10. **WheelPicker style** — 180–200 viewport, center band soft-green r11–12 h38–40, selected
    Bricolage 20–23 w700 ink, neighbors 0.35 opacity, next 0.18.
11. **RhythmBand** (plant detail) — eyebrow "WATERING RHYTHM"; "Every Nd" Bricolage 26; MIN/MAX
    labels 11 w700 taupe; 12px track `linear-gradient(90deg,#E3EBD6,#B9D3A2)` r6; 2px marker
    at base-interval position labeled "base Nd"; 26Ø brandGreen thumb (3px white border,
    white droplet 11px) at effective interval labeled "now". Positions =
    `(value − min)/(max − min)`, clamped; when base and now are within ~8% collapse to the
    thumb label only (**⚑ derived** collision rule).
12. **PlantRow** — white r20 card p13×14: PlantToken 46 + name (Bricolage 18) + italic
    species 12.5 + meta 11.5 w600 ("Every Nd" + " · shortened"/" · stretched" when adapted)
    + trailing DueChip.

## 3. Screens (canvas order; SPROUT_SCREEN hook in parens)

Numbers = canvas mockups. Layouts below are complete; exact copy strings included.

**00 Launch splash — NEW.** Full-bleed launch gradient; radial white glow top; 114×114 r32
frosted tile (white@0.12, border white@0.16) with cream seedling 58; "Sprout" wordmark;
26Ø spinner (ring white@0.22, cream arc) 72 from bottom; tile floats ±5px 3s loop; whole
screen fades to Home ~0.6s after data load. (Implement as a SwiftUI overlay shown at
startup, not a LaunchScreen storyboard — the animation requires live views. A static
launch-screen background color `#2F6B4C` matches.)

**01 Notification intro (`notifyoff` + intro).** Bottom sheet: 112Ø gradient circle, white
bell 46; "Never miss a watering"; body "Sprout sends one gentle reminder a day when your
plants need water, at a time you choose. 🌱"; PrimaryButton "Enable reminders"; text button
"Maybe later". Shown once before the system prompt (keep current gatekeeper logic).

**02 Home — empty (`home` with no plants).** Top bar: logo lockup (34×34 r11 gradient tile +
seedling + "Sprout" Bricolage 22) left; right CircularToolbarButtons: bell-slash `#C4663F`
(only when reminders off) + gear `#4A5142`. Eyebrow "WELCOME 🌱"; greeting "Let's grow\nsomething."
Reminders-off banner (white r18, terracotta border/icon per §1.2; title "Reminders are off",
sub "Turn them on so Sprout can nudge you.", chevron; tap = current enable/settings logic).
Empty HeroCard: watermark seedling bottom-right; "Your garden's\nempty — for now."
(Bricolage 24 white); body white@0.82 "Add the plants you own and Sprout keeps their watering
on track."; CreamInsetButton "+ Add your first plant" → add flow. Bento row: sage "My Plants"
sub "None yet"; oat "Rooms" sub "Set one up".

**03 Home — plants due (`home`, seeded).** Same top bar (no bell-slash when authorized).
Eyebrow time-of-day ("GOOD MORNING ☀️" / "GOOD AFTERNOON 🌤" / "GOOD EVENING 🌙" **⚑ derived**
for afternoon/evening); greeting reflects due count ("Two plants are\nready for a drink.").
HeroCard replaces old Water tile: watermark droplet top-right; eyebrow "TO WATER TODAY 💧";
numeral 60 (due count) + "plants need\nyour care" 15; avatar stack of due plants (36Ø,
border 2.5 `#285A40`, −12 overlap) + names line italic 13.5 white@0.8 ("Basil & Willow");
CreamInsetButton "Water these two" (count-aware copy) + arrow → guided watering (due mode).
Bento: sage My Plants (token stack 38Ø + "6 growing") → plant list; oat Rooms (house bubble +
"3 spaces") → rooms. Ghost row: "+ Add a plant" / "☑ Check in" (list-check) → add sheet /
full check-in cover (all-plants mode).

**03b Home — all watered — ⚑ derived.** Same layout; eyebrow "ALL DONE FOR TODAY 🌿";
greeting "Everything's\nwatered."; hero: watermark check-circle; success token 60Ø (white
check 26) in place of numeral; line "Nothing needs water today." 15 white; sub italic 13.5
white@0.8 "Next up: {plant} in {N} days." (omit if nothing scheduled); NO cream button.
Ghost row unchanged.

**04 My Plants (`plants`).** Nav "‹ Home" green 17 w500 + green FAB right. Title "My Plants"
Bricolage 32. PlantRows (gutter 18, gap 11), sorted soonest-due first; meta shows cadence +
adaptation suffix. Row → detail push.

**05 My Plants — empty + swipe.** Empty: 84Ø green token ph-flower; "No plants yet"
(Bricolage 22); body "Add the plants you own and Sprout will keep their watering on track.";
PrimaryButton (r14 p13×24) "Add your first plant". Swipe actions on rows: Edit `#5E8CA8`
(pencil+label) and Delete `#C4553B` (trash) 70pt full-height; Delete opens the delete
confirmation (09).

**06 Plant detail (`detail`).** Nav "‹ Plants" / "Edit" text button. Centered header:
PlantToken 112 (photo wins) + name Bricolage 32 + italic species 16 `#7C8173`.
Schedule card (white r20, 3 zones, inset dividers): (1) 34×34 r10 soft-green droplet bubble;
"Due in 2 days" Bricolage 17 in due-status color; sub "Tap to adjust when it's next due" 12
`#9AA090`; trailing pencil — row opens 07. (2) RhythmBand (§2.11) fed by species min/max,
base and effective interval. (3) why sentence 13 `#6E7A63`. PrimaryButton "✓ Check in on
{name}" → check-in sheet. Eyebrow "CHECK-IN HISTORY"; white r18 card rows: date 15 w600 +
"Soil dry · Leaves fine" 12.5 + trailing "💧 Watered" 12.5 w700 green when watered; dividers.

**07 Adjust schedule sheet.** Medium detent over detail. Handle; Cancel / "Adjust schedule" /
Save. Label "Water this plant in" 15 w600 `#6E7A63`. Wheel (0–365): "Today / 1 day / 2 days
/ …" selected Bricolage 23. Footer hint "Sets the next-watering date. Future check-ins keep
adapting it."

**08 Edit plant (`edit`).** Sheet Cancel / "Edit Plant" / Save. "PHOTO": white row — 64Ø
PlantToken (photo wins) + "Change photo" green 17 → single camera (26). **⚑ derived:**
"ICON" section under PHOTO: white row — current glyph in 34Ø token + "Change icon" green 17
→ icon picker (11b). "NICKNAME": white field. "ROOM": white row + menu picker. No species
field (locked). Bottom, 30 gap: white r18 row, border `rgba(196,85,59,0.2)`: "🗑 Delete
Plant" 17 w600 red → 09.

**09 Delete plant confirmation — NEW.** Scrim `rgba(25,40,30,0.4)`; AlertCard: red-tinted
trash circle; "Delete {name}?"; "This removes the plant and its check-in history. This can't
be undone."; Cancel / Delete(red).

**10 Add flow — room step (`addflow`).** Full-height sheet; handle; right "Cancel". Title
Bricolage 28 "Where do they\nlive?"; body "First pick the room these plants live in — its
light and humidity set how often they're watered." "YOUR ROOMS": white r18 rows — 40×40 r12
oat-tinted house bubble + name Bricolage 17 + env sub 12.5 ("Bright · Normal") + chevron.
GhostButton "+ Add a new room" → add-room sheet (16). Text "Skip — no room for now" 15 w500
`#8A9080`.

**11 Add flow — basket step (`basket`).** Header Cancel / "Add Plants". Room summary row
(white r16: house + room name + trailing "Change" green) → back to step 1. "BASKET · N":
compact rows (white r15, PlantToken 34, name + italic species, trailing green shuffle =
re-roll nickname). **⚑ derived:** tapping a basket row's token opens the icon picker (11b)
for that plant. "ADD SPECIES": search field `rgba(120,120,110,0.1)` r13 + magnifier; results
white r14 rows with trailing green circle-plus. Pinned PrimaryButton "Add N Plants".
Species display (**⚑ derived** rule): search results show the care-DB display name; once in
basket/rows, show nickname + the DB's Latin/scientific name italic (fall back to display
name if no Latin name).

**11b Icon picker — NEW.** Sheet Cancel / "Choose an icon" / Done. Preview: 88Ø token with
current icon + name Bricolage 20 + italic species. "PICK AN ICON": 4-col grid gap 12,
square r18 cells — selected solid brandGreen white glyph shadow; idle white, hairline
border, glyph `#3A4136` 28. The 16 Phosphor icons. Footer "Set the look now — you can
change it anytime from the plant's page."

**12 Photo prompt (`photoprompt`).** Bottom sheet: 104Ø gradient circle with cream camera
40; "Three plants added 🌱" (count-aware) Bricolage 27; body "Add a photo of each so they're
easy to spot. You can always do this later."; PrimaryButton "Take Photos"; text "Skip
photos".

**13 Sequential capture (`camera`).** Full cover `#10160E`. Header: name Bricolage 22 white;
"*{species}* · 2 of 3" 14 white@0.6. Square viewfinder margin 22 r26. Success state: 3px
`#4FC07E` border, overlay `rgba(63,126,88,0.5)`, white check-circle 72 pop-in
(scale 0.5→1.1→1, 0.5s), "Saved — next plant" Bricolage 18 white. Bottom: "Skip" 17 white /
white shutter (84Ø ring 4px + 70Ø fill).

**14 Rooms (`rooms`).** Nav "‹ Home" + green FAB. Title "Rooms" Bricolage 32. Rows white
r20: 44×44 r14 oat bubble with per-room FA icon (§1.4 mapping) `#B4832F`; name Bricolage 18;
env sub 12.5; trailing "{N} plants" 13 w600 taupe + chevron. **Tap → room detail (15), NOT
the editor.** **⚑ derived:** swipe-delete on rows → room delete confirm (15b).

**15 Room detail — NEW (`roomdetail` — new hook).** Nav "‹ Rooms" / "Edit" → editor (17).
Title = room name Bricolage 32. Stat duo: oat card (sun `#D98B0A`, "Brightness", value
Bricolage 19) + sage card (droplet green, "Humidity", value). InfoBanner (arrow-trend-up):
"Bright light dries soil faster — plants here are watered about {P}% more often." — copy
formula **⚑ derived**: P = round(|1 − environmentFactor| × 100); factor >1 → "more often",
<1 → "less often", =1 → "Balanced light and humidity — no adjustment to watering here."
"PLANTS IN THIS ROOM": compact rows (PlantToken 40, name, italic species, small DueChip) →
plant detail. Empty (**⚑ derived**): hint text "No plants in this room yet."

**15b Room delete confirmation — ⚑ derived.** AlertCard: red trash circle; "Delete {room}?";
"Its {N} plants stay in your garden without a room's light and humidity. This can't be
undone." (0 plants: "This can't be undone."); Cancel / Delete(red). Entry: swipe on 14 +
**⚑ derived** a "Delete Room" red row at the bottom of the editor (17), mirroring 08.

**16 Add room (`addroom`).** Sheet Cancel / "Add Room" / Add. "ROOM TYPE": white card with
wheel (Kitchen / Bedroom / Living Room / Bathroom / Dining Room / **Other… ⚑ derived**),
selected Bricolage 20. "TYPICAL SETTINGS": white card — "Brightness" → amber chip, divider,
"Humidity" → green chip; values live-update with the wheel. **⚑ derived Other… path:**
selecting Other swaps TYPICAL SETTINGS for: name field + the DIRECT SUN / INDIRECT SUN /
HUMIDITY segmented controls from 17. Footer "Pick a common room and Sprout fills in typical
light and humidity — fine-tune it later by editing the room."

**17 Edit room (`roomeditor`).** Sheet Cancel / "Edit Room" / Save. Name field. "DIRECT SUN
ⓘ": segmented Low/Medium/High. "INDIRECT SUN ⓘ": segmented Low/Medium/High. Live readout
card: sun icon + "Brightness" + amber chip, helper "Inferred from direct + indirect light.
Brighter rooms dry out faster, so plants there are watered more often." "HUMIDITY":
segmented Dry/Normal/Moist. Keep current ⓘ popover copy (RoomInfoHeader). Bottom
**⚑ derived**: "Delete Room" red row → 15b.

**18 Check-in input (`checkin`).** Full sheet Cancel / "Check in". Header: PlantToken 60 +
name Bricolage 21 + italic species. "SOIL": segmented Dry/Moist/Wet. "LEAVES": segmented
Fine/Droopy. Toggle row white r16 "I watered it" + switch (off track `#D6D0C0`). Helper
"Sprout learns each plant's true rhythm from these quick reads and adjusts its schedule."
Pinned PrimaryButton "Save check-in".

**19 Check-in recommendation.** Sheet header (spacer) / "Recommendation" / Done. Centered:
100Ø tinted circle + icon 46 (per-outcome, §4); headline Bricolage 23 (outcome copy, §4).
"NEXT": white r16 row "Next watering" 17 / date Bricolage 17 w700 green.

**20 Guided watering — report (`water`).** Full cover on paper. Header "Close" / "Water your
plants" Bricolage 17 / "Skip". Progress: 5px track `#E1DBCB` + green fill (position/total).
Hero: PlantToken 120 + name Bricolage 22 + "*{species}* · 1 of 2". "HOW DOES IT LOOK?":
segmented Fine/Droopy. "HOW'S THE SOIL?": segmented Dry/Moist/Wet. Pinned PrimaryButton
"Check".

**21 Guided watering — action.** Same chrome. Recommendation card white r22 p26×22:
78Ø tinted circle + icon 34; headline Bricolage 20 (outcome copy §4). Pinned: PrimaryButton
"💧 I watered it" + text button "Didn't water — next" green 17 w600. Schedule only advances
on a real water (current rule).

**22 Guided watering — done.** Header "Close" only. 104Ø success token (white check 46,
pop-in); "All done 🌿" Bricolage 27; body "You've been through every plant that needed water
today."; PrimaryButton "Done". (Full-check-in mode body **⚑ derived**: "You've checked in on
every plant.")

**23 Daily digest notification.** Content unchanged ("Time to water your plants 🌱" /
"N plants need watering today.") — no app work beyond keeping copy; mock is illustrative.

**24 Settings (`settings`).** Sheet (spacer) / "Settings" / Done. "REMINDERS": white r16 row
"Reminder time" + soft-green chip "9:00 AM" (opens time picker). Helper "Watering reminders
arrive at this time on the day a plant is due — pick a window you're usually home."
"DEVELOPER": white card rows — "Camera diagnostics" (file icon, chevron) / "Send a test
reminder (5s)" (bell) / "Delete all plants & rooms" (trash, red). Helper "Diagnostics
capture camera issues. The test reminder fires in 5 seconds. Deleting is permanent."
**⚑ derived:** "Delete all" gets an AlertCard confirm (mirrors 09; title "Delete
everything?", body "Every plant, room and check-in will be removed. This can't be undone.").

**25 Camera diagnostics.** Nav "‹ Settings" / "Diagnostics" Bricolage 16 / refresh icon.
Terminal card `#232821` r16, mono 11.5 lh1.75 `#C7D0BE` (+timestamp/success/warning colors
§1.2). Bottom frosted toolbar (`rgba(244,241,231,0.92)` blur, top border): Share / Copy
(green) / Clear (red) — icon over 11px label.

**26 Single-shot camera.** Full cover `#10160E`; "Take a photo" Bricolage 22 white; square
r26 viewfinder; bottom "Cancel" + white shutter. From Edit Plant "Change photo".

## 4. Check-in outcome voice — ⚑ derived (unified, replaces mixed copy)

Headline pattern: **"{Action} — {reason}."** Icon in a 0.12-alpha tinted circle, icon at
full tint. Mapping for the existing engine outcomes:

| Outcome | Icon (FA) | Tint | Headline template |
|---|---|---|---|
| Water now (on schedule) | droplet | `#2F6B4C` | "Water now — right on schedule." |
| Water now (dried early) | droplet | `#2F6B4C` | "Water now — it dried out faster than expected." |
| Water now (overdue) | droplet | `#2F6B4C` | "Water now — it's been waiting since {date}." |
| Water lightly | droplet (half-size 0.8 scale) | `#5FB4A2` | "Water lightly — the soil isn't fully dry yet." |
| Skip (soil wet) | circle-check | `#B4832F` | "Skip today — the soil's still wet. Back in about {N} days." |
| Skip (watered) | circle-check | `#B4832F` | "All set — you've just watered it." |
| Monitor (droopy but moist) | circle-info | `#7C8173` | "Hold off — droopy leaves but damp soil. Check again tomorrow." |
| Monitor (generic) | circle-info | `#7C8173` | "Nothing to do — looking fine. Next check {date}." |

Map each existing engine recommendation case to the closest row; reasons may be adapted to
the engine's actual reason strings, keeping the "{Action} — {reason}." shape and these
icon/tint pairings. Same mapping used in check-in sheet (19) and guided watering (21).

## 5. Data-model addition

`Plant.icon: String` — the Phosphor icon name (e.g. `"ph-flower"`), persisted (SwiftData
schema addition, lightweight migration; default assigned at creation deterministically from
the species' category, falling back to `"ph-plant"` **⚑ derived**). Token gradient remains
derived from plant UUID (no stored field).

## 6. Bundled assets (committed under Sources/)

- `Sources/Fonts/` — Bricolage Grotesque + Hanken Grotesk TTFs (static weights; OFL
  licenses alongside). Wire via `project.yml` resources + `UIAppFonts` in Info.plist.
- Asset catalog `Sources/Assets.xcassets/RedesignIcons/` — template-rendered vector
  imagesets: `ph-*` (16 Phosphor, MIT) and `fa-*` (FontAwesome 6 Free solid, CC BY 4.0 —
  attribution in Settings or LICENSES file). Recolor via `.foregroundStyle`/tint;
  `.renderingMode(.template)`.
- PostScript font names are recorded in `Sources/Fonts/FONTS.md` at asset-commit time —
  builders use those exact names in `Font.custom`.

## 7. Explicit non-goals this wave

Dark mode; tab bar or navigation changes; widget/watch surfaces; changing the notification
digest logic; Night Garden styling.
