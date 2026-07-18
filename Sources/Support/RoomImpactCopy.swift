import Foundation

/// Plain-language copy for the Room detail screen's watering-impact banner (screen 15).
///
/// Turns a room's `RoomEnvironment` schedule factor into a sentence explaining how the
/// room's light and humidity nudge its plants' watering cadence. The direction matches
/// the engine's semantics (see `RoomEnvironment`): a factor **below 1** shortens the
/// interval (water *more* often — bright, dry rooms), **above 1** lengthens it (water
/// *less* often — dark, humid rooms). `P = round(|1 − factor| × 100)`; a factor that
/// rounds to 0% change reads as balanced.
enum RoomImpactCopy {
    static func impactLine(factor: Double) -> String {
        let percent = Int((abs(1 - factor) * 100).rounded())
        if percent == 0 {
            return "Balanced light and humidity — no adjustment to watering here."
        }
        if factor < 1 {
            return "Bright light dries soil faster — plants here are watered about \(percent)% more often."
        }
        return "Low light holds moisture longer — plants here are watered about \(percent)% less often."
    }
}
