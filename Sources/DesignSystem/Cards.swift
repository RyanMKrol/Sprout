import SwiftUI

// MARK: - SproutCard Modifier

struct SproutCardModifier: ViewModifier {
    let radius: CGFloat

    init(radius: CGFloat = 20) {
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        Color(red: 34.0 / 255, green: 39.0 / 255, blue: 31.0 / 255, opacity: 0.05),
                        lineWidth: 1
                    )
            )
            .cardShadow()
    }
}

extension View {
    func sproutCard(radius: CGFloat = 20) -> some View {
        modifier(SproutCardModifier(radius: radius))
    }
}

// MARK: - BentoStyle & BentoTile Modifier

enum BentoStyle {
    case sage
    case oat

    var fill: Color {
        switch self {
        case .sage:
            return SproutTheme.sageSurface
        case .oat:
            return SproutTheme.oatSurface
        }
    }

    var border: Color {
        switch self {
        case .sage:
            return SproutTheme.sageBorder
        case .oat:
            return SproutTheme.oatBorder
        }
    }

    var titleColor: Color {
        switch self {
        case .sage:
            return SproutTheme.sageTitle
        case .oat:
            return SproutTheme.oatTitle
        }
    }

    var subtitleColor: Color {
        switch self {
        case .sage:
            return SproutTheme.sageSubtitle
        case .oat:
            return SproutTheme.oatSubtitle
        }
    }
}

struct BentoTileModifier: ViewModifier {
    let style: BentoStyle

    func body(content: Content) -> some View {
        content
            .background(style.fill)
            .cornerRadius(SproutTheme.Radius.bento)
            .overlay(
                RoundedRectangle(cornerRadius: SproutTheme.Radius.bento)
                    .stroke(style.border, lineWidth: 1)
            )
            .padding(16)
            .bentoShadow()
    }
}

extension View {
    func bentoTile(_ style: BentoStyle) -> some View {
        modifier(BentoTileModifier(style: style))
    }
}

// MARK: - HeroCard

struct HeroCard<Content: View>: View {
    let content: Content
    let watermark: ChromeIcon
    let watermarkPosition: WatermarkPosition

    enum WatermarkPosition {
        case topTrailing
        case bottomTrailing
    }

    init(
        watermark: ChromeIcon,
        watermarkPosition: WatermarkPosition = .topTrailing,
        @ViewBuilder content: () -> Content
    ) {
        self.watermark = watermark
        self.watermarkPosition = watermarkPosition
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: watermarkAlignment) {
            SproutTheme.heroGradient
                .ignoresSafeArea()

            VStack(alignment: .leading) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(22)

            watermark.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .foregroundStyle(Color.white.opacity(0.08))
                .offset(watermarkOffset)
        }
        .cornerRadius(SproutTheme.Radius.hero)
        .heroShadow()
    }

    private var watermarkAlignment: Alignment {
        switch watermarkPosition {
        case .topTrailing:
            return .topTrailing
        case .bottomTrailing:
            return .bottomTrailing
        }
    }

    private var watermarkOffset: CGSize {
        switch watermarkPosition {
        case .topTrailing:
            return CGSize(width: 75, height: -75)
        case .bottomTrailing:
            return CGSize(width: 75, height: 75)
        }
    }
}

// MARK: - InfoBanner

struct InfoBanner: View {
    let icon: ChromeIcon
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color(hex: 0x2A6045))

            Text(text)
                .font(SproutFont.body(13))
                .foregroundStyle(Color(hex: 0x2A6045))

            Spacer()
        }
        .padding(16)
        .background(Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.10))
        .cornerRadius(16)
    }
}

// MARK: - CircularToolbarButton

struct CircularToolbarButton: View {
    let icon: ChromeIcon
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundStyle(tint)
        }
        .frame(width: 42, height: 42)
        .background(Color.white)
        .cornerRadius(21)
        .shadow(
            color: Color(red: 50.0 / 255, green: 55.0 / 255, blue: 40.0 / 255, opacity: 0.1),
            radius: 8, x: 0, y: 2
        )
    }
}

// MARK: - SproutFAB

struct SproutFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChromeIcon.plus.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.white)
        }
        .frame(width: 40, height: 40)
        .background(SproutTheme.brandGreen)
        .cornerRadius(20)
        .shadow(
            color: Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.3),
            radius: 12, x: 0, y: 4
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // White Card
        VStack(spacing: 8) {
            Text("White Card")
                .font(SproutFont.display(18, weight: .bold))
                .foregroundStyle(SproutTheme.ink)

            Text("This is a card with white fill, radius 20, and a subtle border.")
                .font(SproutFont.body(14))
                .foregroundStyle(SproutTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sproutCard()

        // Bento Tiles
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Sage Tile")
                    .font(SproutFont.display(18, weight: .bold))
                    .foregroundStyle(SproutTheme.sageTitle)

                Text("sage variant")
                    .font(SproutFont.body(13, weight: .semibold))
                    .foregroundStyle(SproutTheme.sageSubtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .bentoTile(.sage)

            VStack(spacing: 4) {
                Text("Oat Tile")
                    .font(SproutFont.display(18, weight: .bold))
                    .foregroundStyle(SproutTheme.oatTitle)

                Text("oat variant")
                    .font(SproutFont.body(13, weight: .semibold))
                    .foregroundStyle(SproutTheme.oatSubtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .bentoTile(.oat)
        }

        // Hero Card
        HeroCard(watermark: .droplet, watermarkPosition: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TO WATER TODAY 💧")
                    .font(SproutFont.body(11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.7))

                Text("2")
                    .font(SproutFont.display(60, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                Text("plants need your care")
                    .font(SproutFont.body(15))
                    .foregroundStyle(Color.white)
            }
        }
        .frame(height: 280)

        // Info Banner
        InfoBanner(
            icon: .arrowTrendUp,
            text: "Bright light dries soil faster, plants here are watered about 20% more often."
        )

        // Toolbar Buttons
        HStack(spacing: 12) {
            CircularToolbarButton(icon: .bell, tint: SproutTheme.brandGreen) {}
            CircularToolbarButton(icon: .gear, tint: SproutTheme.brandGreen) {}

            Spacer()

            SproutFAB {}
        }
        .padding(16)
        .background(SproutTheme.paper)

        Spacer()
    }
    .padding(16)
    .background(SproutTheme.paper)
}

// Helper for hex color in Preview
private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
