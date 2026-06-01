import XCTest
@testable import Sprout

/// Tests for the T016 forecast → `weatherFactor` mapping (`WeatherFactor`) and the
/// **end-to-end recompute** it drives: a hot forecast shortens a plant's watering
/// interval, a cold one stretches it, and a mild one leaves it untouched.
final class WeatherFactorTests: XCTestCase {

    // MARK: - Helpers

    /// A flat forecast of `count` identical days at the given temperatures / rain.
    private func forecast(maxC: Double, minC: Double, rainMM: Double = 0, days count: Int = 5) -> WeatherForecast {
        WeatherForecast(days: (0..<count).map { i in
            WeatherForecast.Day(date: "2026-07-0\(i + 1)", temperatureMaxC: maxC, temperatureMinC: minC, precipitationMM: rainMM)
        })
    }

    // MARK: - Temperature mapping

    func testHotForecastYieldsFactorBelowOne() {
        // Daily mean 30 °C → 1.0 − (30 − 24) × 0.02 = 0.88.
        let factor = WeatherFactor.factor(for: forecast(maxC: 35, minC: 25))
        XCTAssertLessThan(factor, 1.0)
        XCTAssertEqual(factor, 0.88, accuracy: 0.0001)
    }

    func testColdForecastYieldsFactorAboveOne() {
        // Daily mean 6 °C → 1.0 + (16 − 6) × 0.02 = 1.20.
        let factor = WeatherFactor.factor(for: forecast(maxC: 9, minC: 3))
        XCTAssertGreaterThan(factor, 1.0)
        XCTAssertEqual(factor, 1.20, accuracy: 0.0001)
    }

    func testMildForecastIsNeutral() {
        // Daily mean 18 °C sits inside the neutral band → exactly 1.0.
        let factor = WeatherFactor.factor(for: forecast(maxC: 23, minC: 13))
        XCTAssertEqual(factor, 1.0, accuracy: 0.0001)
        XCTAssertEqual(factor, ScheduleEngine.defaultWeatherFactor, accuracy: 0.0001)
    }

    func testNeutralBandBoundariesAreNeutral() {
        XCTAssertEqual(WeatherFactor.temperatureFactor(forMeanC: 16), 1.0, accuracy: 0.0001)
        XCTAssertEqual(WeatherFactor.temperatureFactor(forMeanC: 24), 1.0, accuracy: 0.0001)
    }

    func testExtremeHeatClampsToFactorFloor() {
        // Mean 45 °C would map to 0.58 → clamped to the 0.7 floor.
        let factor = WeatherFactor.factor(for: forecast(maxC: 50, minC: 40))
        XCTAssertEqual(factor, WeatherFactor.factorRange.lowerBound, accuracy: 0.0001)
    }

    func testExtremeColdClampsToFactorCeiling() {
        // Mean −10 °C would map to 1.52 → clamped to the 1.3 ceiling.
        let factor = WeatherFactor.factor(for: forecast(maxC: -5, minC: -15))
        XCTAssertEqual(factor, WeatherFactor.factorRange.upperBound, accuracy: 0.0001)
    }

    func testEmptyForecastIsNeutral() {
        let factor = WeatherFactor.factor(for: WeatherForecast(days: []))
        XCTAssertEqual(factor, ScheduleEngine.defaultWeatherFactor, accuracy: 0.0001)
    }

    func testFactorAveragesAcrossDays() {
        // One hot day + one mild day → mean of daily means, not just the first day.
        let mixed = WeatherForecast(days: [
            WeatherForecast.Day(date: "2026-07-01", temperatureMaxC: 35, temperatureMinC: 25, precipitationMM: 0), // mean 30
            WeatherForecast.Day(date: "2026-07-02", temperatureMaxC: 23, temperatureMinC: 13, precipitationMM: 0), // mean 18
        ])
        // Overall mean = 24 → on the neutral upper bound → exactly 1.0.
        XCTAssertEqual(WeatherFactor.factor(for: mixed), 1.0, accuracy: 0.0001)
    }

    // MARK: - Precipitation (outdoor only)

    func testRainIgnoredForIndoorPlants() {
        // Heavy rain over a mild forecast: indoor (the default) ignores it entirely.
        let wet = forecast(maxC: 23, minC: 13, rainMM: 12)
        XCTAssertEqual(WeatherFactor.factor(for: wet, outdoor: false), 1.0, accuracy: 0.0001)
    }

    func testRainLengthensForOutdoorPlants() {
        // Same mild + wet forecast, outdoor: rain above the threshold lengthens.
        let wet = forecast(maxC: 23, minC: 13, rainMM: 12)
        let factor = WeatherFactor.factor(for: wet, outdoor: true)
        // (12 − 1) × 0.02 = 0.22 → capped at 0.20 → 1.20.
        XCTAssertEqual(factor, 1.0 + WeatherFactor.rainCapFactor, accuracy: 0.0001)
    }

    func testLightRainBelowThresholdIsIgnoredOutdoors() {
        let drizzle = forecast(maxC: 23, minC: 13, rainMM: 0.5)
        XCTAssertEqual(WeatherFactor.factor(for: drizzle, outdoor: true), 1.0, accuracy: 0.0001)
    }

    // MARK: - End-to-end recompute (forecast → factor → schedule)

    private let profile = CareProfile(
        species: "Peace Lily", baseIntervalDays: 6, minIntervalDays: 4, maxIntervalDays: 10, moisture: .evenlyMoist
    )

    func testHotSpellShortensTheEffectiveInterval() {
        let engine = ScheduleEngine()
        let neutral = engine.effectiveInterval(for: profile, adj: Plant.defaultAdj)
        let hotFactor = WeatherFactor.factor(for: forecast(maxC: 35, minC: 25)) // 0.88
        let hot = engine.effectiveInterval(for: profile, adj: Plant.defaultAdj, weatherFactor: hotFactor)

        XCTAssertEqual(neutral, 6)
        XCTAssertEqual(hot, 5) // round(6 × 0.88) = 5
        XCTAssertLessThan(hot, neutral)
    }

    func testColdSpellStretchesTheEffectiveInterval() {
        let engine = ScheduleEngine()
        let coldFactor = WeatherFactor.factor(for: forecast(maxC: 9, minC: 3)) // 1.20
        let cold = engine.effectiveInterval(for: profile, adj: Plant.defaultAdj, weatherFactor: coldFactor)
        XCTAssertEqual(cold, 7) // round(6 × 1.20) = 7
        XCTAssertGreaterThan(cold, 6)
    }

    func testEndToEndRecomputeThroughAdaptiveEngineAndExplanation() {
        // A watering recorded on-time during a hot spell advances the schedule using
        // the weather-shortened interval (the on-time/moist row holds `adj`, so the
        // only mover is weather), and the "why" explanation names the warm spell.
        let calendar = Calendar(identifier: .gregorian)
        let adaptive = AdaptiveEngine(schedule: ScheduleEngine(calendar: calendar))
        let builder = ScheduleExplanationBuilder(schedule: ScheduleEngine(calendar: calendar))
        let hotFactor = WeatherFactor.factor(for: forecast(maxC: 35, minC: 25)) // 0.88

        let lastWatered = Date(timeIntervalSince1970: 1_750_000_000)
        let due = calendar.date(byAdding: .day, value: 6, to: lastWatered)!
        var plant = Plant(nickname: "Lily", species: "Peace Lily", lastWatered: lastWatered)
        plant.nextDue = due
        // Check in exactly on the due date with moist soil / fine leaves → on-target,
        // a neutral `adj` nudge, so weather alone shapes the recompute.
        let checkIn = CheckIn(date: due, soil: .moist, leaves: .fine, watered: true)

        let update = adaptive.update(profile: profile, plant: plant, checkIn: checkIn, weatherFactor: hotFactor)
        XCTAssertTrue(update.didWater)
        XCTAssertEqual(update.newAdj, Plant.defaultAdj, accuracy: 0.0001)

        // Hot recompute is 5 days out from the watering; neutral would be 6.
        let hotDue = calendar.date(byAdding: .day, value: 5, to: due)
        let neutralUpdate = adaptive.update(profile: profile, plant: plant, checkIn: checkIn)
        XCTAssertEqual(update.nextDue, hotDue)
        XCTAssertLessThan(update.nextDue, neutralUpdate.nextDue)

        let explanation = builder.explanation(
            species: "Peace Lily", profile: profile, adj: Plant.defaultAdj, lastCheckIn: nil, environmentFactor: hotFactor
        )
        XCTAssertEqual(explanation.cause, .driesFaster)
        XCTAssertEqual(explanation.effectiveDays, 5)
        XCTAssertTrue(explanation.sentence.contains("dries out faster"))
    }
}
