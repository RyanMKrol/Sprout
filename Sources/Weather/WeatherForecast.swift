import Foundation

/// A short multi-day forecast for one location — the unit the schedule engine
/// will eventually read to nudge a plant's watering interval (T016).
///
/// This is a **decoded, source-agnostic** value: `OpenMeteoWeatherProvider`
/// produces it from the Open-Meteo HTTP API, but nothing downstream depends on
/// that wire format. Keeping the forecast a plain `Equatable` struct (no I/O,
/// no provider type) is what lets the decode path be unit-tested straight from a
/// saved fixture with **no network**.
struct WeatherForecast: Equatable {
    /// One calendar day of the forecast.
    struct Day: Equatable {
        /// The day, as the provider's ISO-8601 date string (e.g. `2026-06-01`).
        /// Kept as the raw string so decoding stays time-zone-agnostic; T016 can
        /// parse it against an injected calendar if it needs real `Date`s.
        let date: String
        /// Forecast high, in °C (Open-Meteo's default unit).
        let temperatureMaxC: Double
        /// Forecast low, in °C.
        let temperatureMinC: Double
        /// Total precipitation for the day, in millimetres.
        let precipitationMM: Double
    }

    /// The forecast days, in chronological order as returned by the provider.
    let days: [Day]
}

extension WeatherForecast {
    /// Decode a `WeatherForecast` from raw Open-Meteo `/v1/forecast` JSON.
    ///
    /// Open-Meteo returns the daily series **column-major** — parallel arrays
    /// under `daily` keyed by variable (`time`, `temperature_2m_max`, …) — so
    /// this zips them back into row-major `Day` values. The arrays are expected
    /// to be the same length; the result is truncated to the shortest so a
    /// malformed-but-parseable payload can't crash.
    init(openMeteoData data: Data) throws {
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let daily = response.daily
        let count = min(
            daily.time.count,
            daily.temperatureMax.count,
            daily.temperatureMin.count,
            daily.precipitationSum.count
        )
        self.days = (0..<count).map { i in
            Day(
                date: daily.time[i],
                temperatureMaxC: daily.temperatureMax[i],
                temperatureMinC: daily.temperatureMin[i],
                precipitationMM: daily.precipitationSum[i]
            )
        }
    }
}

/// The slice of the Open-Meteo `/v1/forecast` response this app consumes.
///
/// Private to the decode path: callers never see this wire type, only the
/// cleaned-up `WeatherForecast`. Only the `daily` block we request is modelled;
/// every other field in the response is ignored.
private struct OpenMeteoResponse: Decodable {
    let daily: Daily

    struct Daily: Decodable {
        let time: [String]
        let temperatureMax: [Double]
        let temperatureMin: [Double]
        let precipitationSum: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case precipitationSum = "precipitation_sum"
        }
    }
}
