import Foundation

/// What the soil felt like at check-in time. The interpretation depends on the
/// species' `MoisturePreference` (see `docs/designs/adaptive-watering.md`).
enum SoilMoisture: String, Codable, CaseIterable, Equatable, Sendable {
    case dry
    case moist
    case wet
}

/// A quick, measurable read of the leaves at check-in time. We deliberately do
/// **not** model abstract "plant health" — only this observable state.
enum LeafState: String, Codable, CaseIterable, Equatable, Sendable {
    /// Dry / dehydrated leaves — under-watered, distinct from `droopy`. Ordered
    /// first so `allCases` matches the on-screen order (Crispy, Fine, Droopy).
    case crispy
    case fine
    case droopy
}

/// A single measurable observation the user makes at check-in time. The adaptive
/// engine (T010) consumes these to nudge the plant's learned `adj`.
///
/// Pure value type: no SwiftUI / SwiftData imports.
struct CheckIn: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    /// When the observation was made.
    var date: Date
    var soil: SoilMoisture
    var leaves: LeafState
    /// Whether the user actually watered at this check-in.
    var watered: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        soil: SoilMoisture,
        leaves: LeafState,
        watered: Bool
    ) {
        self.id = id
        self.date = date
        self.soil = soil
        self.leaves = leaves
        self.watered = watered
    }
}
