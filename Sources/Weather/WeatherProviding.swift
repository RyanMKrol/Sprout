import Foundation

/// Boundary for fetching a `WeatherForecast` for a coordinate (T015).
///
/// Callers depend on **this protocol**, never on `URLSession` directly — so the
/// schedule wiring (T016) and tests can swap in a recorded/stubbed forecast
/// without touching the network, mirroring how the app depends on
/// `PlantRepository` and `NotificationScheduling` rather than their concretes.
protocol WeatherProviding {
    /// Fetch a short forecast for `latitude`/`longitude`. Throws on a network or
    /// decode failure — the higher-level `WeatherFactorService` turns any such
    /// throw into the neutral fallback rather than surfacing it to the UI.
    func forecast(latitude: Double, longitude: Double) async throws -> WeatherForecast
}

/// `WeatherProviding` backed by the free, **key-less** Open-Meteo forecast API.
///
/// Requests only the daily fields the app uses (`temperature_2m_max/min`,
/// `precipitation_sum`) and decodes them via `WeatherForecast(openMeteoData:)`.
/// The `URLSession` is injected so this stays the only place that touches the
/// network; the decode itself is exercised in tests from a saved fixture.
struct OpenMeteoWeatherProvider: WeatherProviding {
    /// Open-Meteo forecast endpoint — no API key, no auth.
    static let endpoint = URL(string: "https://api.open-meteo.com/v1/forecast")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func forecast(latitude: Double, longitude: Double) async throws -> WeatherForecast {
        var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        let (data, _) = try await session.data(from: components.url!)
        return try WeatherForecast(openMeteoData: data)
    }
}
