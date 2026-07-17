import SwiftUI

struct RhythmBand: View {
    let minDays: Int
    let maxDays: Int
    let baseDays: Int
    let effectiveDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WATERING RHYTHM")
                .font(SproutFont.body(11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(SproutTheme.taupe)
                .textCase(.uppercase)

            Text("Every \(effectiveDays) days")
                .font(SproutFont.display(26, weight: .bold))
                .foregroundStyle(SproutTheme.ink)

            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let basePosition = Self.position(of: baseDays, min: minDays, max: maxDays)
                let nowPosition = Self.position(of: effectiveDays, min: minDays, max: maxDays)
                let showCollapsedLabel = abs(basePosition - nowPosition) < 0.08

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        Text("MIN \(minDays)d")
                            .font(SproutFont.body(11, weight: .bold))
                            .foregroundStyle(SproutTheme.taupe)

                        Spacer()

                        Text("MAX \(maxDays)d")
                            .font(SproutFont.body(11, weight: .bold))
                            .foregroundStyle(SproutTheme.taupe)
                    }

                    ZStack(alignment: .top) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: 0xE3EBD6),
                                Color(hex: 0xB9D3A2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .cornerRadius(6)

                        if !showCollapsedLabel {
                            VStack(alignment: .center, spacing: 4) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(SproutTheme.ink.opacity(0.35))
                                    .frame(width: 2, height: 12)

                                Text("base \(baseDays)d")
                                    .font(SproutFont.body(11))
                                    .foregroundStyle(Color(hex: 0x9AA090))
                            }
                            .offset(x: basePosition * trackWidth - 1)
                        }

                        VStack(alignment: .center, spacing: 4) {
                            ZStack(alignment: .center) {
                                Circle()
                                    .fill(SproutTheme.brandGreen)
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )

                                ChromeIcon.droplet.image
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            .frame(width: 26, height: 26)

                            if !showCollapsedLabel {
                                Text("now")
                                    .font(SproutFont.body(11.5, weight: .bold))
                                    .foregroundStyle(SproutTheme.brandGreen)
                            }
                        }
                        .offset(x: nowPosition * trackWidth - 13)
                    }
                    .frame(height: 60)

                    if showCollapsedLabel {
                        HStack {
                            Text("now")
                                .font(SproutFont.body(11.5, weight: .bold))
                                .foregroundStyle(SproutTheme.brandGreen)
                            Spacer()
                        }
                        .offset(x: nowPosition * trackWidth - 13)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func position(of value: Int, min: Int, max: Int) -> Double {
        if max <= min {
            return 0.5
        }
        let rawPosition = Double(value - min) / Double(max - min)
        return Swift.max(0, Swift.min(1, rawPosition))
    }
}

#Preview {
    RhythmBand(minDays: 4, maxDays: 14, baseDays: 7, effectiveDays: 5)
        .padding(20)
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
