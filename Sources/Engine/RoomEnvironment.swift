import Foundation

/// Maps a room's environment (sunlight × humidity) to the multiplicative schedule
/// factor the `ScheduleEngine` already consumes — the indoor replacement for the
/// retired weather factor. `> 1.0` lengthens the interval (water less often), `< 1.0`
/// shortens it. More light and drier air dry the soil faster → shorter interval.
///
/// Pure: a hand-tuned 3×3 table, clamped to the same `[0.7, 1.3]` band the engine
/// used for weather, so the schedule never swings more than ±30%.
enum RoomEnvironment {
    /// The clamp band for the combined factor (matches the old weather range).
    static let factorRange: ClosedRange<Double> = 0.7...1.3

    /// The schedule factor for an explicit sunlight + humidity pair.
    static func factor(sunlight: SunlightLevel, humidity: RoomHumidity) -> Double {
        let raw = sunlightFactor(sunlight) * humidityFactor(humidity)
        return min(max(raw, factorRange.lowerBound), factorRange.upperBound)
    }

    /// The schedule factor for a plant's room — neutral `1.0` when the plant has no
    /// room assigned. The single entry point callers (T212) use.
    static func factor(for room: Room?) -> Double {
        guard let room else { return 1.0 }
        return factor(sunlight: room.sunlight, humidity: room.humidity)
    }

    private static func sunlightFactor(_ sunlight: SunlightLevel) -> Double {
        switch sunlight {
        case .low: return 1.15       // dries slowly → water less often
        case .indirect: return 1.0   // neutral
        case .direct: return 0.85    // dries fast → water more often
        }
    }

    private static func humidityFactor(_ humidity: RoomHumidity) -> Double {
        switch humidity {
        case .dry: return 0.9        // drier air → water more often
        case .normal: return 1.0
        case .moist: return 1.1      // humid air → water less often
        }
    }
}
