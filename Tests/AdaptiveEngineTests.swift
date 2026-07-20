import XCTest
@testable import Sprout

/// Unit tests for the pure adaptive update (T010). A `(species, adj, checkIn,
/// timing) → (newAdj, recommendation, didWater)` table asserts **every** row of
/// the decision table in `docs/designs/adaptive-watering.md`, plus the
/// `[0.5, 2.0]` `adj` clamp and the schedule recompute (water vs. recheck).
/// Everything is deterministic — timing is derived from an explicit `nextDue`,
/// never the wall clock.
final class AdaptiveEngineTests: XCTestCase {

    /// A UTC calendar so day arithmetic is deterministic regardless of host TZ.
    private let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func engine() -> AdaptiveEngine { AdaptiveEngine(schedule: ScheduleEngine(calendar: utc)) }

    // The three moisture shapes (interval 7 keeps the ±20% band = 1.4 days simple).
    private let pothos = CareProfile(species: "Pothos", baseIntervalDays: 7,
                                     minIntervalDays: 5, maxIntervalDays: 12, moisture: .evenlyMoist)
    private let snake = CareProfile(species: "Snake Plant", baseIntervalDays: 14,
                                    minIntervalDays: 10, maxIntervalDays: 21, moisture: .driesOut)
    private let fern = CareProfile(species: "Boston Fern", baseIntervalDays: 7,
                                   minIntervalDays: 3, maxIntervalDays: 12, moisture: .staysMoist)

    /// A stable anchor for the plant's `nextDue`; check-ins are placed relative to it.
    private let due = Date(timeIntervalSinceReferenceDate: 700_000_000)

    private func date(daysFromDue days: Int) -> Date {
        utc.date(byAdding: .day, value: days, to: due)!
    }

    /// A plant due at `due`, last watered one interval earlier, with the given `adj`.
    private func plant(adj: Double = 1.0, interval: Int = 7) -> Plant {
        Plant(nickname: "P", species: "Pothos", adj: adj,
              lastWatered: utc.date(byAdding: .day, value: -interval, to: due)!,
              nextDue: due)
    }

    private func checkIn(
        _ soil: SoilMoisture, _ leaves: LeafState, watered: Bool, daysFromDue days: Int
    ) -> CheckIn {
        CheckIn(date: date(daysFromDue: days), soil: soil, leaves: leaves, watered: watered)
    }

    // MARK: - Decision table — leaves fine

    func testWetSkipsAndLengthens() {
        // Row 1: Wet | any | any ⇒ ×1.15, skip (don't water).
        let r = engine().update(profile: snake, plant: plant(adj: 1.0),
                                checkIn: checkIn(.wet, .fine, watered: false, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .stillWet)
        XCTAssertEqual(r.recommendation.action, .skip)
        XCTAssertEqual(r.newAdj, 1.15, accuracy: 1e-9)
        XCTAssertFalse(r.didWater)
    }

    func testDryEarlyShortens() {
        // Row 2: Dry | fine | early ⇒ ×0.85, water now.
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: checkIn(.dry, .fine, watered: true, daysFromDue: -3))
        XCTAssertEqual(r.recommendation.reason, .driedEarly)
        XCTAssertEqual(r.recommendation.action, .waterNow)
        XCTAssertEqual(r.newAdj, 0.85, accuracy: 1e-9)
        XCTAssertTrue(r.didWater)
    }

    func testDryOnTimeHoldsForDriesOut() {
        // Row 3: Dry | fine | on-time, driesOut ⇒ ×1.0 (hold), water now.
        let r = engine().update(profile: snake, plant: plant(adj: 1.0, interval: 14),
                                checkIn: checkIn(.dry, .fine, watered: true, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .onTargetDry)
        XCTAssertEqual(r.recommendation.action, .waterNow)
        XCTAssertEqual(r.newAdj, 1.0, accuracy: 1e-9)
        XCTAssertTrue(r.didWater)
    }

    func testDryOnTimeHoldsForEvenlyMoist() {
        // Row 3: Dry | fine | on-time, evenlyMoist ⇒ ×1.0 (hold), water now.
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: checkIn(.dry, .fine, watered: true, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .onTargetDry)
        XCTAssertEqual(r.newAdj, 1.0, accuracy: 1e-9)
    }

    func testDryLateStillHoldsForEvenlyMoist() {
        // Dry | fine | late, evenlyMoist ⇒ still on-target hold (no early/staysMoist rule).
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: checkIn(.dry, .fine, watered: true, daysFromDue: 3))
        XCTAssertEqual(r.recommendation.reason, .onTargetDry)
        XCTAssertEqual(r.newAdj, 1.0, accuracy: 1e-9)
    }

    func testDryOnTimeShortensForStaysMoist() {
        // Row 4: Dry | fine | on-time, staysMoist ⇒ ×0.90, water now.
        let r = engine().update(profile: fern, plant: plant(adj: 1.0),
                                checkIn: checkIn(.dry, .fine, watered: true, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .dontDryOut)
        XCTAssertEqual(r.recommendation.action, .waterNow)
        XCTAssertEqual(r.newAdj, 0.90, accuracy: 1e-9)
    }

    func testDryLateShortensForStaysMoist() {
        // Row 4: Dry | fine | late, staysMoist ⇒ ×0.90, water now.
        let r = engine().update(profile: fern, plant: plant(adj: 1.0),
                                checkIn: checkIn(.dry, .fine, watered: true, daysFromDue: 3))
        XCTAssertEqual(r.recommendation.reason, .dontDryOut)
        XCTAssertEqual(r.newAdj, 0.90, accuracy: 1e-9)
    }

    func testDryEarlyBeatsStaysMoistShorten() {
        // Early takes precedence over the species note for dry+fine.
        let r = engine().update(profile: fern, plant: plant(adj: 1.0),
                                checkIn: checkIn(.dry, .fine, watered: true, daysFromDue: -3))
        XCTAssertEqual(r.recommendation.reason, .driedEarly)
        XCTAssertEqual(r.newAdj, 0.85, accuracy: 1e-9)
    }

    func testMoistOnTimeHolds() {
        // Row 5: Moist | fine | on-time ⇒ ×1.0 (hold), water lightly.
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: checkIn(.moist, .fine, watered: true, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .onTargetMoist)
        XCTAssertEqual(r.recommendation.action, .waterLightly)
        XCTAssertEqual(r.newAdj, 1.0, accuracy: 1e-9)
        XCTAssertTrue(r.didWater)
    }

    func testMoistEarlyLengthens() {
        // Row 6: Moist | fine | early ⇒ ×1.05, water lightly (top up).
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: checkIn(.moist, .fine, watered: true, daysFromDue: -3))
        XCTAssertEqual(r.recommendation.reason, .touchEarly)
        XCTAssertEqual(r.recommendation.action, .waterLightly)
        XCTAssertEqual(r.newAdj, 1.05, accuracy: 1e-9)
    }

    // MARK: - Decision table — droopy overrides

    func testDroopyDryShortens() {
        // Row 7: droopy + Dry ⇒ ×0.80, water now (regardless of timing/species).
        let r = engine().update(profile: snake, plant: plant(adj: 1.0, interval: 14),
                                checkIn: checkIn(.dry, .droopy, watered: true, daysFromDue: -3))
        XCTAssertEqual(r.recommendation.reason, .droopyDry)
        XCTAssertEqual(r.recommendation.action, .waterNow)
        XCTAssertEqual(r.newAdj, 0.80, accuracy: 1e-9)
        XCTAssertTrue(r.didWater)
    }

    func testDroopyWetLengthensAndIndicatesOverwater() {
        // Row 8: droopy + Wet ⇒ ×1.20, skip (may be overwatered, don't water).
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: checkIn(.wet, .droopy, watered: false, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .droopyWet)
        XCTAssertEqual(r.recommendation.action, .skip)
        XCTAssertEqual(r.newAdj, 1.20, accuracy: 1e-9)
        XCTAssertFalse(r.didWater)
        // Skip horizon is the recheck window.
        XCTAssertEqual(r.recommendation.days, AdaptiveEngine.recheckDays)
    }

    func testDroopyMoistMonitors() {
        // Row 9: droopy + Moist ⇒ ×0.95, monitor (keep an eye on it).
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: checkIn(.moist, .droopy, watered: false, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .droopyMoist)
        XCTAssertEqual(r.recommendation.action, .monitor)
        XCTAssertEqual(r.newAdj, 0.95, accuracy: 1e-9)
        XCTAssertFalse(r.didWater)
    }

    func testDroopyOverridesWetSkipRow() {
        // droopy+wet uses row 8 (×1.20), not the fine-leaf wet row 1 (×1.15).
        let r = engine().update(profile: snake, plant: plant(adj: 1.0),
                                checkIn: checkIn(.wet, .droopy, watered: false, daysFromDue: 0))
        XCTAssertEqual(r.newAdj, 1.20, accuracy: 1e-9)
    }

    // MARK: - Decision table — crispy overrides (dehydration)

    func testCrispyDryShortensHard() {
        // Crispy + Dry ⇒ ×0.75, water now — shortens harder than droopyDry's 0.80.
        let base = plant(adj: 1.0, interval: 14)
        let r = engine().update(profile: snake, plant: base,
                                checkIn: checkIn(.dry, .crispy, watered: true, daysFromDue: -3))
        XCTAssertEqual(r.recommendation.reason, .crispyDry)
        XCTAssertEqual(r.recommendation.action, .waterNow)
        XCTAssertEqual(r.newAdj, 0.75, accuracy: 1e-9)
        XCTAssertLessThan(r.newAdj, base.adj)
        XCTAssertTrue(r.didWater)
    }

    func testCrispyMoistWatersAndShortens() {
        // Crispy + Moist ⇒ ×0.85, water now — dehydrated despite damp soil.
        let base = plant(adj: 1.0)
        let r = engine().update(profile: pothos, plant: base,
                                checkIn: checkIn(.moist, .crispy, watered: true, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .crispyMoist)
        XCTAssertEqual(r.recommendation.action, .waterNow)
        XCTAssertEqual(r.newAdj, 0.85, accuracy: 1e-9)
        XCTAssertLessThan(r.newAdj, base.adj)
        XCTAssertTrue(r.didWater)
    }

    func testCrispyWetWatersLightlyAndShortensMildly() {
        // Crispy + Wet ⇒ ×0.95, water lightly — wet soil tempers urgency but the
        // plant still reads dehydrated, so water lightly and shorten mildly.
        let base = plant(adj: 1.0)
        let r = engine().update(profile: pothos, plant: base,
                                checkIn: checkIn(.wet, .crispy, watered: false, daysFromDue: 0))
        XCTAssertEqual(r.recommendation.reason, .crispyWet)
        XCTAssertEqual(r.recommendation.action, .waterLightly)
        XCTAssertEqual(r.newAdj, 0.95, accuracy: 1e-9)
        XCTAssertLessThan(r.newAdj, base.adj)
    }

    func testCrispyOverridesFineWetRow() {
        // crispy+wet uses the crispy row (×0.95), not the fine-leaf wet row (×1.15).
        let r = engine().update(profile: snake, plant: plant(adj: 1.0),
                                checkIn: checkIn(.wet, .crispy, watered: false, daysFromDue: 0))
        XCTAssertEqual(r.newAdj, 0.95, accuracy: 1e-9)
    }

    // MARK: - adj clamp [0.5, 2.0]

    func testAdjClampLowerBound() {
        // 0.55 × 0.80 = 0.44 → clamped up to 0.5.
        let r = engine().update(profile: snake, plant: plant(adj: 0.55),
                                checkIn: checkIn(.dry, .droopy, watered: true, daysFromDue: 0))
        XCTAssertEqual(r.newAdj, 0.5, accuracy: 1e-9)
    }

    func testAdjClampUpperBound() {
        // 1.8 × 1.20 = 2.16 → clamped down to 2.0.
        let r = engine().update(profile: snake, plant: plant(adj: 1.8),
                                checkIn: checkIn(.wet, .droopy, watered: false, daysFromDue: 0))
        XCTAssertEqual(r.newAdj, 2.0, accuracy: 1e-9)
    }

    func testHoldKeepsAdjUnchanged() {
        let r = engine().update(profile: pothos, plant: plant(adj: 1.3),
                                checkIn: checkIn(.moist, .fine, watered: true, daysFromDue: 0))
        XCTAssertEqual(r.newAdj, 1.3, accuracy: 1e-9)
    }

    // MARK: - Schedule recompute: water vs. recheck

    func testWateringAdvancesSchedule() {
        // didWater ⇒ lastWatered = checkIn.date, nextDue = checkIn.date + new interval.
        let ci = checkIn(.dry, .fine, watered: true, daysFromDue: -3)
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0), checkIn: ci)
        XCTAssertTrue(r.didWater)
        XCTAssertEqual(r.lastWatered, ci.date)
        // new adj 0.85 ⇒ 7 × 0.85 = 5.95 → 6 days.
        XCTAssertEqual(r.recommendation.days, 6)
        let expected = utc.date(byAdding: .day, value: 6, to: ci.date)!
        XCTAssertEqual(r.nextDue, expected)
    }

    func testSkipSetsRecheckWindowAndKeepsLastWatered() {
        // Skip ⇒ lastWatered unchanged, nextDue = checkIn.date + recheckDays.
        let p = plant(adj: 1.0)
        let ci = checkIn(.wet, .fine, watered: false, daysFromDue: 0)
        let r = engine().update(profile: snake, plant: p, checkIn: ci)
        XCTAssertFalse(r.didWater)
        XCTAssertEqual(r.lastWatered, p.lastWatered)
        XCTAssertEqual(r.recommendation.days, AdaptiveEngine.recheckDays)
        let expected = utc.date(byAdding: .day, value: AdaptiveEngine.recheckDays, to: ci.date)!
        XCTAssertEqual(r.nextDue, expected)
    }

    func testRecommendedWaterButUserDidNotWaterTakesRecheckPath() {
        // We recommended watering, but the user didn't ⇒ didWater=false, recheck path.
        let p = plant(adj: 1.0)
        let ci = checkIn(.dry, .fine, watered: false, daysFromDue: 0)
        let r = engine().update(profile: snake, plant: p, checkIn: ci)
        XCTAssertEqual(r.recommendation.action, .waterNow)
        XCTAssertFalse(r.didWater)
        XCTAssertEqual(r.lastWatered, p.lastWatered)
        let expected = utc.date(byAdding: .day, value: AdaptiveEngine.recheckDays, to: ci.date)!
        XCTAssertEqual(r.nextDue, expected)
    }

    // MARK: - Timing classification

    func testTimingClassification() {
        let e = engine()
        let p = plant(adj: 1.0) // interval 7 ⇒ band ±1.4 days.
        XCTAssertEqual(e.timing(checkInDate: date(daysFromDue: -3), plant: p, interval: 7), .early)
        XCTAssertEqual(e.timing(checkInDate: date(daysFromDue: 0), plant: p, interval: 7), .onTime)
        XCTAssertEqual(e.timing(checkInDate: date(daysFromDue: -1), plant: p, interval: 7), .onTime)
        XCTAssertEqual(e.timing(checkInDate: date(daysFromDue: 3), plant: p, interval: 7), .late)
    }

    func testTimingFallsBackToOnTimeWithoutAnchor() {
        // Never-scheduled plant (no nextDue / lastWatered) ⇒ on-time.
        let bare = Plant(nickname: "P", species: "Pothos", adj: 1.0)
        XCTAssertEqual(engine().timing(checkInDate: due, plant: bare, interval: 7), .onTime)
    }

    func testWeatherFactorFlowsIntoRecomputedInterval() {
        // Cold spell (×1.5) lengthens the recomputed interval: 7 × 1.5 × 1.0 = 10.5 → 11.
        let ci = checkIn(.dry, .fine, watered: true, daysFromDue: 0)
        let r = engine().update(profile: pothos, plant: plant(adj: 1.0),
                                checkIn: ci, weatherFactor: 1.5)
        XCTAssertEqual(r.recommendation.days, 11)
    }
}
