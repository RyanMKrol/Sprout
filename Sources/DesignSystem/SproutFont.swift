import SwiftUI

enum SproutFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let psName: String
        switch weight {
        case .semibold:
            psName = "BricolageGrotesque96ptExtraBold-SemiBold"
        case .bold, .heavy, .black:
            psName = "BricolageGrotesque96ptExtraBold-Bold"
        default:
            psName = "BricolageGrotesque96ptExtraBold-Bold"
        }
        return .custom(psName, size: size)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let psName: String
        switch weight {
        case .regular:
            psName = "HankenGrotesk-Regular"
        case .medium:
            psName = "HankenGrotesk-Medium"
        case .semibold:
            psName = "HankenGrotesk-SemiBold"
        case .bold:
            psName = "HankenGrotesk-Bold"
        default:
            psName = "HankenGrotesk-Regular"
        }
        return .custom(psName, size: size)
    }

    static func bodyItalic(_ size: CGFloat) -> Font {
        .custom("HankenGrotesk-Italic", size: size)
    }
}
