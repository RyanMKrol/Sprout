import CoreLocation
import Foundation

/// A latitude/longitude pair — the input the weather provider needs and the
/// only thing the app cares about from CoreLocation.
struct Coordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

/// Boundary for "where is the device?" (T015).
///
/// Injected so the weather path never reaches into `CLLocationManager`
/// directly: tests pass a stub returning a fixed `Coordinate` (or `nil`), and
/// the real `CoreLocationProvider` is the only type that touches CoreLocation.
///
/// `currentCoordinate()` returns **`nil`** for every "can't locate" outcome —
/// permission denied/restricted, or a location fetch that fails — so callers
/// have a single, test-reachable signal to fall back on (the neutral weather
/// factor) without inspecting `CLAuthorizationStatus`.
protocol LocationProviding {
    func currentCoordinate() async -> Coordinate?
}

/// `LocationProviding` backed by `CLLocationManager`.
///
/// Requests **when-in-use** authorization on first use, then a single
/// coarse-accuracy fix (a forecast only needs city-scale precision). Every
/// failure path — denied/restricted authorization, or a manager error —
/// resolves to `nil` so the caller degrades to the neutral factor rather than
/// erroring. Not unit-tested (it would need a real device/simulator location);
/// the `LocationProviding` seam is what tests exercise instead.
final class CoreLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    /// The in-flight request's continuation, if any. Guards against issuing a
    /// second request while one is pending and is resumed **exactly once**.
    private var continuation: CheckedContinuation<Coordinate?, Never>?

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentCoordinate() async -> Coordinate? {
        // Already-denied: no point prompting or waiting.
        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        default:
            break
        }
        // Only one request at a time; if one is somehow pending, decline.
        guard continuation == nil else { return nil }

        return await withCheckedContinuation { cont in
            continuation = cont
            switch manager.authorizationStatus {
            case .notDetermined:
                // The fix is kicked off from `didChangeAuthorization` once the
                // user answers the prompt.
                manager.requestWhenInUseAuthorization()
            default:
                manager.requestLocation()
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            resume(nil)
        case .notDetermined:
            break // still waiting on the user
        @unknown default:
            resume(nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last.map {
            Coordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        resume(coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(nil)
    }

    /// Resume the pending continuation once, then clear it.
    private func resume(_ coordinate: Coordinate?) {
        continuation?.resume(returning: coordinate)
        continuation = nil
    }
}
