import XCTest
@testable import Sprout

/// Unit tests for the pure schedule engine (T009). These assert the
/// effective-interval formula `clamp(round(base × weatherFactor × adj), min, max)`
/// across species, `adj`, and `weatherFactor` values, plus the next-due date
/// arithmetic with an injected clock. Everything is deterministic — no wall-clock.
final class ScheduleEngineTests: XCTestCase {

    /// A UTC calendar so day arithmetic is deterministic regardless of host TZ.
    private let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func engine() -> ScheduleEngine { ScheduleEngine(calendar: utc) }

    // A representative spread of the three moisture shapes.
    private let pothos = CareProfile(species: "Pothos", baseIntervalDays: 7,
                                     minIntervalDays: 5, maxIntervalDays: 12, moisture: .evenlyMoist)
    private let snake = CareProfile(species: "Snake Plant", baseIntervalDays: 14,
                                    minIntervalDays: 10, maxIntervalDays: 21, moisture: .driesOut)
    private let fern = CareProfile(species: "Boston Fern", baseIntervalDays: 4,
                                   minIntervalDays: 2, maxIntervalDays: 7, moisture: .staysMoist)

    // MARK: - Effective interval — base case

    func testEffectiveIntervalDefaultsToBaseWhenNeutral() {
        // adj = 1.0, weatherFactor = 1.0 ⇒ exactly the base interval.
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: 1.0), 7)
        XCTAssertEqual(engine().effectiveInterval(for: snake, adj: 1.0), 14)
        XCTAssertEqual(engine().effectiveInterval(for: fern, adj: 1.0), 4)
    }

    func testWeatherFactorParameterDefaultsToOne() {
        // Omitting weatherFactor is identical to passing 1.0.
        XCTAssertEqual(
            engine().effectiveInterval(for: pothos, adj: 1.0),
            engine().effectiveInterval(for: pothos, adj: 1.0, weatherFactor: 1.0)
        )
    }

    // MARK: - Inverse: adj for a desired interval (manual "adjust schedule")

    func testAdjForDesiredIntervalRoundTrips() {
        // A desired interval inside the species band round-trips through effectiveInterval.
        let adj = engine().adj(forDesiredInterval: 10, profile: pothos)
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: adj), 10)
    }

    func testAdjForDesiredIntervalClampsToSpeciesBand() {
        // Beyond the band, the derived adj is clamped so the interval stays in [min, max].
        let long = engine().adj(forDesiredInterval: 100, profile: pothos)
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: long), pothos.maxIntervalDays)

        let short = engine().adj(forDesiredInterval: 1, profile: pothos)
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: short), pothos.minIntervalDays)
    }

    // MARK: - Effective interval — adj scaling + rounding

    func testAdjScalesTheInterval() {
        // 14 × 1.5 = 21 (== max, still inside band).
        XCTAssertEqual(engine().effectiveInterval(for: snake, adj: 1.5), 21)
        // 14 × 0.75 = 10.5 → round → 11 (round-half-away-from-zero, inside band).
        XCTAssertEqual(engine().effectiveInterval(for: snake, adj: 0.75), 11)
    }

    func testRoundingToNearestWholeDay() {
        // 7 × 1.2 = 8.4 → 8.
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: 1.2), 8)
        // 7 × 1.07 = 7.49 → 7.
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: 1.07), 7)
        // 7 × 1.08 = 7.56 → 8.
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: 1.08), 8)
    }

    // MARK: - Effective interval — clamping to the species band

    func testIntervalClampedToSpeciesMax() {
        // 14 × 2.0 = 28, but Snake Plant max is 21.
        XCTAssertEqual(engine().effectiveInterval(for: snake, adj: 2.0), 21)
    }

    func testIntervalClampedToSpeciesMin() {
        // 14 × 0.5 = 7, but Snake Plant min is 10.
        XCTAssertEqual(engine().effectiveInterval(for: snake, adj: 0.5), 10)
        // Fern: 4 × 0.5 = 2 (== min).
        XCTAssertEqual(engine().effectiveInterval(for: fern, adj: 0.5), 2)
    }

    // MARK: - Effective interval — adj is clamped to [0.5, 2.0] before use

    func testAdjClampedBelowRange() {
        // adj 0.1 is treated as 0.5 ⇒ same as the min-adj result.
        XCTAssertEqual(
            engine().effectiveInterval(for: pothos, adj: 0.1),
            engine().effectiveInterval(for: pothos, adj: 0.5)
        )
    }

    func testAdjClampedAboveRange() {
        // adj 9.0 is treated as 2.0 ⇒ same as the max-adj result.
        XCTAssertEqual(
            engine().effectiveInterval(for: pothos, adj: 9.0),
            engine().effectiveInterval(for: pothos, adj: 2.0)
        )
    }

    // MARK: - Effective interval — weatherFactor

    func testHotWeatherShortensInterval() {
        // weatherFactor < 1.0 ⇒ water more often. 14 × 0.8 = 11.2 → 11.
        XCTAssertEqual(engine().effectiveInterval(for: snake, adj: 1.0, weatherFactor: 0.8), 11)
    }

    func testColdWeatherLengthensInterval() {
        // weatherFactor > 1.0 ⇒ water less often. 7 × 1.3 = 9.1 → 9.
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: 1.0, weatherFactor: 1.3), 9)
    }

    func testWeatherAndAdjCompose() {
        // 7 × 1.3 × 1.2 = 10.92 → 11, clamped to pothos max 12 ⇒ 11.
        XCTAssertEqual(engine().effectiveInterval(for: pothos, adj: 1.2, weatherFactor: 1.3), 11)
    }

    // MARK: - Next due — date arithmetic

    func testNextDueFromLastWatered() {
        let last = date(2026, 6, 1)
        let due = engine().nextDue(for: snake, adj: 1.0, lastWatered: last)
        XCTAssertEqual(due, date(2026, 6, 15)) // +14 days
    }

    func testNextDueUsesPlantLastWateredWhenPresent() {
        let last = date(2026, 6, 1)
        let plant = Plant(nickname: "Monty", species: pothos.species, adj: 1.0, lastWatered: last)
        let due = engine().nextDue(for: pothos, plant: plant, clock: FixedClock(date(2026, 6, 10)))
        XCTAssertEqual(due, date(2026, 6, 8)) // 1 June + 7 days, ignores clock
    }

    func testNextDueAnchorsToNowWhenNeverWatered() {
        let plant = Plant(nickname: "Newbie", species: pothos.species, adj: 1.0, lastWatered: nil)
        let now = date(2026, 6, 1)
        let due = engine().nextDue(for: pothos, plant: plant, clock: FixedClock(now))
        XCTAssertEqual(due, date(2026, 6, 8)) // now + 7 days
    }

    func testNextDueReflectsAdjAndWeather() {
        let last = date(2026, 6, 1)
        // 14 × 1.5 = 21 days.
        let due = engine().nextDue(for: snake, adj: 1.5, lastWatered: last)
        XCTAssertEqual(due, date(2026, 6, 22))
    }

    // MARK: - Purity sanity

    func testEngineIsDeterministic() {
        let a = engine().effectiveInterval(for: pothos, adj: 1.234, weatherFactor: 0.97)
        let b = engine().effectiveInterval(for: pothos, adj: 1.234, weatherFactor: 0.97)
        XCTAssertEqual(a, b)
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
}
