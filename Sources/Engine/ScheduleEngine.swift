import Foundation

/// A provider of "now", injected so the scheduling engine never reads the wall
/// clock directly (see `docs/designs/adaptive-watering.md`). Tests pass a
/// `FixedClock`; production wires a `SystemClock`. Keeping time injectable is
/// what makes every rule in the engine a deterministic, directly-asserted pure
/// function.
protocol Clock {
    var now: Date { get }
}

/// Reads the real wall clock — the production `Clock`.
struct SystemClock: Clock {
    var now: Date { Date() }
}

/// A `Clock` frozen at a fixed instant — for deterministic tests.
struct FixedClock: Clock {
    var now: Date
    init(_ now: Date) { self.now = now }
}

/// The pure schedule engine (T009): given a species' `CareProfile`, a plant's
/// learned `adj`, and an (injected) `weatherFactor`, it computes the
/// **effective watering interval** and the resulting **next-due** date.
///
/// ```
/// effectiveInterval = clamp( round(baseIntervalDays × weatherFactor × adj),
///                            minIntervalDays, maxIntervalDays )
/// nextDue           = lastWatered + effectiveInterval days
/// ```
///
/// Everything here is pure: no I/O, no wall-clock reads ("now" arrives via a
/// `Clock`). `weatherFactor` defaults to `1.0` until T015/T016 feed a forecast
/// in; `adj` is clamped to `Plant.adjRange` ([0.5, 2.0]) before use.
struct ScheduleEngine {
    /// Neutral weather multiplier — no hot/cold influence. T016 replaces this
    /// with a forecast-derived factor (hot/dry `< 1.0`, cold `> 1.0`).
    static let defaultWeatherFactor: Double = 1.0

    /// The calendar used for day arithmetic. Injectable for determinism; the
    /// default is the current calendar.
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// The effective watering interval in **days** for a plant of this species
    /// with this learned `adj` under this `weatherFactor`.
    ///
    /// `adj` is clamped to `Plant.adjRange` first, the raw product is rounded to
    /// the nearest whole day, and the result is clamped to the species'
    /// `[minIntervalDays, maxIntervalDays]` band — so it never recommends
    /// watering more often than `min` nor stretches past `max`.
    func effectiveInterval(
        for profile: CareProfile,
        adj: Double,
        weatherFactor: Double = defaultWeatherFactor
    ) -> Int {
        let clampedAdj = clamp(adj, to: Plant.adjRange)
        let raw = Double(profile.baseIntervalDays) * weatherFactor * clampedAdj
        let rounded = Int(raw.rounded())
        return clamp(rounded, lower: profile.minIntervalDays, upper: profile.maxIntervalDays)
    }

    /// The learned `adj` that makes the effective interval land as close as the
    /// clamps allow to `days` for this species under `weatherFactor` — the inverse of
    /// `effectiveInterval`, used when the user sets a cadence by hand. The result is
    /// clamped to `Plant.adjRange`, so the interval it produces stays within the
    /// species' `[minIntervalDays, maxIntervalDays]` band.
    func adj(
        forDesiredInterval days: Int,
        profile: CareProfile,
        weatherFactor: Double = defaultWeatherFactor
    ) -> Double {
        let base = Double(profile.baseIntervalDays) * weatherFactor
        guard base > 0 else { return 1.0 }
        let raw = Double(max(1, days)) / base
        return clamp(raw, to: Plant.adjRange)
    }

    /// The next-due date: `lastWatered + effectiveInterval days`.
    ///
    /// When the plant has never been watered, the interval is anchored at the
    /// injected `clock.now` so a freshly-added plant still gets a due date.
    func nextDue(
        for profile: CareProfile,
        plant: Plant,
        weatherFactor: Double = defaultWeatherFactor,
        clock: Clock
    ) -> Date {
        let anchor = plant.lastWatered ?? clock.now
        let interval = effectiveInterval(for: profile, adj: plant.adj, weatherFactor: weatherFactor)
        return calendar.date(byAdding: .day, value: interval, to: anchor) ?? anchor
    }

    /// The next-due date from an explicit `lastWatered` anchor — the building
    /// block T010/T011 use after recording a watering at a known date.
    func nextDue(
        for profile: CareProfile,
        adj: Double,
        lastWatered: Date,
        weatherFactor: Double = defaultWeatherFactor
    ) -> Date {
        let interval = effectiveInterval(for: profile, adj: adj, weatherFactor: weatherFactor)
        return calendar.date(byAdding: .day, value: interval, to: lastWatered) ?? lastWatered
    }

    // MARK: - Clamps

    private func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
