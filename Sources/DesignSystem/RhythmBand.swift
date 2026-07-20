import SwiftUI

/// A "time until next water" gauge for the plant detail screen. The track runs from
/// **"Water now"** on the left to a freshly-watered plant on the right; the droplet
/// marker sits at `daysUntilDue / interval` and slides left as the due date nears,
/// with a draining fill behind it. It deliberately hides the MIN/MAX calibration band
/// — the "Every N days, shortened from M because…" sentence tells that story instead.
struct RhythmBand: View {
    /// The current effective watering interval, shown as "Every N days".
    let effectiveDays: Int
    /// Days remaining until the next watering (0 when due today / overdue).
    let daysUntilDue: Int
    /// Past due — pins the marker at "Water now" and tints the gauge red.
    let isOverdue: Bool

    /// 1.0 = freshly watered (a full interval remains) → marker at the right;
    /// 0.0 = due now → marker at the left "Water now" end.
    private var fraction: Double {
        isOverdue ? 0 : Self.position(of: daysUntilDue, min: 0, max: Swift.max(effectiveDays, 1))
    }

    private var accent: Color {
        isOverdue ? Color(hex: 0xC4553B) : SproutTheme.brandGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WATERING RHYTHM")
                .font(SproutFont.body(11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(SproutTheme.taupe)
                .textCase(.uppercase)

            Text("Every \(effectiveDays) \(effectiveDays == 1 ? "day" : "days")")
                .font(SproutFont.display(26, weight: .bold))
                .foregroundStyle(SproutTheme.ink)

            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let markerRadius: CGFloat = 13
                // The marker centre travels within an inset span so it never clips the ends.
                let markerCenter = markerRadius + fraction * (trackWidth - 2 * markerRadius)

                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color(hex: 0xE7ECDF))
                            .frame(height: 10)

                        // Draining fill — the reserve of days left, from the left edge
                        // up to the marker.
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: 0xB9D3A2), accent]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: Swift.max(markerCenter, 10), height: 10)

                        // "Now" droplet marker.
                        ZStack {
                            Circle()
                                .fill(accent)
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))

                            ChromeIcon.droplet.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                                .foregroundStyle(Color.white)
                        }
                        .frame(width: 26, height: 26)
                        .offset(x: markerCenter - markerRadius)
                    }
                    .frame(height: 26)

                    Text("Water now")
                        .font(SproutFont.body(11, weight: .semibold))
                        .foregroundStyle(SproutTheme.taupe)
                }
            }
            .frame(height: 56)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Clamp `value` to a `[0, 1]` fraction of the `[min, max]` span.
    static func position(of value: Int, min: Int, max: Int) -> Double {
        if max <= min {
            return 0.5
        }
        let rawPosition = Double(value - min) / Double(max - min)
        return Swift.max(0, Swift.min(1, rawPosition))
    }
}

#Preview {
    VStack(spacing: 32) {
        RhythmBand(effectiveDays: 8, daysUntilDue: 8, isOverdue: false)
        RhythmBand(effectiveDays: 8, daysUntilDue: 3, isOverdue: false)
        RhythmBand(effectiveDays: 8, daysUntilDue: 0, isOverdue: true)
    }
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
