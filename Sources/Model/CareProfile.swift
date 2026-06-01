import Foundation

/// How a species likes its soil to behave between waterings. Drives what a given
/// soil reading *means* at check-in time (see `docs/designs/adaptive-watering.md`).
///
/// Raw values match the `moisture` field in the bundled `care_database.json`
/// (decoded in T004), so this enum doubles as the JSON contract.
enum MoisturePreference: String, Codable, CaseIterable, Equatable, Sendable {
    /// Succulents, cacti, snake plant — wants to dry fully between waterings.
    case driesOut
    /// Pothos, monstera, most foliage — water when the top inch is dry.
    case evenlyMoist
    /// Ferns, calathea — keep lightly moist; Dry means overdue.
    case staysMoist
}

/// One record per species in the bundled care database — the adaptive *seed*
/// for a plant's watering cadence. The numbers are a sensible starting point;
/// the per-plant `adj` learned from check-ins (see `Plant`) personalises them.
///
/// Pure value type: no SwiftUI / SwiftData imports. The reusable validator that
/// enforces these invariants across the whole dataset lives in T004; `isValid`
/// here is the single-record predicate it (and the unit tests) build on.
struct CareProfile: Codable, Equatable, Identifiable, Sendable {
    /// Display name, also the unique key across the database (e.g. "Snake Plant").
    var species: String
    /// Starting cadence in days for typical indoor conditions.
    var baseIntervalDays: Int
    /// Floor — never recommend watering more often than this.
    var minIntervalDays: Int
    /// Ceiling — never stretch the interval beyond this.
    var maxIntervalDays: Int
    /// What the soil should look like at the due date.
    var moisture: MoisturePreference

    var id: String { species }

    init(
        species: String,
        baseIntervalDays: Int,
        minIntervalDays: Int,
        maxIntervalDays: Int,
        moisture: MoisturePreference
    ) {
        self.species = species
        self.baseIntervalDays = baseIntervalDays
        self.minIntervalDays = minIntervalDays
        self.maxIntervalDays = maxIntervalDays
        self.moisture = moisture
    }

    /// The core invariant for a single record: a positive, ordered interval band
    /// (`min ≤ base ≤ max`) and a non-empty species name. T004's dataset-level
    /// validator additionally enforces uniqueness of `species` across all records.
    var isValid: Bool {
        !species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && minIntervalDays > 0
            && minIntervalDays <= baseIntervalDays
            && baseIntervalDays <= maxIntervalDays
    }
}
