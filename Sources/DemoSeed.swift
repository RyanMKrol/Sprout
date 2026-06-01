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

    /// A fresh in-memory repository pre-loaded with `plants`, for seeded
    /// screenshots. DEBUG-only; callers fall back to an empty store when inactive.
    static func seededRepository() throws -> PlantRepository {
        let repository = try PlantStore.inMemory()
        #if DEBUG
        for plant in plants {
            try repository.add(plant)
        }
        #endif
        return repository
    }

    #if DEBUG
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
            // Lily carries a learned `adj` below 1.0 so its detail screen shows a
            // real "shortened" explanation (T012) rather than the seed cadence.
            Plant(nickname: "Lily", species: "Peace Lily", adj: 0.7, lastWatered: day(-2), nextDue: day(-1), checkIns: lilyHistory),
            Plant(nickname: "Monty", species: "Monstera deliciosa", nextDue: day(0)),
            Plant(nickname: "Fern Bundy", species: "Boston Fern", nextDue: day(2)),
            Plant(nickname: "Pothos Pete", species: "Pothos", nextDue: day(3)),
            Plant(nickname: "Spike", species: "Snake Plant", nextDue: day(6)),
        ]
    }
    #endif
}
