import SwiftUI

/// Maps an engine outcome to the redesign's icon + tint + "{Action} — {reason}." headline,
/// consumed by the check-in sheet and guided watering (§4, redesign-spec.md).
struct RecommendationPresentation: Equatable {
    let icon: ChromeIcon
    let iconScale: CGFloat
    let tint: Color
    let headline: String

    /// Present a watering recommendation in the redesign voice.
    /// - Parameters:
    ///   - outcome: The engine's recommendation (action + reason + days).
    ///   - nextDue: The recomputed next-watering date, used to format certain reasons.
    ///   - calendar: Calendar for date arithmetic and formatting.
    ///   - now: The current date, used as the reference for relative-date display.
    static func present(
        _ outcome: WateringRecommendation,
        nextDue: Date?,
        calendar: Calendar,
        now: Date
    ) -> RecommendationPresentation {
        switch outcome.action {
        case .waterNow:
            return waterNowPresentation(outcome.reason, nextDue: nextDue, calendar: calendar, now: now)

        case .waterLightly:
            return waterLightlyPresentation(outcome.reason, calendar: calendar)

        case .skip:
            return skipPresentation(outcome.reason, days: outcome.days, calendar: calendar, now: now)

        case .monitor:
            return monitorPresentation(outcome.reason, nextDue: nextDue, calendar: calendar, now: now)
        }
    }

    // MARK: - Action-specific presenters

    private static func waterNowPresentation(
        _ reason: WateringRecommendation.Reason,
        nextDue: Date?,
        calendar: Calendar,
        now: Date
    ) -> RecommendationPresentation {
        let tint = Color(hex: 0x2F6B4C)

        let headline: String
        switch reason {
        case .onTargetDry:
            headline = "Water now — right on schedule."
        case .driedEarly:
            headline = "Water now — it dried out faster than expected."
        case .dontDryOut:
            headline = "Water now — let's not let it dry out next time."
        case .droopyDry:
            headline = "Water now — the leaves are drooping."
        default:
            headline = "Water now — the soil's dry."
        }

        return RecommendationPresentation(
            icon: .droplet,
            iconScale: 1.0,
            tint: tint,
            headline: headline
        )
    }

    private static func waterLightlyPresentation(
        _ reason: WateringRecommendation.Reason,
        calendar: Calendar
    ) -> RecommendationPresentation {
        let tint = Color(hex: 0x5FB4A2)

        let headline: String
        switch reason {
        case .onTargetMoist:
            headline = "Water lightly — the soil's moist."
        case .touchEarly:
            headline = "Water lightly — a touch early, but fine to top up."
        default:
            headline = "Water lightly — the soil isn't fully dry yet."
        }

        return RecommendationPresentation(
            icon: .droplet,
            iconScale: 0.8,
            tint: tint,
            headline: headline
        )
    }

    private static func skipPresentation(
        _ reason: WateringRecommendation.Reason,
        days: Int,
        calendar: Calendar,
        now: Date
    ) -> RecommendationPresentation {
        let tint = Color(hex: 0xB4832F)

        let headline: String
        switch reason {
        case .stillWet:
            headline = "Skip today — the soil's still wet. Back in about \(days) days."
        case .droopyWet:
            headline = "All set — the soil's wet. Back in about \(days) days."
        default:
            headline = "Skip today — the soil's still wet. Back in about \(days) days."
        }

        return RecommendationPresentation(
            icon: .circleCheck,
            iconScale: 1.0,
            tint: tint,
            headline: headline
        )
    }

    private static func monitorPresentation(
        _ reason: WateringRecommendation.Reason,
        nextDue: Date?,
        calendar: Calendar,
        now: Date
    ) -> RecommendationPresentation {
        let tint = Color(hex: 0x7C8173)

        let headline: String
        switch reason {
        case .droopyMoist:
            headline = "Hold off — droopy leaves but damp soil. Check again tomorrow."
        default:
            headline = "Nothing to do — looking fine. Check again soon."
        }

        return RecommendationPresentation(
            icon: .circleInfo,
            iconScale: 1.0,
            tint: tint,
            headline: headline
        )
    }
}

// MARK: - Hex color extension

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
