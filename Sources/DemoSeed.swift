import Foundation

/// Verification baseline (T002) — a lightweight, in-memory demo dataset and the
/// launch hook that activates it. This is the convention **every later UI task
/// verifies against**: launch the app with `-seedDemoData YES` (optionally
/// `SPROUT_SCREEN=<name>`) so `build_run.sh` screenshots show real content
/// instead of the empty first-run screen — no XCUITest, no manual taps.
///
/// It is strictly **DEBUG-only**: in release builds the hook compiles to a no-op
/// (`DemoSeed.isActive` is always `false`, `plants` is always empty), so neither
/// the demo data nor the seeding path ships in a production binary.
///
/// Usage:
///   ./build_run.sh "iPhone 17 Pro" -seedDemoData YES
///   ./build_run.sh "iPhone 17 Pro" -seedDemoData YES   # + SPROUT_SCREEN=detail later
///
/// T006 swapped the throwaway `DemoPlant` stand-in for the **real** domain model
/// (`Plant`) seeded into an in-memory `PlantRepository`, while keeping this same
/// launch-argument contract so every later UI task's screenshots stay scriptable.

/// The DEBUG launch hook. Reads the `-seedDemoData YES` launch argument and the
/// optional `SPROUT_SCREEN=<name>` environment variable.
enum DemoSeed {
    /// Which screen a screenshot wants to land on. Later tasks deep-link on this
    /// (e.g. "detail", "checkin", "settings"); defaults to the home list.
    static var requestedScreen: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SPROUT_SCREEN"] ?? "list"
        #else
        return "list"
        #endif
    }

    /// `true` only in DEBUG builds launched with `-seedDemoData YES`.
    static var isActive: Bool {
        #if DEBUG
        // `-seedDemoData YES` registers in UserDefaults' argument domain, so the
        // bool lookup works; the raw-arguments check is a belt-and-braces fallback.
        if UserDefaults.standard.bool(forKey: "seedDemoData") { return true }
        return ProcessInfo.processInfo.arguments.contains("-seedDemoData")
        #else
        return false
        #endif
    }

    /// The in-memory demo plants (real domain `Plant`s) — non-empty only when
    /// `isActive`. `nextDue` dates are relative to launch time so the seeded list
    /// shows a realistic spread: overdue, due today, and upcoming.
    static var plants: [Plant] {
        #if DEBUG
        guard isActive else { return [] }
        return sampleData
        #else
        return []
        #endif
    }

    /// A fixed forecast-derived weather multiplier for seeded screenshots (T016):
    /// a deterministic **warm spell** so the detail "why" explanation visibly
    /// mentions weather, without invoking CoreLocation/network in the simulator.
    /// Neutral (`1.0`) outside DEBUG / when the seed isn't active.
    static var weatherFactor: Double {
        #if DEBUG
        guard isActive else { return ScheduleEngine.defaultWeatherFactor }
        return WeatherFactor.factor(for: warmSpellForecast)
        #else
        return ScheduleEngine.defaultWeatherFactor
        #endif
    }

    /// Species pre-filled into the basket for the `SPROUT_SCREEN=basket` screenshot
    /// (T204) so it lands on a populated basket. Empty outside DEBUG / when inactive.
    /// Names must exist in the bundled care database to resolve.
    static var basketSampleSpecies: [String] {
        #if DEBUG
        guard isActive else { return [] }
        return ["Pothos", "Snake Plant", "Monstera deliciosa"]
        #else
        return []
        #endif
    }

    /// Demo rooms (T213), with fixed ids so plants can reference them. Empty outside
    /// DEBUG / when inactive.
    static var rooms: [Room] {
        #if DEBUG
        guard isActive else { return [] }
        return [
            Room(id: livingRoomID, name: "Living Room", sunlight: .direct, humidity: .dry),
            Room(id: bathroomID, name: "Bathroom", sunlight: .low, humidity: .moist),
        ]
        #else
        return []
        #endif
    }

    /// A fresh in-memory repository pre-loaded with `rooms` + `plants`, for seeded
    /// screenshots. DEBUG-only; callers fall back to an empty store when inactive.
    static func seededRepository() throws -> PlantRepository {
        let repository = try PlantStore.inMemory()
        #if DEBUG
        for room in rooms {
            try repository.addRoom(room)
        }
        for plant in plants {
            try repository.add(plant)
        }
        #endif
        return repository
    }

    #if DEBUG
    private static let livingRoomID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    private static let bathroomID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!

    /// A clearly-hot 5-day forecast (≈30 °C daily mean) so `weatherFactor` lands
    /// well below 1.0 — enough to shorten Peace Lily's 6-day cadence to 5.
    private static var warmSpellForecast: WeatherForecast {
        WeatherForecast(days: (0..<5).map { i in
            WeatherForecast.Day(
                date: "2026-07-0\(i + 1)",
                temperatureMaxC: 35.0,
                temperatureMinC: 25.0,
                precipitationMM: 0.0
            )
        })
    }

    private static var sampleData: [Plant] {
        let now = Date()
        func day(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        }
        // The first plant in due-order (Lily) carries a small check-in history so
        // the `SPROUT_SCREEN=detail` screenshot (T008) lands on a populated history.
        let lilyHistory = [
            CheckIn(date: day(-14), soil: .dry, leaves: .droopy, watered: true),
            CheckIn(date: day(-7), soil: .moist, leaves: .fine, watered: false),
            CheckIn(date: day(-2), soil: .dry, leaves: .fine, watered: true),
        ]
        return [
            // Lily is first in due order, so the `SPROUT_SCREEN=detail` deep-link
            // lands on her. With a neutral learned `adj` and a real check-in history,
            // the demo warm-spell `weatherFactor` (T016) becomes the dominant cause —
            // her detail screen shows "shortened … because of a warm spell".
            Plant(nickname: "Lily", species: "Peace Lily", adj: Plant.defaultAdj, lastWatered: day(-2), nextDue: day(-1), checkIns: lilyHistory, roomID: livingRoomID),
            Plant(nickname: "Monty", species: "Monstera deliciosa", nextDue: day(0), roomID: livingRoomID),
            Plant(nickname: "Fern Bundy", species: "Boston Fern", nextDue: day(2), roomID: bathroomID),
            Plant(nickname: "Pothos Pete", species: "Pothos", nextDue: day(3)),
            Plant(nickname: "Spike", species: "Snake Plant", nextDue: day(6)),
        ]
    }
    #endif
}
