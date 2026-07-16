# Sprout Redesign — Architecture Contract

Frozen names, signatures, and file locations for the redesign backlog. Every task builds
against THESE names — do not invent variants. Companion to `redesign-spec.md` (visual truth).
Existing app architecture (view models, repository, engines, DemoSeed) is unchanged unless a
task says otherwise.

## 1. File layout (new/changed)

```
Sources/DesignSystem/                  ← NEW module directory (single app target, namespace by folder)
  SproutTheme.swift                    ← colors, gradients, shadows, radii, spacing
  SproutFont.swift                     ← Font helpers over the bundled families
  SproutIcon.swift                     ← icon-name enums → Image accessors
  PlantToken.swift                     ← PlantToken view + PlantTokenPalette
  DueChip.swift                        ← DueChip view + DueStatus mapping
  Buttons.swift                        ← PrimaryButtonStyle, GhostButtonStyle, CreamInsetButtonStyle
  Cards.swift                          ← sproutCard/bentoTile/heroCard modifiers, SectionEyebrow, InfoBanner
  SegmentedPicker.swift                ← SproutSegmentedPicker
  SheetScaffold.swift                  ← SproutSheetHeader + sheet chrome helpers
  AlertCard.swift                      ← SproutAlert (confirm dialogs)
  RhythmBand.swift                     ← RhythmBand view (pure, testable position math)
Sources/Fonts/                         ← bundled TTFs + FONTS.md (PostScript names) + licenses
Sources/Assets.xcassets/RedesignIcons/ ← ph-* and fa-* template imagesets
```

Screens stay in their current files (`Sources/Views/*.swift`); oversized ones split as their
task directs (HomeView → extract tiles into `Sources/Views/HomeComponents.swift`).

## 2. Core types (signatures frozen)

```swift
// SproutTheme.swift
enum SproutTheme {
    // Color are static lets: paper, ink, brandGreen, heroGradient(LinearGradient),
    // logoGradient, launchGradient, textSecondary, textMuted, textHint, textTertiary,
    // taupe, cream, deepGreenOnCream, cardSurface, segmentedTrack, toggleOffTrack,
    // progressTrack, sheetScrim, destructive, swipeEdit, dueTodayAmber, warningTerracotta,
    // sun, brightnessChip, softGreenFill, sageSurface, sageBorder, sageTitle, sageSubtitle,
    // oatSurface, oatBorder, oatTitle, oatSubtitle, oatIcon
    // Radii: enum Radius { sheet=40, hero=28, bento=24, dialog=22, row=20, field=18,
    //        button=16, segmented=15, pill=11, chip=10 } (CGFloat statics)
    // Shadows: card/bento/hero/primaryButton/token/dialog as ViewModifier helpers
}

// SproutFont.swift
enum SproutFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font  // Bricolage
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font  // Hanken
    static func bodyItalic(_ size: CGFloat) -> Font                            // Hanken italic
}
// Uses the PostScript names from Sources/Fonts/FONTS.md. NEVER Font.system in redesigned UI
// (except .monospaced in Diagnostics).

// SproutIcon.swift
enum PlantIcon: String, CaseIterable, Codable {   // the 16 Phosphor glyphs
    case flower = "ph-flower"; case leaf = "ph-leaf"; case plant = "ph-plant"
    case pottedPlant = "ph-potted-plant"; case cactus = "ph-cactus"
    case flowerTulip = "ph-flower-tulip"; case flowerLotus = "ph-flower-lotus"
    case grains = "ph-grains"; case clover = "ph-clover"; case treePalm = "ph-tree-palm"
    case tree = "ph-tree"; case treeEvergreen = "ph-tree-evergreen"; case acorn = "ph-acorn"
    case cherries = "ph-cherries"; case carrot = "ph-carrot"; case pepper = "ph-pepper"
    var image: Image                                   // Image(rawValue).renderingMode(.template)
    static func `default`(forSpecies species: String) -> PlantIcon
}
enum ChromeIcon: String { /* fa-* names as needed */ case gear = "fa-gear" /* … */
    var image: Image }

// PlantToken.swift
struct PlantTokenPalette {                 // replaces PlantPalette for tokens
    struct Duo { let light: Color; let dark: Color }
    static let duos: [Duo]                 // green, purple, blue, gold, teal, pink (spec §1.2)
    static let success: Duo
    static func duo(for id: UUID) -> Duo   // deterministic, same hashing idea as old PlantPalette
}
struct PlantToken: View {
    init(icon: PlantIcon, duo: PlantTokenPalette.Duo, size: CGFloat, photo: UIImage? = nil)
    // photo != nil → photo clipped in Circle() (photo wins); else radial gradient + white glyph
    // glyph size ≈ 0.45 × size; token shadow per spec
}

// DueChip.swift
enum DueStatus { case overdue(days: Int), dueToday, due(inDays: Int), unscheduled }
struct DueChip: View { init(status: DueStatus) }   // colors/copy per spec §1.2/§2.2

// Buttons.swift — ButtonStyles: SproutPrimaryButtonStyle, SproutGhostButtonStyle,
// SproutCreamButtonStyle. Usage: .buttonStyle(SproutPrimaryButtonStyle())

// SegmentedPicker.swift
struct SproutSegmentedPicker<T: Hashable>: View {
    init(selection: Binding<T>, options: [(value: T, label: String)])
}

// AlertCard.swift
struct SproutAlert: View {
    init(icon: ChromeIcon, tint: Color, title: String, message: String,
         confirmLabel: String, confirmRole: ButtonRole?, onConfirm: @escaping () -> Void,
         onCancel: @escaping () -> Void)
}
// Presented via .overlay + scrim (full-screen), not SwiftUI's .alert (custom look).

// RhythmBand.swift
struct RhythmBand: View {
    init(minDays: Int, maxDays: Int, baseDays: Int, effectiveDays: Int)
    static func position(of value: Int, min: Int, max: Int) -> Double  // 0…1 clamped, pure+tested
}
```

## 3. Model change

`StoredPlant.iconName: String?` (SwiftData, optional → lightweight migration) surfaced as
`Plant.icon: PlantIcon` (decode rawValue, fallback `.default(forSpecies:)`). Repository
add/update paths carry it through. DemoSeed assigns varied icons to the 5 demo plants.

## 4. Conventions every redesign task follows

- **Colors/fonts/radii ONLY via SproutTheme/SproutFont** — no new inline `Color(red:…)` or
  `Font.system` in redesigned screens. (Old screens keep theirs until their task lands.)
- Icons ONLY via `PlantIcon`/`ChromeIcon` — no SF Symbols in redesigned UI.
- Latin species names: `SproutFont.bodyItalic`.
- Keep every existing `SPROUT_SCREEN` deep-link working; new screens add hooks:
  `roomdetail` (15), icon picker reachable via `edit` (08 → Change icon).
- Keep all existing view-model tests green; view models are restyled-around, not rewritten,
  unless the task says otherwise.
- Accessibility: every tappable redesigned element keeps/gains an `accessibilityIdentifier`
  (existing ids unchanged); Dynamic Type via `@ScaledMetric` on custom font sizes is NOT
  required this wave (fixed sizes acceptable, flagged in LIMITATIONS).
- Screenshot verification: `./build_run.sh Sprout-Claude -seedDemoData YES` (+
  `SPROUT_SCREEN=<hook>` env via `xcrun simctl spawn … launchctl setenv` when needed), then
  READ `screenshots/latest.png` and describe what you see.
