import SwiftUI
import XCTest
@testable import Sprout

final class RecommendationPresentationTests: XCTestCase {
    let calendar = Calendar.current
    let now = Date(timeIntervalSince1970: 1000000)

    // MARK: Water now cases

    func testWaterNowOnSchedule() {
        let recommendation = WateringRecommendation(
            action: .waterNow,
            reason: .onTargetDry,
            days: 4
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .droplet)
        XCTAssertEqual(presentation.iconScale, 1.0)
        XCTAssertEqual(presentation.tint, Color(hex: 0x2F6B4C))
        XCTAssertEqual(presentation.headline, "Water now, right on schedule.")
    }

    func testWaterNowDriedEarly() {
        let recommendation = WateringRecommendation(
            action: .waterNow,
            reason: .driedEarly,
            days: 3
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .droplet)
        XCTAssertEqual(presentation.iconScale, 1.0)
        XCTAssertEqual(presentation.tint, Color(hex: 0x2F6B4C))
        XCTAssertEqual(presentation.headline, "Water now, it dried out faster than expected.")
    }

    func testWaterNowDontDryOut() {
        let recommendation = WateringRecommendation(
            action: .waterNow,
            reason: .dontDryOut,
            days: 3
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .droplet)
        XCTAssertEqual(presentation.iconScale, 1.0)
        XCTAssertEqual(presentation.headline, "Water now, let's not let it dry out next time.")
    }

    func testWaterNowDroopyDry() {
        let recommendation = WateringRecommendation(
            action: .waterNow,
            reason: .droopyDry,
            days: 3
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .droplet)
        XCTAssertEqual(presentation.iconScale, 1.0)
        XCTAssertEqual(presentation.headline, "Water now, the leaves are drooping.")
    }

    // MARK: Water lightly cases

    func testWaterLightlyOnSchedule() {
        let recommendation = WateringRecommendation(
            action: .waterLightly,
            reason: .onTargetMoist,
            days: 5
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .droplet)
        XCTAssertEqual(presentation.iconScale, 0.8)
        XCTAssertEqual(presentation.tint, Color(hex: 0x5FB4A2))
        XCTAssertEqual(presentation.headline, "Water lightly, the soil's moist.")
    }

    func testWaterLightlyTouchEarly() {
        let recommendation = WateringRecommendation(
            action: .waterLightly,
            reason: .touchEarly,
            days: 5
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .droplet)
        XCTAssertEqual(presentation.iconScale, 0.8)
        XCTAssertEqual(presentation.tint, Color(hex: 0x5FB4A2))
        XCTAssertEqual(presentation.headline, "Water lightly, a touch early, but fine to top up.")
    }

    // MARK: Skip cases

    func testSkipStillWet() {
        let recommendation = WateringRecommendation(
            action: .skip,
            reason: .stillWet,
            days: 3
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .circleCheck)
        XCTAssertEqual(presentation.iconScale, 1.0)
        XCTAssertEqual(presentation.tint, Color(hex: 0xB4832F))
        XCTAssertEqual(presentation.headline, "Skip today. The soil's still wet. Back in about 3 days.")
    }

    func testSkipDroopyWet() {
        let recommendation = WateringRecommendation(
            action: .skip,
            reason: .droopyWet,
            days: 4
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .circleCheck)
        XCTAssertEqual(presentation.iconScale, 1.0)
        XCTAssertEqual(presentation.tint, Color(hex: 0xB4832F))
        XCTAssertEqual(presentation.headline, "All set. The soil's wet. Back in about 4 days.")
    }

    // MARK: Monitor cases

    func testMonitorDroopyMoist() {
        let recommendation = WateringRecommendation(
            action: .monitor,
            reason: .droopyMoist,
            days: 1
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.icon, .circleInfo)
        XCTAssertEqual(presentation.iconScale, 1.0)
        XCTAssertEqual(presentation.tint, Color(hex: 0x7C8173))
        XCTAssertEqual(presentation.headline, "Hold off. Droopy leaves but damp soil. Check again tomorrow.")
    }

    // MARK: All cases covered

    func testAllActionsCovered() {
        let actions: [WateringRecommendation.Action] = [.waterNow, .waterLightly, .skip, .monitor]
        for action in actions {
            let recommendation = WateringRecommendation(
                action: action,
                reason: .onTargetDry,
                days: 3
            )
            let presentation = RecommendationPresentation.present(
                recommendation,
                nextDue: nil,
                calendar: calendar,
                now: now
            )
            XCTAssertNotNil(presentation.headline)
            XCTAssertFalse(presentation.headline.isEmpty)
        }
    }

    func testAllReasonsProducedValidHeadline() {
        let reasons: [WateringRecommendation.Reason] = [
            .stillWet, .driedEarly, .onTargetDry, .dontDryOut,
            .onTargetMoist, .touchEarly, .droopyDry, .droopyWet, .droopyMoist,
            .crispyDry, .crispyMoist, .crispyWet
        ]

        for reason in reasons {
            let action: WateringRecommendation.Action
            switch reason {
            case .stillWet, .droopyWet:
                action = .skip
            case .driedEarly, .onTargetDry, .dontDryOut, .droopyDry, .crispyDry, .crispyMoist:
                action = .waterNow
            case .onTargetMoist, .touchEarly, .crispyWet:
                action = .waterLightly
            case .droopyMoist:
                action = .monitor
            }

            let recommendation = WateringRecommendation(
                action: action,
                reason: reason,
                days: 3
            )

            let presentation = RecommendationPresentation.present(
                recommendation,
                nextDue: nil,
                calendar: calendar,
                now: now
            )

            XCTAssertNotNil(presentation.headline)
            XCTAssertFalse(presentation.headline.isEmpty)
            XCTAssert(presentation.headline.hasSuffix("."), "Headline must end with period")
        }
    }

    // MARK: Color equivalences

    func testSkipTintMatchesSproutThemeDueTodayAmber() {
        let recommendation = WateringRecommendation(
            action: .skip,
            reason: .stillWet,
            days: 3
        )

        let presentation = RecommendationPresentation.present(
            recommendation,
            nextDue: nil,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(presentation.tint, SproutTheme.dueTodayAmber)
    }
}

// MARK: - Test-only Color constructor

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
