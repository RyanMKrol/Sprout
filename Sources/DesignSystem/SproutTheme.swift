import SwiftUI

enum SproutTheme {
    // MARK: Core

    static let paper = Color(hex: 0xF4F1E7)
    static let ink = Color(hex: 0x232821)
    static let brandGreen = Color(hex: 0x2F6B4C)
    static let cream = Color(hex: 0xEBE4CF)
    static let deepGreenOnCream = Color(hex: 0x1C4330)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x2F6B4C), Color(hex: 0x193E2C)],
        startPoint: .init(x: 0.07, y: 0),
        endPoint: .init(x: 0.93, y: 1)
    )

    static let logoGradient = LinearGradient(
        colors: [Color(hex: 0x3C7E58), Color(hex: 0x1E4632)],
        startPoint: .init(x: 0.07, y: 0),
        endPoint: .init(x: 0.93, y: 1)
    )

    static let launchGradient = LinearGradient(
        colors: [Color(hex: 0x2F6B4C), Color(hex: 0x173726)],
        startPoint: .init(x: 0.03, y: 0),
        endPoint: .init(x: 0.97, y: 1)
    )

    // MARK: Text ramp

    static let textSecondary = Color(hex: 0x7C8173)
    static let textMuted = Color(hex: 0x6E7A63)
    static let textHint = Color(hex: 0x8A9080)
    static let textTertiary = Color(hex: 0x9AA090)
    static let taupe = Color(hex: 0xA79E85)

    // MARK: Chrome

    static let sheetDim = Color(hex: 0xD8D3C2)
    static let sheetScrim = Color(red: 25.0 / 255, green: 40.0 / 255, blue: 30.0 / 255, opacity: 0.34)
    static let segmentedTrack = Color(hex: 0xE7E1D2)
    static let toggleOffTrack = Color(hex: 0xD6D0C0)
    static let progressTrack = Color(hex: 0xE1DBCB)
    static let cardSurface = Color.white

    // MARK: Semantic

    static let destructive = Color(hex: 0xC4553B)
    static let swipeEdit = Color(hex: 0x5E8CA8)
    static let dueTodayAmber = Color(hex: 0xB4832F)
    static let dueLater = Color(hex: 0x2F6B4C)
    static let warningTerracotta = Color(hex: 0xC4663F)
    static let sun = Color(hex: 0xD98B0A)
    static let brightnessChip = Color(hex: 0xC4832A)
    static let softGreenFill = Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.11)

    // MARK: Bento surfaces

    static let sageSurface = Color(hex: 0xDEE8D0)
    static let sageBorder = Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.16)
    static let sageTitle = Color(hex: 0x1F2A20)
    static let sageSubtitle = Color(hex: 0x586A4E)

    static let oatSurface = Color(hex: 0xEEE3CD)
    static let oatBorder = Color(red: 140.0 / 255, green: 108.0 / 255, blue: 52.0 / 255, opacity: 0.16)
    static let oatTitle = Color(hex: 0x2A2418)
    static let oatSubtitle = Color(hex: 0x7C6E4E)
    static let oatIcon = Color(hex: 0xB4832F)

    // MARK: Radius

    enum Radius {
        static let sheet: CGFloat = 40
        static let hero: CGFloat = 28
        static let bento: CGFloat = 24
        static let dialog: CGFloat = 22
        static let row: CGFloat = 20
        static let field: CGFloat = 18
        static let button: CGFloat = 16
        static let segmented: CGFloat = 15
        static let pill: CGFloat = 11
        static let chip: CGFloat = 10
    }

    // MARK: Shadows

    struct CardShadow: ViewModifier {
        func body(content: Content) -> some View {
            content
                .shadow(
                    color: Color(red: 45.0 / 255, green: 55.0 / 255, blue: 38.0 / 255, opacity: 0.05),
                    radius: 12, x: 0, y: 3
                )
        }
    }

    struct BentoShadow: ViewModifier {
        func body(content: Content) -> some View {
            content
                .shadow(
                    color: Color(red: 45.0 / 255, green: 55.0 / 255, blue: 38.0 / 255, opacity: 0.06),
                    radius: 14, x: 0, y: 4
                )
        }
    }

    struct HeroShadow: ViewModifier {
        func body(content: Content) -> some View {
            content
                .shadow(
                    color: Color(red: 25.0 / 255, green: 62.0 / 255, blue: 44.0 / 255, opacity: 0.34),
                    radius: 36, x: 0, y: 18
                )
        }
    }

    struct PrimaryButtonShadow: ViewModifier {
        func body(content: Content) -> some View {
            content
                .shadow(
                    color: Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.34),
                    radius: 26, x: 0, y: 12
                )
        }
    }

    struct DialogShadow: ViewModifier {
        func body(content: Content) -> some View {
            content
                .shadow(
                    color: Color.black.opacity(0.32),
                    radius: 54, x: 0, y: 24
                )
        }
    }
}

extension View {
    func cardShadow() -> some View { modifier(SproutTheme.CardShadow()) }
    func bentoShadow() -> some View { modifier(SproutTheme.BentoShadow()) }
    func heroShadow() -> some View { modifier(SproutTheme.HeroShadow()) }
    func primaryButtonShadow() -> some View { modifier(SproutTheme.PrimaryButtonShadow()) }
    func dialogShadow() -> some View { modifier(SproutTheme.DialogShadow()) }
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
