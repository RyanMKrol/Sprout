import SwiftUI
import UIKit

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

struct PlantTokenPalette {
    struct Duo {
        let light: Color
        let dark: Color
    }

    static let green = Duo(light: Color(hex: 0x79B98C), dark: Color(hex: 0x3F7E58))
    static let purple = Duo(light: Color(hex: 0xA98CC0), dark: Color(hex: 0x6E4E8C))
    static let blue = Duo(light: Color(hex: 0x8CB0D2), dark: Color(hex: 0x4E7CA6))
    static let gold = Duo(light: Color(hex: 0xDCC078), dark: Color(hex: 0xB08A34))
    static let teal = Duo(light: Color(hex: 0x5FB4A2), dark: Color(hex: 0x2E7C6B))
    static let pink = Duo(light: Color(hex: 0xD79BB0), dark: Color(hex: 0xB05F7E))
    static let success = Duo(light: Color(hex: 0x79B98C), dark: Color(hex: 0x2E7C4E))

    static let duos: [Duo] = [green, purple, blue, gold, teal, pink]

    static func duo(for id: UUID) -> Duo {
        let sum = id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return duos[sum % duos.count]
    }
}

struct PlantToken: View {
    let icon: PlantIcon
    let duo: PlantTokenPalette.Duo
    let size: CGFloat
    let photo: UIImage?

    init(icon: PlantIcon, duo: PlantTokenPalette.Duo, size: CGFloat, photo: UIImage? = nil) {
        self.icon = icon
        self.duo = duo
        self.size = size
        self.photo = photo
    }

    var body: some View {
        ZStack {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                RadialGradient(
                    gradient: Gradient(colors: [duo.light, duo.dark]),
                    center: UnitPoint(x: 0.3, y: 0.25),
                    startRadius: 0,
                    endRadius: size * 0.75
                )
                .clipShape(Circle())

                icon.image
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: duo.dark.opacity(0.28), radius: 5, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            PlantToken(icon: .flower, duo: PlantTokenPalette.green, size: 46)
            PlantToken(icon: .leaf, duo: PlantTokenPalette.purple, size: 46)
            PlantToken(icon: .plant, duo: PlantTokenPalette.blue, size: 46)
        }
        HStack(spacing: 16) {
            PlantToken(icon: .cactus, duo: PlantTokenPalette.gold, size: 46)
            PlantToken(icon: .treePalm, duo: PlantTokenPalette.teal, size: 46)
            PlantToken(icon: .grains, duo: PlantTokenPalette.pink, size: 46)
        }
    }
    .padding()
}
