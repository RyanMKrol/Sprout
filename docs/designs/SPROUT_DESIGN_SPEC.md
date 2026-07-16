# Sprout — Complete Product & Flow Specification

**For:** External design agency undertaking a full visual redesign
**Prepared:** 2026-07-16
**Source of truth:** the current `main` build (55 Swift files). Every string, colour, SF Symbol, font, and numeric constant below is taken verbatim from the shipping code — nothing is invented. Where the code reveals a design inconsistency or gap, it is flagged as **⚑ Redesign flag**.

> **How to read this document.** Sections 1–3 give you the product, the design system, and the navigation map — read these first. Section 4 is the screen-by-screen bible (every element, state, and interaction). Section 5 explains the adaptive watering engine — the "brains" you must be able to *visualise* accurately. Sections 6–9 are reference appendices: data model, full copy inventory, full symbol inventory, and the consolidated list of redesign flags.

---

## 1. Product Overview

**Sprout** is an iOS app (SwiftUI, iOS 18+) for tracking the care of houseplants. The user adds the plants they own; Sprout proposes a **per-plant watering schedule** seeded from a bundled database of **335 common UK houseplants**, then personalises it over time from two signals:

1. **Check-ins** — a quick soil "knuckle-test" (Dry / Moist / Wet) and a glance at the leaves (Fine / Droopy), plus "did you water it?".
2. **Room environment** — every plant lives in a **Room** whose light and humidity make its plants dry out faster or slower.

Sprout sends a **once-a-day watering reminder** at a time the user chooses, and always explains **why** a plant's schedule is what it is in plain language.

### The core mental model (designers must convey this)
- A plant has a **species** (fixed once created) which seeds a base watering cadence.
- The plant lives in a **room** (light + humidity) which speeds up or slows down that cadence.
- Each **check-in** nudges the cadence toward the plant's *real* rhythm ("it dried out faster than expected → water more often").
- The result is always fenced within the species' safe **min/max day band** — the schedule can never recommend watering more often than the floor nor stretch past the ceiling.

### Product principles baked into the current build
- **No abstract "health" score.** Sprout only records *observable* facts (soil state, leaf droop, watered yes/no). Every recommendation and explanation is derived from those plus species + room.
- **One reminder a day, not one per plant.** A digest: "N plants need watering today."
- **Always explain the "why."** Every plant surfaces a plain-language sentence for its schedule.
- **Forgiving, low-effort input.** Segmented pickers with sensible defaults; random auto-names so adding plants is fast.

---

## 2. Design System (current state)

This is the visual vocabulary the redesign will replace or evolve. It is coherent and worth understanding before diverging.

### 2.1 Brand / accent
- **Accent colour** (`AccentColor` asset): `sRGB(0.298, 0.733, 0.357)` ≈ **`#4CBB5B`** — a fresh leaf green. Applied to system controls, "add species" buttons, and the photo-prompt CTA.
- App display name: **Sprout**. Wordmark currently rendered as the plain large navigation title "Sprout 🌱" concept (title text is "Sprout").

### 2.2 The five gradient "tile" styles — the app's core identity
The Home screen is a **bento grid** of gradient tiles. Each tile is a two-stop **diagonal `LinearGradient`** (`.topLeading → .bottomTrailing`), white content, a **24pt continuous-corner** rounded rectangle, and a soft shadow tinted to the *lighter* stop (`opacity 0.35, radius 10, y 6`). Each tile carries a **frosted circular icon badge** (`white.opacity(0.22)` circle, white SF Symbol at `.semibold`, glyph = 50% of badge size).

| Style | Stop 1 (RGB 0–1) | Stop 2 | Hex approx. | Reads as | Used for |
|---|---|---|---|---|---|
| `.plants` | (0.36, 0.80, 0.46) | (0.13, 0.62, 0.40) | `#5CCC75`→`#219E66` | green | My Plants tile |
| `.rooms` | (0.97, 0.64, 0.28) | (0.88, 0.42, 0.24) | `#F7A347`→`#E06B3D` | orange | Rooms tile |
| `.add` | (0.22, 0.76, 0.70) | (0.15, 0.52, 0.74) | `#38C2B3`→`#2685BD` | teal→blue | Add-plants CTA |
| `.water` | (0.27, 0.67, 0.96) | (0.16, 0.46, 0.87) | `#45ABF5`→`#2975DE` | blue | Water action tile + notification-intro icon |
| `.checkIn` | (0.52, 0.43, 0.93) | (0.37, 0.31, 0.82) | `#856DED`→`#5E4FD1` | violet | Full-check-in action tile |

### 2.3 The per-plant colour palette (`PlantPalette`)
Photo-less plants show a **tinted `leaf.fill` glyph**. The tint is picked **deterministically per plant** (sum of the plant's UUID unicode scalars mod 10 — stable across launches) from ten vibrant hues:

| Name | RGB (0–1) | Hex approx. |
|---|---|---|
| red | (0.94, 0.27, 0.27) | `#F04545` |
| orange | (0.96, 0.55, 0.13) | `#F58C21` |
| amber | (0.98, 0.78, 0.18) | `#FAC72E` |
| green | (0.40, 0.78, 0.22) | `#66C738` |
| teal | (0.13, 0.72, 0.55) | `#21B88C` |
| blue | (0.20, 0.62, 0.92) | `#339EEB` |
| indigo | (0.36, 0.40, 0.92) | `#5C66EB` |
| violet | (0.61, 0.35, 0.91) | `#9C59E8` |
| pink | (0.92, 0.36, 0.65) | `#EB5CA6` |
| brown | (0.78, 0.45, 0.20) | `#C77333` |

The placeholder glyph sits on a `tint.opacity(0.15)` background inside a **10pt** rounded square (`PlantThumbnail`). Thumbnail sizes in use: **44** (list rows), **64** (edit form), **120** (guided watering), **170** (plant detail header).

### 2.4 Status colours (watering `DueStatus`)
One shared colour language for "how urgent is this plant," used by list pills and the detail schedule row:

| Status | Label | Colour |
|---|---|---|
| Overdue | "Overdue by N day(s)" | **red** |
| Due today | "Due today" | **orange** |
| Due later | "Due in N day(s)" | **blue** |
| No schedule | "No schedule" | **secondary (grey)** |

Recommendation icons in check-in results use a parallel scheme: water now → **blue**, water lightly → **teal**, skip → **orange**, monitor → **secondary**.

### 2.5 Typography (system fonts throughout — SF Pro)
No custom fonts. Semantic text styles used:
- Screen greeting / section intros: `.headline`, secondary.
- Tile titles: `.title3.bold()`. Tile captions: `.subheadline`, `white.opacity(0.9)`.
- Plant name — list `.headline`, detail header `.largeTitle.bold()`, guided/capture `.title2.bold()`.
- Recommendation message: `.callout.weight(.medium)`.
- Body copy in sheets: `.body` / `.callout`, secondary.
- Captions & "why" summaries: `.caption`, `.caption2`, `.footnote`, in secondary/tertiary.
- Diagnostics log: `.footnote` **monospaced**.

### 2.6 Spacing & geometry constants
- Screen padding **16pt**; primary vertical stack spacing **16pt**; row HStack spacing **16pt** (and **12pt** in list rows).
- Bento tiles: **18pt** internal padding, **24pt** continuous corners; square tiles are 1:1; action tiles `minHeight 132`.
- Cards/banners: **16pt** corners; photo-capture preview **16pt**; photo-prompt icon tile **18pt**; thumbnail **10pt**.
- Backgrounds: `Color(.systemGroupedBackground)` for screens; `Color(.secondarySystemGroupedBackground)` for inset cards.

### 2.7 Shared components (define once in the new system)
- **`PlantThumbnail`** — square photo, or tinted `leaf.fill` placeholder. Sizes 44/64/120/170.
- **`HomeTileStyle` family** — the five gradient tiles (square, wide, action variants).
- **Due pill** — capsule, `dueColor.opacity(0.15)` fill, `dueColor` text, `.caption2.bold()`, padding h10/v4.
- **`RoomInfoHeader`** — a section title + an `info.circle` ⓘ button opening a 280pt popover of help text.
- **Segmented pickers** — the universal input for soil/leaves/light/humidity.
- **`ContentUnavailableView`** — the standard empty/error state across every list.

---

## 3. Information Architecture & Navigation Map

### 3.1 Shell
- **Entry:** `SproutApp` → `ContentView` (composition root; builds repository, care database, list view-model, notification gatekeeper) → **`HomeView`**, which owns the app's **single `NavigationStack`**.
- There is **no tab bar.** The Home bento grid *is* the navigation hub. Everything is reached from Home via push, sheet, or full-screen cover.

### 3.2 Navigation types
- **Push (stack):** Home → My Plants; Home → Rooms; My Plants → Plant Detail.
- **Sheets (modal):** Settings; Add-plants flow; Photo prompt; Notification intro (first run); Check-in; Add/Edit Room; Edit Plant; manual schedule override.
- **Full-screen covers (immersive):** Camera (sequential capture) and Guided Watering — driven by **one shared cover** (`enum FullScreenFlow`) because two covers on one view conflict on-device (black-screen bug). **⚑ Preserve this single-cover constraint.**

### 3.3 Full navigation map from Home
| Home element | Destination | Presentation |
|---|---|---|
| "My Plants" square tile | Plant list | Push |
| "Rooms" square tile | Rooms list | Push |
| "Add plants" wide CTA | Add flow → (chains to) Photo prompt → Camera | Sheet → sheet → cover |
| "Water" action tile | Guided Watering (due plants only) | Cover |
| "Full check-in" action tile | Guided Watering (all plants) | Cover |
| Toolbar gear (trailing) | Settings | Sheet |
| Toolbar bell-slash (leading, conditional) | Enable notifications / open system Settings | No navigation |
| "Reminders are off" banner | Enable notifications / open system Settings | No navigation |

### 3.4 The signature chained flow (Add → Photograph)
The most complex sequence, orchestrated via **staged sheet dismissals** to avoid present-while-dismissing races:

```
My Plants  →  [+]  →  "Where do they live?" (pick/add room)
           →  "Add Plants" (search species → basket → confirm "Add N Plants")
           →  sheet dismisses → "New plants added" prompt
           →  "Take Photos" → sheet dismisses → sequential Camera (one plant at a time)
           →  back to My Plants
```
**⚑ Redesign flag:** any nav rework must preserve "present the next screen only after the previous fully dismisses."

---

## 4. Screen-by-Screen Specification

### 4.1 HOME (`HomeView`)

**Container:** `ScrollView` → `VStack(spacing 16)` → `.padding(16)`, over `systemGroupedBackground`. Nav title **"Sprout"** (large).

**Top-to-bottom layout:**
1. **Greeting line** (status-aware, `.headline` secondary):
   - No plants → **"Let's add your first plant 🌱"**
   - All watered → **"Everything's watered — nice work 🌿"**
   - Plants due → **"N plants need water today 💧"** (singular "1 plant needs water today 💧").
2. **"Reminders are off" banner** (only when notification permission is not-determined or denied) — tappable card: `bell.slash.fill` (orange) + **"Reminders are off"** / **"Turn on notifications so Sprout can remind you to water."** + `chevron.right`. On `secondarySystemGroupedBackground`, 16pt corners, 1pt `orange.opacity(0.4)` stroke.
3. **Two square "place" tiles** (row):
   - **My Plants** — `leaf.fill`, green gradient. Caption: "Add your first plant" / "1 plant" / "N plants". → push list.
   - **Rooms** — `house.fill`, orange gradient. Caption fixed **"Light & humidity"**. → push Rooms.
4. **"Add plants" wide tile** — `plus.circle.fill` (48pt badge), teal→blue gradient, `chevron.right`. Title **"Add plants"**, subtitle **"Pick a room, then add its plants"**. → Add flow sheet.
5. **"Today" section heading** (`.subheadline.weight(.semibold)`, secondary).
6. **Two action tiles** (row):
   - **Water** — `drop.fill`, blue gradient. Subtitle "Nothing due right now" / "N due now". **White capsule count badge** when due > 0. **Pulses** (scale 1.0↔1.03, shadow radius 8↔18 / opacity 0.25↔0.7, `easeInOut 1.1s repeatForever`) when due > 0. → Guided Watering (due).
   - **Full check-in** — `checklist`, violet gradient. Subtitle "No plants yet" / "Check every plant". Never badges/pulses. → Guided Watering (all).

**Toolbar:** trailing gear (`gearshape`) → Settings. Leading `bell.slash.fill` (orange, conditional) → enable notifications.

**Data sources:** `listViewModel.dueCount` (due today + overdue), `listViewModel.items.count`, `gatekeeper.needsAttention`. Only the reminders-off banner + bell are conditional; everything else is always present with copy/badge/pulse driven by data.

---

### 4.2 MY PLANTS (`PlantListView`)

**Nav title** "My Plants". `List` with `.insetGrouped` style. Toolbar `+` **"Add Plants"**.

**Row (`PlantCardView`), HStack spacing 12:**
- **`PlantThumbnail` 44pt**, tinted per-plant (`PlantPalette`).
- Name `.headline`; species (capitalised) `.caption` secondary; optional **"why" summary** `.caption2` tertiary — e.g. **"Every 5d · shortened"**, **"Every 7d · stretched"**, **"Every 7d"**.
- Trailing **due pill** (see §2.4).
- Tap → Plant Detail (push). Trailing swipe → **Delete** (red, destructive, **no confirmation ⚑**) and **Edit** (blue).

**Ordering:** soonest `nextDue` first; unscheduled last; nickname tie-break. No manual reorder, no sections.

**Empty state:** `ContentUnavailableView` — `leaf.fill`, **"No plants yet"**, **"Add the plants you own and Sprout will keep their watering on track."**

This screen also coordinates the whole Add → Photo-prompt → Camera chain via four presentations.

---

### 4.3 PLANT DETAIL (`PlantDetailView`)

A `Form`; **no nav-bar title** (the in-content header names the plant); trailing **Edit** button.

**a. Header** (centered): `PlantThumbnail` **170pt** (per-plant tint) → nickname `.largeTitle.bold()` → species (capitalised) `.headline` secondary.

**b. Schedule section** ("Schedule"):
- **Tappable row**: `drop.fill` (in due colour) + due label (`.subheadline.semibold`, due colour) + trailing `pencil`. Hint "Adjust when this plant is next due." → opens manual override sheet.
- **"Why this schedule" sentence** (`.footnote` secondary), e.g. **"Every 5 days — shortened from 6 because it dried out faster than expected."** Fallback when species unknown: **"Watering schedule coming soon."**

**c. Manual schedule override** (`ScheduleEditorSheet`, medium detent): title **"Adjust schedule"**, heading **"Water this plant in"**, **wheel picker 0…365** ("Today" for 0, else "N day(s)"), caption **"Sets the next-watering date. Future check-ins keep adapting it."**, Cancel / Save.

**d. Check-in CTA**: full-width **"Check in"** (`checkmark.circle`). → Check-in sheet.

**e. Check-in history** ("Check-in history"): empty → **"No check-ins yet."**; else rows (most recent first): date + optional `drop.fill` (blue, "Watered"), and **"Soil {dry/moist/wet} · Leaves {fine/droopy}"**.

**Error state:** `ContentUnavailableView` "Plant unavailable" / `exclamationmark.triangle` / "This plant could not be loaded."

---

### 4.4 ADD PLANTS — room-first "basket" flow (`AddFlowView` + `BasketAddViewModel`)

Two steps over one navigation stack. Toolbar always "Cancel."

**Step 1 — Room** (title **"Where do they live?"**):
- Intro: **"First pick the room these plants live in — its light and humidity set how often they're watered."**
- `Section("Your rooms")`: each room a button row (name `.headline`, `environmentSummary` e.g. **"Bright · Normal"** `.caption` secondary, `chevron.right`). Tap → advance with that room.
- Bottom: **"Add a new room"** (`plus.circle.fill`) → Add Room sub-sheet; **"Skip — no room for now"** → advance with no room.

**Step 2 — Plants** (title **"Add Plants"**):
- `Section("Room")`: `house.fill` + room name (or "No room") + borderless **"Change"** (returns to step 1, basket preserved).
- **Basket** section: empty prompt **"Tap a species below to add it. Each plant gets a random name you can edit."** Populated → `Section("Basket (N)")`, each row: editable nickname `TextField` + species (capitalised) + `shuffle` re-roll button + swipe-to-remove.
- **"Add species"** section: `TextField("Search species")` filtering the 335-species DB; results are button rows (species capitalised + trailing `plus.circle.fill` in accent). Tap → adds a basket entry with a random name.

**Auto-naming:** each plant gets a random English first name from a curated ~300-name pool (≈140 girls', ≈140 boys', 20 nature-unisex e.g. "Ash", "Basil", "Fern", "Juniper", "Willow"), unique where possible, suffixing "Name 2" when exhausted.

**Commit:** button **"Add Plant"** / **"Add N Plants"** (disabled unless every entry resolves + basket non-empty). Creates each plant, assigns the room, seeds an initial `nextDue` from species cadence × room factor (assumes just-watered now).

**Add Room sub-sheet** — identical to §4.6.

---

### 4.5 EDIT PLANT (`PlantEditView`)

`Form`, title **"Edit Plant"**, Cancel / Save (Save disabled if nickname blank). **Species is NOT editable** (fixed after creation).
- `Section("Photo")`: `PlantThumbnail` **64pt** (⚑ uses default green tint, not the per-plant palette used everywhere else — **inconsistency to unify**) + **"Change photo"** / **"Add photo"** → single-shot camera. Transactional (Cancel discards).
- `Section("Nickname")`: text field.
- `Section("Room")` (only if rooms exist): picker with **"None"** + each room.

**Delete** lives **only** on the list swipe — there is no delete on the edit form, and no confirmation dialog anywhere. **⚑**

---

### 4.6 ROOMS

**Rooms list (`RoomsView`)** — nav title "Rooms", `List`, toolbar `+`.
- Row: name `.headline` + `environmentSummary` (e.g. **"Bright · Dry"**, `.caption` secondary) + trailing plant count **"N plants"**. Tap → **Edit Room** (⚑ not a plant list — there is no room→plants drill-in). Swipe → Delete (nils assigned plants' room; plants never deleted; no confirmation ⚑).
- Empty: `ContentUnavailableView` — `house`, **"No rooms yet"**, **"Add the rooms your plants live in. Their light and humidity set each plant's watering rhythm."**

**Add Room (`AddRoomView`)** — `Form`, title "Add Room", Cancel / **Add**.
- **Wheel picker** "Room type": the 10 presets + **"Other…"**.
- Preset selected → read-only `Section("Typical settings")`: **Brightness** + **Humidity** values. Footer: "Pick a common room and Sprout fills in typical light and humidity — you can fine-tune it later by editing the room."
- "Other…" selected → custom controls: **Name** field, **Direct Sun** (segmented Low/Medium/High + ⓘ), **Indirect Sun** (segmented + ⓘ), **Humidity** (segmented Dry/Normal/Moist). Footer: "Name your room and choose its light and humidity." (⚑ custom path omits the live inferred-Brightness readout that the editor has.)

**The 10 presets** (name → Direct / Indirect / Humidity → inferred Brightness):

| Preset | Direct | Indirect | Humidity | Brightness |
|---|---|---|---|---|
| Living Room | Medium | High | Normal | Bright |
| Kitchen | Medium | High | Normal | Bright |
| Bedroom | Low | Medium | Normal | Dark |
| Bathroom | Low | Medium | Moist | Dark |
| Dining Room | Medium | Medium | Normal | Medium |
| Office | Medium | Medium | Dry | Medium |
| Hallway | Low | Low | Normal | Dark |
| Conservatory | High | High | Dry | Bright |
| Kids' Room | Low | Medium | Normal | Dark |
| Balcony | High | High | Dry | Bright |

**Edit Room (`RoomEditorView`)** — title "Edit Room", Cancel / Save. Sections: Name; Direct Sun (segmented + ⓘ); Indirect Sun (segmented + ⓘ); **Brightness** (read-only inferred: Dark/Medium/Bright, footer "Inferred from direct + indirect light. Brighter rooms dry out faster, so plants there are watered more often."); Humidity (segmented).

**Light model:** `Brightness = score(directSun×2 + indirectSun)`; weights Low=0/Medium=1/High=2; bands 0–1 Dark, 2–3 Medium, 4–6 Bright. Humidity: Dry/Normal/Moist.

**ⓘ help text (verbatim):**
- Direct Sun: "How much direct sunlight lands on the plants — e.g. an unobstructed south-facing windowsill. Direct sun dries the soil fastest."
- Indirect Sun: "The ambient daylight in the room with no direct beam on the leaves — bright rooms away from a window still get plenty."

**Room→plant link:** plants store an optional `roomID`; assignment happens in the **Plant edit form** (not from Rooms). A room with no plants gets the neutral schedule factor.

---

### 4.7 CHECK-IN (single plant, `CheckInView`)

Sheet, `.inline`. **Two states** toggled by whether a result exists.

**State 1 — Input** (title "Check in", leading "Cancel"):
- `Section("Soil")` — segmented **Dry / Moist / Wet** (default **Moist**).
- `Section("Leaves")` — segmented **Fine / Droopy** (default **Fine**).
- Unheaded section — toggle **"I watered it"** (default off). Footer: "Sprout learns each plant's true rhythm from these quick reads and adjusts its schedule."
- Submit — **"Save check-in"** (disabled if species not in DB; disabled footer explains why).

**State 2 — Result** (title "Recommendation", leading "Done"):
- Recommendation row: colour-coded icon (`drop.fill` blue = water now / `drop.fill` teal = water lightly / `hand.raised.fill` orange = skip / `eye.fill` grey = monitor) + message (`.callout.medium`).
- `Section("Next")` — `LabeledContent` labelled **"Next watering"** (if watered) or **"Check back"** (if not), value = the next date.

**Recommendation messages (check-in flow):**
| Reason | Message |
|---|---|
| stillWet | "Skip — the soil's still wet. Check back in 3 days." |
| driedEarly | "Water now — it dried out faster than expected." |
| onTargetDry | "Water now — right on schedule." |
| dontDryOut | "Water now — let's not let it dry out next time." |
| onTargetMoist | "Water lightly — right on schedule." |
| touchEarly | "A touch early, but fine to top up." |
| droopyDry | "Water now — the leaves are drooping." |
| droopyWet | "Leaves droop but the soil's wet — let it dry out; it may be overwatered." |
| droopyMoist | "Keep an eye on it — check back in 3 days." |

**Error state:** `ContentUnavailableView` "Check-in unavailable" / `exclamationmark.triangle`.

---

### 4.8 GUIDED WATERING — the "two modes" (`GuidedWateringView`)

Launched from Home's two action tiles. **Full-screen cover.** Title "Water your plants." Leading "Close", trailing "Skip" (per plant).

- **Mode 1 — "Water" (`.due`):** only plants that need water now.
- **Mode 2 — "Full check-in" (`.all`):** every plant, in list order.
- The two modes are **identical in flow** — only the plant set differs.

**Per plant, two sub-steps:**

**Step A — Report:** centered `PlantThumbnail` **120pt** (per-plant tint) + name `.title2.bold()` + species + progress **"N of M"**. `Section("How does it look?")` — segmented Fine/Droopy. `Section("How's the soil?")` — segmented Dry/Moist/Wet (defaults Moist/Fine). Button **"Check"** → previews recommendation **without persisting**.

**Step B — Recommendation:** message (`.callout.medium`), then:
- If it recommends water → **"I watered it"** (`drop.fill`) + **"Didn't water — next"**.
- If not → single **"Next plant"**.
- Confirming records the real check-in and advances; Skip advances without recording.

**Guided messages (note: several differ from the single check-in flow):**
| Reason | Guided message |
|---|---|
| stillWet | "Skip — the soil's still wet. Check back in 3 days." |
| driedEarly | "Water now — it dried out faster than expected." |
| onTargetDry | "Water now — right on schedule." |
| dontDryOut | "Water now — this one likes to stay moist." |
| onTargetMoist | "A light water — it's on track." |
| touchEarly | "A light top-up — a touch early but fine." |
| droopyDry | "Water now — it's drooping and dry." |
| droopyWet | "Skip — drooping but the soil's wet; let it dry out." |
| droopyMoist | "Hold off — keep an eye on it." |

**⚑ Redesign flag:** two parallel copy sets for the same nine outcomes. Consider unifying.

**Completion:** `ContentUnavailableView` — `checkmark.circle.fill`, **"All done"** / **"You've been through every plant."** (or "Nothing to water" / "No plants need water right now." if the list was empty). Button **"Done"** (borderedProminent).

---

### 4.9 PHOTO CAPTURE

**Two distinct camera screens** on black backgrounds.

**a. Single-shot (`CapturePhotoView`)** — used from Edit form. Heading "Take a photo"; square live preview (16pt corners) or placeholder (`camera.fill` + "Camera preview unavailable here"); controls: "Cancel" + centered shutter (72pt white fill inside 84pt 4pt-stroke ring). Capture shows a scrim + spinner.

**b. Sequential (`PhotoCaptureView`)** — used after Add, driven by `PhotoCaptureCoordinator`, **no back nav**. Top banner: name `.title2.bold()` + species + progress "N of M", with an **asymmetric slide transition** between plants (old slides out left, next in from right). Preview overlays: **white shutter flash**, **green success pulse** (`green.opacity(0.45)` + `checkmark.circle.fill` 72pt + **"Saved — next plant"** / **"All done!"**, border turns green). Controls: "Skip" + shutter.

**Capture feedback sequence:** medium haptic → shutter flash → save → success haptic + green pulse (~650ms) → advance (or fade whole screen out on the last plant). A **failed** capture flashes but shows no confirmation and stays for retry.

**Backend:** `PhotoCapturing` protocol seam. Real `AVFoundationCamera` (all session work off-main; unavailable if denied / no camera). `StubPhotoCapturing` for simulator returns a teal→indigo "Demo photo" image so flows are screenshottable. Photos are center-cropped square, ≤1024px edge, JPEG q0.7 (~150–300KB).

**Permissions:** camera permission string — "Sprout uses the camera to take a photo of each plant you add."

---

### 4.10 NOTIFICATIONS & ONBOARDING

**First-run intro (`NotificationIntroView`)** — sheet (medium/large detents), shown **once** when permission is still undetermined, *before* the system prompt.
- Icon badge: 110pt circle, blue gradient (same as `.water`), `bell.badge.fill` 46pt white, blue shadow.
- Title **"Never miss a watering"** (`.title.bold()`); body **"Sprout sends a once-a-day reminder when your plants need water, at a time you choose. Turn on notifications so it can reach you."**
- **"Enable reminders"** (borderedProminent) → triggers the system prompt; **"Maybe later"** → dismiss.

**Watering reminders — daily digest model:**
- **One notification per day**, at the chosen hour (`:00`), summarising how many plants need water. Overdue plants fold into today's reminder.
- Title **"Time to water your plants 🌱"**; body **"N plants need watering today."** (singular "1 plant needs watering today.").
- Rebuilt on launch and on every scene-phase change (idempotent; identifier prefix `sprout.watering.`).
- Foreground presenter forces banners even when the app is open.

**"Reminders off" indicators** (when not-determined or denied): the Home toolbar bell (`bell.slash.fill`, orange) and the Home banner. Tapping enables (or deep-links to system Settings if denied).

**Test reminder:** Settings ▸ Developer button schedules a one-off notification in 5s — title **"Test reminder 🌱"**, body **"If you can see this, watering reminders are working."**

---

### 4.11 SETTINGS (`SettingsView`)

`Form`, title "Settings" (inline), toolbar **"Done"**. Reached from the Home gear.

- **`Section("Reminders")`** — a `DatePicker` **"Reminder time"** (hour/minute; minutes ignored — scheduler pins `:00`; default **9:00**). Footer: "Watering reminders arrive at this time on the day a plant is due — pick a window you're usually home."
- **`Section("Developer")`** — **"Camera diagnostics"** (`doc.text.magnifyingglass`, → Diagnostics); **"Send a test reminder (5s)"** (`bell.badge`); **"Delete all plants & rooms"** (red, → confirmation dialog "Delete everything" / "Cancel"). Footer explains all three.

Historical note: a temperature-units picker and a weather toggle existed but were **removed** when phone-weather was retired in favour of Rooms — do not reintroduce them from old screenshots. Settings currently has **no toggles/steppers** — just one time picker and buttons.

**Diagnostics (`DiagnosticsView`):** an on-disk monospaced camera log (survives crashes). Empty state `doc.text.magnifyingglass` "No diagnostics yet". Toolbar Refresh; bottom bar Share / Copy / Clear.

---

## 5. The Adaptive Watering Engine (what designers must be able to visualise)

Everything the UI shows about a schedule comes from this pure logic. You don't implement it, but your visuals must be **truthful** to it.

### 5.1 The effective-interval formula
```
adj              = clamp(plant.adj, 0.5 … 2.0)              // learned personalisation
raw              = baseIntervalDays × environmentFactor × adj
effectiveInterval= clamp(round(raw), minIntervalDays … maxIntervalDays)
nextDue          = lastWatered (or now) + effectiveInterval days
```

**Four inputs:**
1. **Species seed** — `baseIntervalDays` with a hard **min/max day band** (the true visual range of any schedule). DB spans ~2–21 days.
2. **`adj`** — learned multiplier, default 1.0, clamped **0.5–2.0**. <1 waters more often; >1 less often.
3. **`environmentFactor`** — the **Room** factor (see §5.2), default 1.0 (neutral) when a plant has no room.
4. **`lastWatered`** — the anchor (falls back to "now" for a brand-new plant).

### 5.2 Room environment factor (`RoomEnvironment`)
`factor = brightnessFactor × humidityFactor`, clamped **0.7–1.3** (±30% max):

| Brightness | factor | | Humidity | factor |
|---|---|---|---|---|
| Dark | 1.15 (water less often) | | Dry | 0.90 (more often) |
| Medium | 1.00 | | Normal | 1.00 |
| Bright | 0.85 (water more often) | | Moist | 1.10 (less often) |

Extremes: Bright·Dry ≈ 0.765 (~24% more frequent); Dark·Moist ≈ 1.265 (~26% less frequent). Semantics: **>1 lengthens the interval, <1 shortens it.**

### 5.3 How a single check-in nudges the schedule (`AdaptiveEngine`)
Each check-in classifies timing (**on-time band = ±20%** of the interval) and applies a **multiplicative nudge** to `adj` (then re-clamps to 0.5–2.0). The decision table:

**Droopy leaves override everything (by soil):** dry → ×0.80 water now (`droopyDry`); wet → ×1.20 skip (`droopyWet`); moist → ×0.95 monitor (`droopyMoist`).

**Leaves fine:** wet → ×1.15 skip (`stillWet`); dry+early → ×0.85 water now (`driedEarly`); dry+on-time/late for a *stays-moist* species → ×0.90 water now (`dontDryOut`), else ×1.0 water now (`onTargetDry`); moist+early → ×1.05 water lightly (`touchEarly`); moist+on-time/late → ×1.0 water lightly (`onTargetMoist`).

**Advancing:** the schedule only *advances* when the engine recommended water **and** the user actually watered → `nextDue = checkIn.date + newInterval`. Otherwise it sets a **3-day recheck** (`recheckDays = 3`) — this is the source of every "check back in 3 days."

A single check-in moves `adj` by at most ±20%; nudges are cumulative across check-ins — that's how a plant "learns" its rhythm.

### 5.4 Moisture preference (what a soil reading *means*)
- **driesOut** (91 species) — succulents/cacti/snake plant; wants to dry fully.
- **evenlyMoist** (192 species — the majority) — pothos/monstera/most foliage; water when top inch dry.
- **staysMoist** (52 species) — ferns/calathea; keep lightly moist; "Dry" means overdue.

### 5.5 "Why this schedule" explanation (`ScheduleExplanation`)
Built from `species`, effective vs base days (**Direction**: shortened / stretched / unchanged), and a **Cause** (priority: last check-in that moved `adj` → else room factor → else starting/settled).

**Sentence templates:**
- unchanged, new plant → "Every N days — the starting cadence for {species}."
- unchanged, has history → "Every N days — settled back to its usual cadence." / "…holding at {species}'s usual cadence."
- changed → "Every N days — {shortened|stretched} from {base} because {cause}."

**Cause clauses:** dried out faster than expected / the soil was still wet last time / the soil was still moist last time / its leaves were drooping / it looked overwatered / its spot dries out faster than average / its spot dries out more slowly than average / of your check-ins.

**Examples:** "Every 5 days — shortened from 6 because it dried out faster than expected." · "Every 9 days — the starting cadence for Snake Plant." · "Every 10 days — stretched from 7 because the soil was still wet last time."

**List pill summary:** "Every Nd" + " · shortened" / " · stretched" (nothing when unchanged).

### 5.6 (Dormant) weather factor
A temperature-based `WeatherFactor` (neutral 16–24°C, ±0.02/°C, clamped 0.7–1.3) exists and maps to the same multiplier slot, but the live app drives that slot from **rooms**, not phone weather (weather was retired). Mention for completeness only.

---

## 6. Data Model (what data exists to display)

**Plant:** `id`, `nickname`, `species` (fixed), `adj` (0.5–2.0, default 1.0), `lastWatered?`, `nextDue?`, `checkIns[]`, `photoData?` (JPEG), `roomID?`.

**CheckIn:** `id`, `date`, `soil` (dry/moist/wet), `leaves` (fine/droopy), `watered` (bool). *No abstract health field — by design.*

**Room:** `id`, `name`, `directSun` (low/medium/high), `indirectSun` (low/medium/high), `humidity` (dry/normal/moist). Brightness is *inferred*, not stored. Derived `environmentSummary` e.g. "Bright · Dry".

**CareProfile (per species — the ONLY per-species data, 5 fields):** `species` (display name + key), `baseIntervalDays`, `minIntervalDays`, `maxIntervalDays`, `moisture` (driesOut / evenlyMoist / staysMoist). **335 species.** *No light/humidity/temperature/fertiliser/toxicity/description per species* — light & humidity live on the Room. **⚑ If the redesign wants richer species pages (care tips, toxicity, images), that data does not exist yet and must be sourced.**

**AppSettings:** `reminderHour` (0–23, default 9). Persisted as JSON in UserDefaults.

**Persistence:** SwiftData behind a `PlantRepository` protocol; photos in external storage; check-ins cascade-delete with their plant; deleting a room nils its plants' `roomID`.

---

## 7. Complete Copy Inventory (verbatim)

**Titles:** Sprout · My Plants · Where do they live? · Add Plants · Add Room · Edit Room · Edit Plant · Adjust schedule · New plants added · Take a photo · Water your plants · Check in · Recommendation · Settings · Camera diagnostics · Rooms · Plant / Plant unavailable · Check-in unavailable.

**Home greetings:** "Let's add your first plant 🌱" · "Everything's watered — nice work 🌿" · "N plant(s) need water today 💧".

**Home tiles:** "My Plants" / "Add your first plant" / "1 plant" / "N plants" · "Rooms" / "Light & humidity" · "Add plants" / "Pick a room, then add its plants" · "Today" · "Water" / "Nothing due right now" / "N due now" · "Full check-in" / "No plants yet" / "Check every plant".

**Empty states:** "No plants yet" / "Add the plants you own and Sprout will keep their watering on track." · "No rooms yet" / "Add the rooms your plants live in. Their light and humidity set each plant's watering rhythm." · "No check-ins yet." · "No diagnostics yet" / "Reproduce the issue (e.g. take a photo), then come back here. The log is captured even if the app crashes."

**Buttons/actions:** Add Plants · Add Plant / Add N Plants · Delete · Edit · Cancel · Save · Add · Done · Change · Change photo / Add photo · Add a new room · Skip — no room for now · Check in · Check · I watered it · Didn't water — next · Next plant · Take Photos · Skip photos · Skip · Close · Take photo · New random name · Delete everything · Send a test reminder (5s) · Delete all plants & rooms · Refresh · Share · Copy · Clear · Enable reminders · Maybe later.

**Add flow help:** "First pick the room these plants live in — its light and humidity set how often they're watered." · "Tap a species below to add it. Each plant gets a random name you can edit."

**Schedule sheet:** "Water this plant in" · "Today" / "N day(s)" · "Sets the next-watering date. Future check-ins keep adapting it."

**Check-in:** "Sprout learns each plant's true rhythm from these quick reads and adjusts its schedule." · "This plant's species isn't in the care database, so its schedule can't be adapted yet." · (result messages in §4.7/§4.8) · history line "Soil {dry/moist/wet} · Leaves {fine/droopy}".

**Room ⓘ help + footers:** see §4.6. Preset "Typical settings" footer; custom footer; Brightness footer.

**Notifications:** intro title/body (§4.10) · digest "Time to water your plants 🌱" / "N plant(s) need watering today." · banner "Reminders are off" / "Turn on notifications so Sprout can remind you to water." · bell a11y "Notifications are off — tap to enable" · test "Test reminder 🌱" / "If you can see this, watering reminders are working." · scheduled alert "Test reminder scheduled" / "A test notification will arrive in about 5 seconds…".

**Settings footers:** Reminders "Watering reminders arrive at this time on the day a plant is due — pick a window you're usually home." · Developer footer; delete dialog "This permanently removes every plant and room on this device. This can't be undone."

**Enum labels:** Soil Dry/Moist/Wet · Leaves Fine/Droopy · Light Low/Medium/High · Brightness Dark/Medium/Bright · Humidity Dry/Normal/Moist.

**System permission strings:** Location "Sprout uses your location to fetch the local forecast and adjust each plant's watering schedule for hot and cold spells." (legacy, weather retired) · Camera "Sprout uses the camera to take a photo of each plant you add."

---

## 8. Full SF Symbol Inventory

`leaf.fill` (plants / placeholder) · `house.fill` (rooms) · `house` (rooms empty) · `plus` (add toolbar) · `plus.circle.fill` (add species / add room / Add tile) · `drop.fill` (water tile, schedule, watered, water-now) · `checklist` (full check-in) · `checkmark.circle` (check-in CTA) · `checkmark.circle.fill` (capture/guided success) · `hand.raised.fill` (skip) · `eye.fill` (monitor) · `shuffle` (re-roll name) · `chevron.right` (wide tile / banner / room row) · `pencil` (schedule edit affordance) · `gearshape` (settings) · `bell.slash.fill` (reminders off) · `bell.badge.fill` (intro icon) · `bell.badge` (test reminder) · `camera.fill` (camera placeholder / photo prompt / stub) · `info.circle` (ⓘ tooltip) · `exclamationmark.triangle` (load failure) · `doc.text.magnifyingglass` (diagnostics) · `arrow.clockwise` (refresh) · `square.and.arrow.up` (share) · `doc.on.doc` (copy).

---

## 9. Consolidated Redesign Flags (opportunities & constraints)

**Consistency / polish**
1. Edit-form thumbnail uses a **default green tint** while everywhere else uses the **per-plant palette** — unify.
2. **Two parallel copy sets** for the nine watering outcomes (single check-in vs guided) — consider one voice.
3. Add-Room "Other…" path **omits the live inferred-Brightness readout** the editor shows — add it.

**Missing UX pieces worth designing**
4. **Delete has no confirmation** anywhere (plants and rooms) and plant-delete lives only in a list swipe — consider confirmations and a delete affordance on the edit screen.
5. **No room→plants drill-in** — tapping a room opens its editor, not a list of its plants. A room detail page is a natural addition.
6. **Species pages are thin** — the only per-species data is name + 3 interval numbers + moisture preference. Richer species content (care tips, light needs, toxicity, reference photos) would need new data sourced.
7. Species is **immutable after creation** — if the redesign wants "change species," it's new behaviour.

**Hard constraints to preserve**
8. **Single full-screen cover** for camera + guided watering (two covers black-screen on device).
9. The **Add → Photo-prompt → Camera** chain relies on "present next only after previous dismisses."
10. The schedule is always fenced by the species **min/max day band** — visualisations must respect it.
11. **One reminder per day** (digest), not per-plant.

---

*End of specification. This document reflects the app as built on `main` as of 2026-07-16. For anything ambiguous, the code is authoritative; file references are available on request.*
