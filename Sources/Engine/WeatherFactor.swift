import Foundation

/// Maps a `WeatherForecast` to the **`weatherFactor`** the schedule engine
/// multiplies into a plant's watering interval (T016) — the piece that makes a
/// hot spell water plants sooner and a cold spell stretch them out.
///
/// Pure and deterministic: no I/O, no clock, no provider type — it takes the
/// decoded `WeatherForecast` value and returns a `Double`, so the whole mapping
/// is asserted directly in unit tests (just like `ScheduleEngine`).
///
/// The mapping is **temperature-led** — a warm forecast pulls the interval in, a
/// cold one pushes it out — with an optional **precipitation** term for *outdoor*
/// plants (recent rain means you can water less). Sprout has no indoor/outdoor
/// flag yet, so the live path calls this with `outdoor: false`; the rain term is
/// implemented and tested for when that flag lands (see `docs/LIMITATIONS.md`).
///
/// ```
/// hot forecast  → factor < 1.0   (water more often)
/// neutral       → factor = 1.0   (no nudge)
/// cold forecast → factor > 1.0   (water less often)
/// ```
enum WeatherFactor {
    /// Daily-**mean** temperature band (°C) treated as neutral — factor exactly
    /// `1.0`. Mild conditions shouldn't nudge the schedule at all; outside this
    /// band the factor ramps linearly.
    static let neutralBandC: ClosedRange<Double> = 16...24

    /// How far the factor moves per °C beyond the neutral band.
    static let degreeSlope: Double = 0.02

    /// Clamp band for the resulting factor, so even an extreme forecast can't
    /// swing the interval more than ±30%.
    static let factorRange: ClosedRange<Double> = 0.7...1.3

    /// Average daily precipitation (mm) below which rain is ignored — a drizzle
    /// shouldn't change anything.
    static let rainThresholdMM: Double = 1.0

    /// How far the factor lengthens per mm of average daily precipitation above
    /// the threshold (outdoor only).
    static let rainSlope: Double = 0.02

    /// Cap on the rain term, so a deluge can't swamp the temperature signal.
    static let rainCapFactor: Double = 0.2

    /// The `weatherFactor` for this forecast.
    ///
    /// `outdoor` enables the precipitation term (recent rain → water less). An
    /// empty forecast yields the neutral `ScheduleEngine.defaultWeatherFactor`.
    static func factor(for forecast: WeatherForecast, outdoor: Bool = false) -> Double {
        guard !forecast.days.isEmpty else { return ScheduleEngine.defaultWeatherFactor }

        let dailyMeans: [Double] = forecast.days.map { day in
            (day.temperatureMaxC + day.temperatureMinC) / 2.0
        }
        let meanTemp = dailyMeans.reduce(0.0, +) / Double(dailyMeans.count)

        var factor = temperatureFactor(forMeanC: meanTemp)
        if outdoor {
            factor += rainTerm(for: forecast)
        }
        return clamp(factor, to: factorRange)
    }

    /// Temperature → factor **before clamping**: `1.0` inside the neutral band,
    /// sloping below `1.0` above it (hot ⇒ water sooner) and above `1.0` below it
    /// (cold ⇒ water later).
    static func temperatureFactor(forMeanC meanC: Double) -> Double {
        if meanC > neutralBandC.upperBound {
            return 1.0 - (meanC - neutralBandC.upperBound) * degreeSlope
        }
        if meanC < neutralBandC.lowerBound {
            return 1.0 + (neutralBandC.lowerBound - meanC) * degreeSlope
        }
        return 1.0
    }

    /// Precipitation lengthening term (outdoor only): average daily rain above the
    /// threshold, scaled by `rainSlope` and capped at `rainCapFactor`. Always
    /// `≥ 0` — rain never shortens the interval.
    private static func rainTerm(for forecast: WeatherForecast) -> Double {
        let avgRain = forecast.days.map(\.precipitationMM).reduce(0, +) / Double(forecast.days.count)
        guard avgRain > rainThresholdMM else { return 0 }
        return min((avgRain - rainThresholdMM) * rainSlope, rainCapFactor)
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
