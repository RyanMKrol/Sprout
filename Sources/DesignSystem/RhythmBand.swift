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

                    // Markers anchor to the track's LEADING edge (`.topLeading`): an
                    // element at fractional position `p` is offset by `p * trackWidth`
                    // minus half its own width, putting its centre exactly on `p`. Each
                    // label is an overlay centred on its marker, so the label's width
                    // never shifts the marker's position.
                    ZStack(alignment: .topLeading) {
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

                        // Base (seed cadence) tick — hidden when it sits under the "now"
                        // marker so their labels don't collide.
                        if !showCollapsedLabel {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(SproutTheme.ink.opacity(0.35))
                                .frame(width: 2, height: 12)
                                .overlay(alignment: .top) {
                                    Text("base \(baseDays)d")
                                        .font(SproutFont.body(11))
                                        .foregroundStyle(Color(hex: 0x9AA090))
                                        .fixedSize()
                                        .offset(y: 16)
                                }
                                .offset(x: basePosition * trackWidth - 1)
                        }

                        // "Now" (effective cadence) droplet marker, with its label
                        // centred beneath it.
                        ZStack {
                            Circle()
                                .fill(SproutTheme.brandGreen)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )

                            ChromeIcon.droplet.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                                .foregroundStyle(Color.white)
                        }
                        .frame(width: 26, height: 26)
                        .overlay(alignment: .top) {
                            Text("now")
                                .font(SproutFont.body(11.5, weight: .bold))
                                .foregroundStyle(SproutTheme.brandGreen)
                                .fixedSize()
                                .offset(y: 30)
                        }
                        .offset(x: nowPosition * trackWidth - 13)
                    }
                    .frame(height: 60)
                }
            }
            // A GeometryReader is greedy and reports no intrinsic height, so without
            // an explicit frame it collapses in a VStack and its below-track markers
            // ("base", "now") overflow onto the content beneath. Reserve the height its
            // content actually needs (MIN/MAX row + 60pt track band + spacing).
            .frame(height: 90)
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
