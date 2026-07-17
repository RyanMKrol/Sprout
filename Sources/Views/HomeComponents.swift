import SwiftUI

enum HomeHeroState {
    case due(count: Int, plants: [Plant])
    case empty
    case allWatered(next: (name: String, days: Int)?)
}

/// A single plant's circular token, sized to `size` — used by the hero card's avatar
/// stack and the My Plants bento tile's token stack.
///
/// Delegates to `PlantToken` for the photo case (its `Image(uiImage:)` branch is
/// already `.resizable()` and renders correctly), but draws its own gradient + glyph
/// for the icon fallback: `PlantToken`'s icon there isn't `.resizable()`, so on a real
/// bundled asset (not an SF Symbol) it renders at the asset's native size and spills
/// across the surrounding UI instead of sitting inside the token.
struct HomePlantAvatar: View {
    let plant: Plant
    let size: CGFloat

    var body: some View {
        Group {
            if let photo = plant.photoData.flatMap(UIImage.init) {
                PlantToken(icon: plant.icon, duo: PlantTokenPalette.duo(for: plant.id), size: size, photo: photo)
            } else {
                let duo = PlantTokenPalette.duo(for: plant.id)
                ZStack {
                    RadialGradient(
                        gradient: Gradient(colors: [duo.light, duo.dark]),
                        center: UnitPoint(x: 0.3, y: 0.25),
                        startRadius: 0,
                        endRadius: size * 0.75
                    )
                    plant.icon.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size * 0.45, height: size * 0.45)
                        .foregroundStyle(Color.white)
                }
                .shadow(color: duo.dark.opacity(0.28), radius: 5, y: 2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct HomeHeroCard: View {
    let state: HomeHeroState
    let onPrimaryTap: () -> Void

    var body: some View {
        switch state {
        case .due(let count, let plants):
            dueCard(count: count, plants: plants)
        case .empty:
            emptyCard
        case .allWatered(let next):
            allWateredCard(next: next)
        }
    }

    private func dueCard(count: Int, plants: [Plant]) -> some View {
        HeroCard(watermark: .droplet, watermarkPosition: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                Text("TO WATER TODAY 💧")
                    .font(SproutFont.body(11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.7))

                Text("\(count)")
                    .font(SproutFont.display(60, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                Text(count == 1 ? "plant needs\nyour care" : "plants need\nyour care")
                    .font(SproutFont.body(15))
                    .foregroundStyle(Color.white)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: -12) {
                        ForEach(Array(plants.prefix(4)), id: \.id) { plant in
                            HomePlantAvatar(plant: plant, size: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: 0x285A40), lineWidth: 2.5)
                                )
                        }
                        Spacer()
                    }
                    .frame(height: 36)

                    Text(plantNamesLine(plants: Array(plants.prefix(4))))
                        .font(SproutFont.bodyItalic(13.5))
                        .foregroundStyle(Color.white.opacity(0.8))
                }

                Button(action: onPrimaryTap) {
                    HStack(spacing: 8) {
                        Text(buttonLabel(for: count))
                        ChromeIcon.arrowRight.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                    }
                }
                .buttonStyle(SproutCreamButtonStyle())
            }
        }
    }

    private var emptyCard: some View {
        HeroCard(watermark: .seedling, watermarkPosition: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your garden's\nempty — for now.")
                    .font(SproutFont.display(24, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("Add the plants you own and Sprout keeps their watering on track.")
                    .font(SproutFont.body(15))
                    .foregroundStyle(Color.white.opacity(0.82))

                Button(action: onPrimaryTap) {
                    HStack(spacing: 8) {
                        ChromeIcon.plus.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                        Text("Add your first plant")
                    }
                }
                .buttonStyle(SproutCreamButtonStyle())
            }
        }
    }

    private func allWateredCard(next: (name: String, days: Int)?) -> some View {
        HeroCard(watermark: .circleCheck, watermarkPosition: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                Text("ALL DONE FOR TODAY 🌿")
                    .font(SproutFont.body(11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.7))

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(PlantTokenPalette.success.light)

                        ChromeIcon.check.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 26, height: 26)
                            .foregroundStyle(Color.white)
                    }
                    .frame(width: 60, height: 60)

                    Spacer()
                }

                Text("Nothing needs water.")
                    .font(SproutFont.display(24, weight: .bold))
                    .foregroundStyle(Color.white)

                if let next {
                    Text("Next up: \(next.name) in \(next.days == 1 ? "1 day" : "\(next.days) days").")
                        .font(SproutFont.bodyItalic(13.5))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
        }
    }

    private func plantNamesLine(plants: [Plant]) -> String {
        switch plants.count {
        case 1:
            return plants[0].nickname
        case 2:
            return "\(plants[0].nickname) & \(plants[1].nickname)"
        case 3:
            return "\(plants[0].nickname), \(plants[1].nickname) & \(plants[2].nickname)"
        case 4:
            return "\(plants[0].nickname), \(plants[1].nickname) & 2 more"
        default:
            return plants[0].nickname
        }
    }

    private func buttonLabel(for count: Int) -> String {
        switch count {
        case 1:
            return "Water it"
        case 2:
            return "Water these two"
        case 3:
            return "Water these three"
        default:
            return "Water all \(count)"
        }
    }
}

/// The top-bar logo lockup: gradient icon tile + wordmark (redesign spec §3, 02/03).
struct HomeLogoLockup: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(SproutTheme.logoGradient)
                ChromeIcon.seedling.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Color.white)
            }
            .frame(width: 34, height: 34)

            Text("Sprout")
                .font(SproutFont.display(22, weight: .bold))
                .foregroundStyle(SproutTheme.ink)
        }
    }
}

/// A restyled "reminders are off" row (redesign spec §3, 02/03): white card, terracotta
/// border/icon, same tap behaviour as before (enable / open Settings).
struct HomeRemindersOffBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ChromeIcon.bellSlash.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(SproutTheme.warningTerracotta)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminders are off")
                        .font(SproutFont.body(15, weight: .semibold))
                        .foregroundStyle(SproutTheme.ink)
                    Text("Turn them on so Sprout can nudge you.")
                        .font(SproutFont.body(12.5))
                        .foregroundStyle(SproutTheme.textHint)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                ChromeIcon.chevronRight.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 11, height: 11)
                    .foregroundStyle(SproutTheme.textTertiary)
            }
            .padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: SproutTheme.Radius.field, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SproutTheme.Radius.field, style: .continuous)
                    .stroke(SproutTheme.warningTerracotta.opacity(0.32), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reminders are off")
        .accessibilityHint("Turn them on so Sprout can nudge you.")
    }
}

/// A 40×40 white, rounded icon bubble used as a bento tile's leading glyph when it
/// has no token stack to show (e.g. Rooms).
struct HomeBentoIconBubble: View {
    let icon: ChromeIcon
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
            icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(tint)
        }
        .frame(width: 40, height: 40)
    }
}

/// The My Plants bento tile's leading glyph: an overlapping stack of up to 3 plant
/// tokens (or the bubble fallback when there are none yet).
struct HomePlantStack: View {
    let plants: [Plant]

    var body: some View {
        if plants.isEmpty {
            HomeBentoIconBubble(icon: .seedling, tint: SproutTheme.brandGreen)
        } else {
            HStack(spacing: -12) {
                ForEach(Array(plants.prefix(3)), id: \.id) { plant in
                    HomePlantAvatar(plant: plant, size: 38)
                        .overlay(Circle().stroke(SproutTheme.sageSurface, lineWidth: 2.5))
                }
            }
        }
    }
}

/// A sage/oat bento tile: leading glyph (icon bubble or token stack), title, subtitle.
struct HomeBentoTile<Leading: View>: View {
    enum Surface { case sage, oat }

    let surface: Surface
    let title: String
    let subtitle: String
    @ViewBuilder let leading: () -> Leading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                leading()
                Text(title)
                    .font(SproutFont.display(18, weight: .bold))
                    .foregroundStyle(titleColor)
                Text(subtitle)
                    .font(SproutFont.body(13, weight: .semibold))
                    .foregroundStyle(subtitleColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(surfaceColor, in: RoundedRectangle(cornerRadius: SproutTheme.Radius.bento, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SproutTheme.Radius.bento, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .bentoShadow()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private var surfaceColor: Color { surface == .sage ? SproutTheme.sageSurface : SproutTheme.oatSurface }
    private var borderColor: Color { surface == .sage ? SproutTheme.sageBorder : SproutTheme.oatBorder }
    private var titleColor: Color { surface == .sage ? SproutTheme.sageTitle : SproutTheme.oatTitle }
    private var subtitleColor: Color { surface == .sage ? SproutTheme.sageSubtitle : SproutTheme.oatSubtitle }
}

extension HomeHeroCard {
    static func greeting(for state: HomeHeroState, hour: Int) -> (eyebrow: String, headline: String) {
        let eyebrow: String
        let headline: String

        switch state {
        case .empty:
            eyebrow = "WELCOME 🌱"
            headline = "Let's grow\nsomething."

        case .due(let count, _):
            if hour >= 5 && hour < 12 {
                eyebrow = "GOOD MORNING ☀️"
            } else if hour >= 12 && hour < 18 {
                eyebrow = "GOOD AFTERNOON 🌤"
            } else {
                eyebrow = "GOOD EVENING 🌙"
            }

            let countWord = Self.spellOutCount(count)
            if count == 1 {
                headline = "One plant is\nready for a drink."
            } else {
                headline = "\(countWord) plants are\nready for a drink."
            }

        case .allWatered:
            if hour >= 5 && hour < 12 {
                eyebrow = "GOOD MORNING ☀️"
            } else if hour >= 12 && hour < 18 {
                eyebrow = "GOOD AFTERNOON 🌤"
            } else {
                eyebrow = "GOOD EVENING 🌙"
            }
            headline = "Everything's\nwatered."
        }

        return (eyebrow, headline)
    }

    private static func spellOutCount(_ count: Int) -> String {
        switch count {
        case 1: return "One"
        case 2: return "Two"
        case 3: return "Three"
        case 4: return "Four"
        case 5: return "Five"
        case 6: return "Six"
        case 7: return "Seven"
        case 8: return "Eight"
        case 9: return "Nine"
        default: return "\(count)"
        }
    }
}

#Preview("Due — 2 plants") {
    VStack(spacing: 20) {
        HomeHeroCard(
            state: .due(
                count: 2,
                plants: [
                    Plant(
                        id: UUID(),
                        nickname: "Basil",
                        species: "Ocimum basilicum",
                        icon: .leaf
                    ),
                    Plant(
                        id: UUID(),
                        nickname: "Willow",
                        species: "Salix alba",
                        icon: .plant
                    )
                ]
            ),
            onPrimaryTap: {}
        )
        .frame(height: 380)

        Spacer()
    }
    .padding(16)
    .background(SproutTheme.paper)
}

#Preview("Due — 5 plants") {
    VStack(spacing: 20) {
        HomeHeroCard(
            state: .due(
                count: 5,
                plants: [
                    Plant(
                        id: UUID(),
                        nickname: "Basil",
                        species: "Ocimum basilicum",
                        icon: .leaf
                    ),
                    Plant(
                        id: UUID(),
                        nickname: "Willow",
                        species: "Salix alba",
                        icon: .plant
                    ),
                    Plant(
                        id: UUID(),
                        nickname: "Fern",
                        species: "Nephrolepis exaltata",
                        icon: .flower
                    ),
                    Plant(
                        id: UUID(),
                        nickname: "Cactus",
                        species: "Opuntia ficus",
                        icon: .cactus
                    )
                ]
            ),
            onPrimaryTap: {}
        )
        .frame(height: 380)

        Spacer()
    }
    .padding(16)
    .background(SproutTheme.paper)
}

#Preview("Empty") {
    VStack(spacing: 20) {
        HomeHeroCard(
            state: .empty,
            onPrimaryTap: {}
        )
        .frame(height: 380)

        Spacer()
    }
    .padding(16)
    .background(SproutTheme.paper)
}

#Preview("All Watered") {
    VStack(spacing: 20) {
        HomeHeroCard(
            state: .allWatered(next: (name: "Basil", days: 2)),
            onPrimaryTap: {}
        )
        .frame(height: 380)

        Spacer()
    }
    .padding(16)
    .background(SproutTheme.paper)
}

#Preview("All Watered — no next") {
    VStack(spacing: 20) {
        HomeHeroCard(
            state: .allWatered(next: nil),
            onPrimaryTap: {}
        )
        .frame(height: 380)

        Spacer()
    }
    .padding(16)
    .background(SproutTheme.paper)
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
