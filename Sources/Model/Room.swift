import Foundation

/// Legacy coarse sunlight enum (T211). Superseded by the two-input light model
/// (`directSun` + `indirectSun`) in **T220**, but kept as a defaulted field on `Room`
/// / `StoredRoom` so existing stores still open (additive schema, no migration).
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

/// How much of one kind of light (direct *or* indirect) a room gets — the T220
/// replacement inputs for the coarse `SunlightLevel`. Two of these (direct + indirect)
/// combine into an inferred `Brightness`.
enum LightLevel: String, Codable, CaseIterable, Equatable, Sendable {
    case low
    case medium
    case high

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    /// Numeric contribution used when inferring brightness (low → 0 … high → 2).
    var weight: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

/// The overall brightness of a room, inferred from its direct + indirect light
/// (T220). Drives the schedule factor: brighter ⇒ soil dries faster ⇒ shorter
/// interval.
enum Brightness: String, Codable, CaseIterable, Equatable, Sendable {
    case dark
    case medium
    case bright

    var label: String {
        switch self {
        case .dark: return "Dark"
        case .medium: return "Medium"
        case .bright: return "Bright"
        }
    }

    /// Infer the overall brightness from the two light inputs. Direct sun is
    /// weighted twice as strongly as indirect, since it dries soil far faster.
    /// Score range `0...6` → dark `0...1`, medium `2...3`, bright `4...6`, so the
    /// inference is monotonic in both inputs.
    static func inferred(directSun: LightLevel, indirectSun: LightLevel) -> Brightness {
        let score = directSun.weight * 2 + indirectSun.weight
        switch score {
        case 0...1: return .dark
        case 2...3: return .medium
        default: return .bright
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

/// A room the user keeps plants in. Its environment (light + humidity) drives the
/// watering cadence of the plants assigned to it — the indoor replacement for the
/// retired phone-weather input.
///
/// Pure value type: no SwiftUI / SwiftData imports. `StoredRoom` maps this onto a
/// SwiftData `@Model`; `RoomEnvironment` turns its derived brightness × humidity into
/// a schedule factor.
///
/// T220 replaced the single `sunlight` enum with two independent light inputs
/// (`directSun` + `indirectSun`) that infer a `brightness`. The old `sunlight` field
/// is kept (defaulted, derived) purely so existing stores still open — additive
/// schema, no migration.
struct Room: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    /// Direct sunlight that lands on the plants (e.g. a south-facing sill).
    var directSun: LightLevel
    /// Ambient/indirect daylight in the room (no direct beam on the leaves).
    var indirectSun: LightLevel
    var humidity: RoomHumidity
    /// Legacy coarse sunlight — retained only for additive schema compatibility (T220).
    var sunlight: SunlightLevel

    /// Primary initialiser — the T220 two-input light model. `sunlight` defaults to a
    /// value derived from the two light levels so the legacy field stays consistent.
    init(
        id: UUID = UUID(),
        name: String,
        directSun: LightLevel,
        indirectSun: LightLevel,
        humidity: RoomHumidity = .normal,
        sunlight: SunlightLevel? = nil
    ) {
        self.id = id
        self.name = name
        self.directSun = directSun
        self.indirectSun = indirectSun
        self.humidity = humidity
        self.sunlight = sunlight ?? Room.legacySunlight(directSun: directSun, indirectSun: indirectSun)
    }

    /// Legacy initialiser (T211 callers / existing tests) — derives the two light
    /// levels from the coarse `sunlight` enum.
    init(
        id: UUID = UUID(),
        name: String,
        sunlight: SunlightLevel = .indirect,
        humidity: RoomHumidity = .normal
    ) {
        let levels = Room.lightLevels(for: sunlight)
        self.init(
            id: id,
            name: name,
            directSun: levels.direct,
            indirectSun: levels.indirect,
            humidity: humidity,
            sunlight: sunlight
        )
    }

    /// The brightness inferred from this room's direct + indirect light.
    var brightness: Brightness {
        Brightness.inferred(directSun: directSun, indirectSun: indirectSun)
    }

    /// A short "Bright · Dry" style summary for list rows.
    var environmentSummary: String { "\(brightness.label) · \(humidity.label)" }

    // MARK: - Legacy ↔ light-level mapping

    /// The two light levels that best represent a coarse legacy `sunlight` value —
    /// used to open old rooms and to keep the legacy field meaningful.
    static func lightLevels(for sunlight: SunlightLevel) -> (direct: LightLevel, indirect: LightLevel) {
        switch sunlight {
        case .low: return (.low, .low)        // → dark
        case .indirect: return (.low, .high)  // → medium (bright, no direct beam)
        case .direct: return (.high, .high)   // → bright
        }
    }

    /// The legacy `sunlight` value that best represents a pair of light levels, via
    /// their inferred brightness — so a round-trip through the legacy field is stable.
    static func legacySunlight(directSun: LightLevel, indirectSun: LightLevel) -> SunlightLevel {
        switch Brightness.inferred(directSun: directSun, indirectSun: indirectSun) {
        case .dark: return .low
        case .medium: return .indirect
        case .bright: return .direct
        }
    }
}
