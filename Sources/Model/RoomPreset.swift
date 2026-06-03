import Foundation

/// A common room type offered when **adding** a room, so the user can pick from a wheel
/// (Living Room, Kitchen, …) and get sensible default light + humidity instead of
/// configuring everything by hand. Picking "Other" (no preset) falls back to a custom
/// name + manual settings.
///
/// The defaults are a hand-tuned starting point — the same kind of typical-indoor
/// assumption as the room environment table — not a measurement. Pure value type so the
/// catalogue is unit-testable without any UI.
struct RoomPreset: Identifiable, Equatable, Sendable {
    let name: String
    let directSun: LightLevel
    let indirectSun: LightLevel
    let humidity: RoomHumidity

    var id: String { name }

    /// The inferred overall brightness for this preset (same mapping the editor shows).
    var brightness: Brightness { Brightness.inferred(directSun: directSun, indirectSun: indirectSun) }

    /// A short "Bright · Moist" style summary of the preset's environment.
    var environmentSummary: String { "\(brightness.label) · \(humidity.label)" }

    /// The common UK household rooms offered in the add-room wheel, with typical light +
    /// humidity. Ordered most-common first.
    static let common: [RoomPreset] = [
        RoomPreset(name: "Living Room", directSun: .medium, indirectSun: .high, humidity: .normal),
        RoomPreset(name: "Kitchen", directSun: .medium, indirectSun: .high, humidity: .normal),
        RoomPreset(name: "Bedroom", directSun: .low, indirectSun: .medium, humidity: .normal),
        RoomPreset(name: "Bathroom", directSun: .low, indirectSun: .medium, humidity: .moist),
        RoomPreset(name: "Dining Room", directSun: .medium, indirectSun: .medium, humidity: .normal),
        RoomPreset(name: "Office", directSun: .medium, indirectSun: .medium, humidity: .dry),
        RoomPreset(name: "Hallway", directSun: .low, indirectSun: .low, humidity: .normal),
        RoomPreset(name: "Conservatory", directSun: .high, indirectSun: .high, humidity: .dry),
        RoomPreset(name: "Kids' Room", directSun: .low, indirectSun: .medium, humidity: .normal),
        RoomPreset(name: "Balcony", directSun: .high, indirectSun: .high, humidity: .dry),
    ]
}
