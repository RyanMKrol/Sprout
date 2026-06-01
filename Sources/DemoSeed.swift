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
/// Later tasks (T006+) replace `DemoPlant` with the real domain model / repository
/// but keep this same launch-argument contract so their screenshots stay scriptable.

/// A minimal plant stand-in used only for seeded screenshots until the real
/// domain model (T003) and persistence (T005) land.
struct DemoPlant: Identifiable {
    let id = UUID()
    let name: String
    let species: String
    /// Human-readable next-watering hint shown on the card pill.
    let nextDue: String
    /// Whether the plant is currently reported healthy (drives the indicator).
    let isHealthy: Bool
}

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

    /// The in-memory demo plants — non-empty only when `isActive`.
    static var plants: [DemoPlant] {
        #if DEBUG
        guard isActive else { return [] }
        return sampleData
        #else
        return []
        #endif
    }

    #if DEBUG
    private static let sampleData: [DemoPlant] = [
        DemoPlant(name: "Monty", species: "Monstera deliciosa", nextDue: "Due today", isHealthy: true),
        DemoPlant(name: "Fern Bundy", species: "Nephrolepis exaltata", nextDue: "Due in 2 days", isHealthy: false),
        DemoPlant(name: "Spike", species: "Sansevieria trifasciata", nextDue: "Due in 6 days", isHealthy: true),
        DemoPlant(name: "Pothos Pete", species: "Epipremnum aureum", nextDue: "Due in 3 days", isHealthy: true),
        DemoPlant(name: "Lily", species: "Spathiphyllum wallisii", nextDue: "Overdue by 1 day", isHealthy: false),
    ]
    #endif
}
