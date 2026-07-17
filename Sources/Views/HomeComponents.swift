import SwiftUI

enum HomeHeroState {
    case due(count: Int, plants: [Plant])
    case empty
    case allWatered(next: (name: String, days: Int)?)
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
                            PlantToken(
                                icon: plant.icon,
                                duo: PlantTokenPalette.duo(for: plant.id),
                                size: 36,
                                photo: plant.photoData.flatMap(UIImage.init)
                            )
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
