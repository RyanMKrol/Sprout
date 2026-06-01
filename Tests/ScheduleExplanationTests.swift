import XCTest
@testable import Sprout

/// Unit tests for the "why this schedule" explanation builder (T012). The builder
/// is pure — schedule inputs in, a structured `ScheduleExplanation` out — so each
/// case asserts the **decision** (direction + cause + day counts) and the derived
/// `sentence` / `pillSummary` strings exactly.
final class ScheduleExplanationTests: XCTestCase {
    private let builder = ScheduleExplanationBuilder()

    /// Peace Lily-shaped seed: base 6, band [4, 10], evenly moist.
    private let profile = CareProfile(
        species: "Peace Lily",
        baseIntervalDays: 6,
        minIntervalDays: 4,
        maxIntervalDays: 10,
        moisture: .evenlyMoist
    )

    private func checkIn(soil: SoilMoisture, leaves: LeafState) -> CheckIn {
        CheckIn(date: Date(timeIntervalSinceReferenceDate: 0), soil: soil, leaves: leaves, watered: true)
    }

    // MARK: direction

    func testUnchangedAtSeedCadenceWithNoHistory() {
        let e = builder.explanation(species: "Peace Lily", profile: profile, adj: 1.0, lastCheckIn: nil)
        XCTAssertEqual(e.effectiveDays, 6)
        XCTAssertEqual(e.baseDays, 6)
        XCTAssertEqual(e.direction, .unchanged)
        XCTAssertEqual(e.cause, .startingCadence)
        XCTAssertEqual(e.sentence, "Every 6 days — the starting cadence for Peace Lily.")
        XCTAssertEqual(e.pillSummary, "Every 6d")
    }

    func testSettledWhenAdjBackToNeutralButHistoryExists() {
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 1.0,
            lastCheckIn: checkIn(soil: .dry, leaves: .fine)
        )
        XCTAssertEqual(e.direction, .unchanged)
        XCTAssertEqual(e.cause, .settled)
        XCTAssertEqual(e.sentence, "Every 6 days — settled back to its usual cadence.")
    }

    func testShortenedDriedOut() {
        // adj 0.7 → round(6 × 0.7) = 4, within [4, 10].
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 0.7,
            lastCheckIn: checkIn(soil: .dry, leaves: .fine)
        )
        XCTAssertEqual(e.effectiveDays, 4)
        XCTAssertEqual(e.direction, .shortened)
        XCTAssertEqual(e.cause, .driedOut)
        XCTAssertEqual(e.sentence, "Every 4 days — shortened from 6 because it dried out faster than expected.")
        XCTAssertEqual(e.pillSummary, "Every 4d · shortened")
    }

    func testLengthenedStayedWet() {
        // adj 1.5 → round(6 × 1.5) = 9, within [4, 10].
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 1.5,
            lastCheckIn: checkIn(soil: .wet, leaves: .fine)
        )
        XCTAssertEqual(e.effectiveDays, 9)
        XCTAssertEqual(e.direction, .lengthened)
        XCTAssertEqual(e.cause, .stayedWet)
        XCTAssertEqual(e.sentence, "Every 9 days — stretched from 6 because the soil was still wet last time.")
        XCTAssertEqual(e.pillSummary, "Every 9d · stretched")
    }

    func testStillMoistCause() {
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 1.5,
            lastCheckIn: checkIn(soil: .moist, leaves: .fine)
        )
        XCTAssertEqual(e.cause, .stillMoist)
        XCTAssertEqual(e.sentence, "Every 9 days — stretched from 6 because the soil was still moist last time.")
    }

    func testDroopingShortens() {
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 0.8,
            lastCheckIn: checkIn(soil: .dry, leaves: .droopy)
        )
        XCTAssertEqual(e.cause, .drooping)
        XCTAssertEqual(e.direction, .shortened)
        XCTAssertEqual(e.sentence, "Every 5 days — shortened from 6 because its leaves were drooping.")
    }

    func testOverwateredLengthens() {
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 1.5,
            lastCheckIn: checkIn(soil: .wet, leaves: .droopy)
        )
        XCTAssertEqual(e.cause, .overwatered)
        XCTAssertEqual(e.sentence, "Every 9 days — stretched from 6 because it looked overwatered.")
    }

    // MARK: weather hook (T016 feeds the factor; neutral until then)

    func testWarmSpellShortensWhenNoCheckInDrivenAdj() {
        // adj neutral, weatherFactor < 1 → weather is the dominant cause.
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 1.0,
            lastCheckIn: nil,
            weatherFactor: 0.5
        )
        XCTAssertEqual(e.effectiveDays, 4) // round(6 × 0.5) = 3 → clamped to min 4
        XCTAssertEqual(e.direction, .shortened)
        XCTAssertEqual(e.cause, .warmSpell)
        XCTAssertEqual(e.sentence, "Every 4 days — shortened from 6 because of a warm spell.")
    }

    func testColdSpellLengthens() {
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 1.0,
            lastCheckIn: nil,
            weatherFactor: 1.5
        )
        XCTAssertEqual(e.effectiveDays, 9)
        XCTAssertEqual(e.direction, .lengthened)
        XCTAssertEqual(e.cause, .coldSpell)
        XCTAssertEqual(e.sentence, "Every 9 days — stretched from 6 because of a cold spell.")
    }

    func testCheckInDrivenAdjTakesPrecedenceOverWeather() {
        // Both a learned adj (from a check-in) and an off-neutral weather factor are
        // present; the check-in explains the schedule.
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 0.7,
            lastCheckIn: checkIn(soil: .dry, leaves: .fine),
            weatherFactor: 1.5
        )
        XCTAssertEqual(e.cause, .driedOut)
    }

    // MARK: clamp interaction

    func testEffectiveIntervalRespectsSpeciesMaxClamp() {
        // adj 2.0 → round(6 × 2.0) = 12, clamped to max 10.
        let e = builder.explanation(
            species: "Peace Lily",
            profile: profile,
            adj: 2.0,
            lastCheckIn: checkIn(soil: .wet, leaves: .fine)
        )
        XCTAssertEqual(e.effectiveDays, 10)
        XCTAssertEqual(e.direction, .lengthened)
    }

    func testSingularDayWording() {
        let oneDay = CareProfile(species: "Thirsty", baseIntervalDays: 1, minIntervalDays: 1, maxIntervalDays: 3, moisture: .staysMoist)
        let e = builder.explanation(species: "Thirsty", profile: oneDay, adj: 1.0, lastCheckIn: nil)
        XCTAssertEqual(e.sentence, "Every 1 day — the starting cadence for Thirsty.")
    }
}
