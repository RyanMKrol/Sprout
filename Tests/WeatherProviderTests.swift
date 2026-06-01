import XCTest
@testable import Sprout

/// Tests for the T015 weather module: Open-Meteo **decoding from a saved
/// fixture** (no network), the injectable location seam, and the
/// `WeatherFactorService` fallback contract — a denied/unavailable location
/// yields the neutral `weatherFactor == 1.0`.
final class WeatherProviderTests: XCTestCase {

    // MARK: - Test doubles

    /// A `LocationProviding` that returns whatever coordinate it's handed —
    /// `nil` models "permission denied / no fix".
    private struct StubLocationProvider: LocationProviding {
        let coordinate: Coordinate?
        func currentCoordinate() async -> Coordinate? { coordinate }
    }

    /// A `WeatherProviding` that returns a canned forecast or throws — never
    /// touches the network.
    private struct StubWeatherProvider: WeatherProviding {
        enum Outcome {
            case forecast(WeatherForecast)
            case failure
        }
        struct Failure: Error {}
        let outcome: Outcome

        func forecast(latitude: Double, longitude: Double) async throws -> WeatherForecast {
            switch outcome {
            case .forecast(let f): return f
            case .failure: throw Failure()
            }
        }
    }

    // MARK: - Fixtures

    /// Load the saved Open-Meteo response from the test bundle — proves the
    /// decode path works against a real-shaped payload with no network.
    private func loadFixtureData() throws -> Data {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "openmeteo_london", withExtension: "json"),
            "openmeteo_london.json missing from the test bundle"
        )
        return try Data(contentsOf: url)
    }

    // MARK: - Decoding

    func testDecodesOpenMeteoFixture() throws {
        let forecast = try WeatherForecast(openMeteoData: loadFixtureData())

        XCTAssertEqual(forecast.days.count, 7)

        let first = try XCTUnwrap(forecast.days.first)
        XCTAssertEqual(first.date, "2026-06-01")
        XCTAssertEqual(first.temperatureMaxC, 21.3, accuracy: 0.0001)
        XCTAssertEqual(first.temperatureMinC, 12.1, accuracy: 0.0001)
        XCTAssertEqual(first.precipitationMM, 0.0, accuracy: 0.0001)

        let last = try XCTUnwrap(forecast.days.last)
        XCTAssertEqual(last.date, "2026-06-07")
        XCTAssertEqual(last.temperatureMaxC, 20.0, accuracy: 0.0001)
        XCTAssertEqual(last.precipitationMM, 1.3, accuracy: 0.0001)
    }

    /// Mismatched-length daily arrays must truncate to the shortest rather than
    /// crash — a defensive guard against a malformed-but-parseable payload.
    func testDecodeTruncatesToShortestSeries() throws {
        let json = """
        {
          "daily": {
            "time": ["2026-06-01", "2026-06-02", "2026-06-03"],
            "temperature_2m_max": [20.0, 21.0],
            "temperature_2m_min": [10.0, 11.0],
            "precipitation_sum": [0.0, 0.0]
          }
        }
        """.data(using: .utf8)!

        let forecast = try WeatherForecast(openMeteoData: json)
        XCTAssertEqual(forecast.days.count, 2)
    }

    func testDecodeThrowsOnGarbage() {
        XCTAssertThrowsError(try WeatherForecast(openMeteoData: Data("not json".utf8)))
    }

    // MARK: - Fallback contract: weatherFactor == 1.0

    func testDeniedLocationYieldsNeutralFactor() async {
        let service = WeatherFactorService(
            locationProvider: StubLocationProvider(coordinate: nil),
            weatherProvider: StubWeatherProvider(outcome: .failure)
        )
        let factor = await service.currentWeatherFactor()
        XCTAssertEqual(factor, 1.0, accuracy: 0.0001)
        XCTAssertEqual(factor, ScheduleEngine.defaultWeatherFactor, accuracy: 0.0001)

        let forecast = await service.currentForecast()
        XCTAssertNil(forecast, "no location ⇒ no forecast fetch")
    }

    func testForecastFailureYieldsNeutralFactor() async {
        let service = WeatherFactorService(
            locationProvider: StubLocationProvider(coordinate: Coordinate(latitude: 51.5, longitude: -0.12)),
            weatherProvider: StubWeatherProvider(outcome: .failure)
        )
        let factor = await service.currentWeatherFactor()
        XCTAssertEqual(factor, 1.0, accuracy: 0.0001)
        let forecast = await service.currentForecast()
        XCTAssertNil(forecast)
    }

    /// With a location *and* a forecast, the service surfaces the decoded
    /// forecast. The London fixture is mild (≈17 °C daily mean, inside the T016
    /// neutral band), so its weather factor is `1.0` — genuinely neutral, not a
    /// placeholder. The hot/cold mapping is exercised in `WeatherFactorTests`.
    func testAvailableLocationAndForecastSurfacesForecast() async throws {
        let decoded = try WeatherForecast(openMeteoData: loadFixtureData())
        let service = WeatherFactorService(
            locationProvider: StubLocationProvider(coordinate: Coordinate(latitude: 51.5, longitude: -0.12)),
            weatherProvider: StubWeatherProvider(outcome: .forecast(decoded))
        )
        let forecast = await service.currentForecast()
        XCTAssertEqual(forecast, decoded)
        let factor = await service.currentWeatherFactor()
        XCTAssertEqual(factor, 1.0, accuracy: 0.0001)
    }
}
