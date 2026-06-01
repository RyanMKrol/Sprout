import Foundation

/// Ties **location** and **forecast** together into the single value the
/// schedule engine consumes — a `weatherFactor` — with graceful fallback (T015).
///
/// The flow is: ask `LocationProviding` where we are; if that yields `nil`
/// (permission denied/restricted or no fix), or the `WeatherProviding` fetch
/// throws, resolve to the **neutral** `ScheduleEngine.defaultWeatherFactor`
/// (`1.0`) — no error reaches the UI, watering just isn't weather-nudged.
///
/// T015 stopped at "fetch a forecast and fall back safely"; **T016** lands the
/// real hot/cold → factor mapping, which lives in the pure `WeatherFactor`
/// (engine) and is delegated to by `factor(for:)` below. The fallback contract is
/// unchanged: **a denied/unavailable location still yields `weatherFactor == 1.0`.**
struct WeatherFactorService {
    private let locationProvider: LocationProviding
    private let weatherProvider: WeatherProviding

    init(locationProvider: LocationProviding, weatherProvider: WeatherProviding) {
        self.locationProvider = locationProvider
        self.weatherProvider = weatherProvider
    }

    /// The current forecast for the device's location, or `nil` when location is
    /// unavailable or the fetch fails. The optionality *is* the fallback signal:
    /// `nil` ⇒ use the neutral factor.
    func currentForecast() async -> WeatherForecast? {
        guard let coordinate = await locationProvider.currentCoordinate() else {
            return nil
        }
        return try? await weatherProvider.forecast(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    /// The weather multiplier to feed `ScheduleEngine`. Resolves to the neutral
    /// factor whenever no forecast is available; otherwise maps the forecast via
    /// `factor(for:)` (neutral in T015, real mapping in T016).
    func currentWeatherFactor() async -> Double {
        guard let forecast = await currentForecast() else {
            return ScheduleEngine.defaultWeatherFactor
        }
        return Self.factor(for: forecast)
    }

    /// Map a forecast to a `weatherFactor`. **T015 placeholder:** always neutral
    /// — T016 replaces this with the temperature/precipitation mapping
    /// (hot/dry `< 1.0`, cold `> 1.0`).
    static func factor(for forecast: WeatherForecast) -> Double {
        ScheduleEngine.defaultWeatherFactor
    }
}
