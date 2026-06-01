import Foundation

/// How much light a room gets — the dominant driver of how fast a plant dries out.
enum SunlightLevel: String, Codable, CaseIterable, Equatable, Sendable {
    case low        // interior / north-facing
    case indirect   // bright but no direct sun
    case direct     // direct sun on the leaves

    /// Human-readable label for pickers.
    var label: String {
        switch self {
        case .low: return "Low light"
        case .indirect: return "Indirect"
        case .direct: return "Direct sun"
        }
    }
}

/// How humid a room is — drier air pulls moisture from the soil faster.
enum RoomHumidity: String, Codable, CaseIterable, Equatable, Sendable {
    case dry
    case normal
    case moist

    var label: String {
        switch self {
        case .dry: return "Dry"
        case .normal: return "Normal"
        case .moist: return "Moist"
        }
    }
}

/// A room the user keeps plants in. Its environment (sunlight + humidity) drives the
/// watering cadence of the plants assigned to it — the indoor replacement for the
/// retired phone-weather input.
///
/// Pure value type: no SwiftUI / SwiftData imports. T211 maps this onto a SwiftData
/// `@Model`; `RoomEnvironment` turns its properties into a schedule factor.
struct Room: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var sunlight: SunlightLevel
    var humidity: RoomHumidity

    init(
        id: UUID = UUID(),
        name: String,
        sunlight: SunlightLevel = .indirect,
        humidity: RoomHumidity = .normal
    ) {
        self.id = id
        self.name = name
        self.sunlight = sunlight
        self.humidity = humidity
    }

    /// A short "Indirect · Normal" style summary for list rows.
    var environmentSummary: String { "\(sunlight.label) · \(humidity.label)" }
}
