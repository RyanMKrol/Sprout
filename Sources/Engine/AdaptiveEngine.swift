import Foundation

/// How `checkIn.date` compares to the plant's current `nextDue` (see
/// `docs/designs/adaptive-watering.md`). **early** = before due by more than
/// ~20% of the effective interval; **late** = after due by more than that same
/// band; **onTime** = within the band.
enum CheckInTiming: String, Equatable, Sendable {
    case early
    case onTime
    case late
}

/// The structured *decision* an adaptive update produces. The UI text (T012) and
/// the unit tests assert this value — never a brittle sentence. It is "an enum
/// case + a computed day count" (the design): `reason` pins the exact table row,
/// `action` says what to do, and `days` is the relevant horizon (the new
/// watering interval when we recommend watering, the recheck window when we skip).
struct WateringRecommendation: Equatable, Sendable {
    /// What the user should do at this check-in.
    enum Action: String, Equatable, Sendable {
        case waterNow
        case waterLightly
        case skip
        case monitor

        /// Whether this action is a watering recommendation — used to derive
        /// `didWater` (we only advance the schedule when we *recommended* water
        /// and the user actually watered).
        var recommendsWater: Bool {
            switch self {
            case .waterNow, .waterLightly: return true
            case .skip, .monitor: return false
            }
        }
    }

    /// The exact row of the design decision table that fired. One case per row,
    /// so a unit-test table can assert the *decision* with no string matching.
    enum Reason: String, Equatable, Sendable {
        /// Wet soil, leaves fine — skip, it's still wet.
        case stillWet
        /// Dry & early — dried out faster than expected; shorten.
        case driedEarly
        /// Dry & on-time/late for a dries-out / evenly-moist species — on target.
        case onTargetDry
        /// Dry for a stays-moist species — don't let it dry out next time; shorten.
        case dontDryOut
        /// Moist & on-time — on target, water lightly.
        case onTargetMoist
        /// Moist & early — a touch early, fine to top up; lengthen slightly.
        case touchEarly
        /// Droopy + dry — water now, leaves are drooping; shorten.
        case droopyDry
        /// Droopy + wet — let it dry out, may be overwatered; lengthen.
        case droopyWet
        /// Droopy + moist — keep an eye on it.
        case droopyMoist
        /// Crispy + dry — dehydrated and dry; water now and shorten hard.
        case crispyDry
        /// Crispy + moist — dehydrated despite damp soil; still water now and shorten.
        case crispyMoist
        /// Crispy + wet — crisping despite wet soil; water lightly, mild shorten.
        case crispyWet
    }

    var action: Action
    var reason: Reason
    /// Days until the next watering when we recommend watering; the recheck
    /// window (`AdaptiveEngine.recheckDays`) when we skip / monitor.
    var days: Int
}

/// The full result of applying a check-in: the design's
/// `(newAdj, recommendation, didWater)` plus the recomputed schedule fields the
/// caller (T011) writes back onto the `Plant`.
struct CheckInUpdate: Equatable, Sendable {
    /// The learned multiplier after this check-in's nudge, clamped to `Plant.adjRange`.
    var newAdj: Double
    /// The structured decision (action + reason + day count).
    var recommendation: WateringRecommendation
    /// True iff we recommended watering **and** the user watered.
    var didWater: Bool
    /// `checkIn.date` when `didWater`; otherwise the plant's existing `lastWatered`.
    var lastWatered: Date?
    /// Recomputed next-due: from the new `adj` when watered, else
    /// `checkIn.date + recheckDays`.
    var nextDue: Date
}

/// The pure adaptive update (T010): a check-in's measurable observations nudge a
/// plant's learned `adj` and produce a structured recommendation, exactly per the
/// decision table in `docs/designs/adaptive-watering.md`.
///
/// Everything here is a deterministic pure function — no I/O, no wall-clock reads.
/// Timing is derived from the plant's `nextDue` relative to `checkIn.date`, and
/// the schedule recompute is delegated to `ScheduleEngine`, so the same
/// `weatherFactor` and `adjRange` clamp apply consistently.
struct AdaptiveEngine {
    /// When we skip (don't water), the next reminder lands this many days out.
    /// Named + tunable per the design.
    static let recheckDays: Int = 3

    /// Fraction of the effective interval that defines the on-time band: a
    /// check-in more than this far before/after due is `early`/`late`.
    static let timingBand: Double = 0.20

    private let schedule: ScheduleEngine

    init(schedule: ScheduleEngine = ScheduleEngine()) {
        self.schedule = schedule
    }

    /// Apply `checkIn` to a plant of species `profile`, returning the nudged
    /// `adj`, the structured recommendation, and the recomputed schedule.
    ///
    /// - `weatherFactor` is passed straight through to `ScheduleEngine` so the
    ///   recomputed interval/next-due honour the current forecast (1.0 until
    ///   T015/T016).
    func update(
        profile: CareProfile,
        plant: Plant,
        checkIn: CheckIn,
        weatherFactor: Double = ScheduleEngine.defaultWeatherFactor
    ) -> CheckInUpdate {
        let interval = schedule.effectiveInterval(for: profile, adj: plant.adj, weatherFactor: weatherFactor)
        let timing = self.timing(checkInDate: checkIn.date, plant: plant, interval: interval)

        let decision = decide(
            soil: checkIn.soil,
            leaves: checkIn.leaves,
            timing: timing,
            moisture: profile.moisture
        )
        let newAdj = clampedAdj(plant.adj * decision.nudge)

        let recommendsWater = decision.action.recommendsWater
        let didWater = recommendsWater && checkIn.watered

        // Day count carried in the recommendation: the new watering interval when
        // we'd water, else the recheck window.
        let recommendationDays = recommendsWater
            ? schedule.effectiveInterval(for: profile, adj: newAdj, weatherFactor: weatherFactor)
            : Self.recheckDays

        let recommendation = WateringRecommendation(
            action: decision.action,
            reason: decision.reason,
            days: recommendationDays
        )

        let lastWatered: Date?
        let nextDue: Date
        if didWater {
            lastWatered = checkIn.date
            nextDue = schedule.nextDue(
                for: profile,
                adj: newAdj,
                lastWatered: checkIn.date,
                weatherFactor: weatherFactor
            )
        } else {
            lastWatered = plant.lastWatered
            nextDue = schedule.calendar.date(
                byAdding: .day, value: Self.recheckDays, to: checkIn.date
            ) ?? checkIn.date
        }

        return CheckInUpdate(
            newAdj: newAdj,
            recommendation: recommendation,
            didWater: didWater,
            lastWatered: lastWatered,
            nextDue: nextDue
        )
    }

    // MARK: - Timing

    /// Classify `checkInDate` against the plant's current due date. The due date
    /// is `plant.nextDue` when present, else `lastWatered + interval`; with
    /// neither anchor (a never-scheduled plant) timing is `onTime`.
    func timing(checkInDate: Date, plant: Plant, interval: Int) -> CheckInTiming {
        let due: Date?
        if let next = plant.nextDue {
            due = next
        } else if let last = plant.lastWatered {
            due = schedule.calendar.date(byAdding: .day, value: interval, to: last)
        } else {
            due = nil
        }
        guard let dueDate = due else { return .onTime }

        let bandSeconds = Double(interval) * Self.timingBand * 86_400
        let secondsUntilDue = dueDate.timeIntervalSince(checkInDate)
        if secondsUntilDue > bandSeconds { return .early }
        if secondsUntilDue < -bandSeconds { return .late }
        return .onTime
    }

    // MARK: - Decision table

    /// One row of the design's decision table: the `adj` nudge and the resulting
    /// action + reason.
    private func decide(
        soil: SoilMoisture,
        leaves: LeafState,
        timing: CheckInTiming,
        moisture: MoisturePreference
    ) -> (nudge: Double, action: WateringRecommendation.Action, reason: WateringRecommendation.Reason) {
        // Droopy leaves override everything else — keyed purely on the soil read.
        if leaves == .droopy {
            switch soil {
            case .dry:   return (0.80, .waterNow, .droopyDry)
            case .wet:   return (1.20, .skip, .droopyWet)
            case .moist: return (0.95, .monitor, .droopyMoist)
            }
        }

        // Crispy leaves signal dehydration — water more urgently than droopy
        // (shorten harder), keyed purely on the soil read.
        if leaves == .crispy {
            switch soil {
            case .dry:   return (0.75, .waterNow, .crispyDry)
            case .moist: return (0.85, .waterNow, .crispyMoist)
            case .wet:   return (0.95, .waterLightly, .crispyWet)
            }
        }

        // Leaves fine.
        switch soil {
        case .wet:
            // Still wet — skip and lengthen, especially for dries-out species.
            return (1.15, .skip, .stillWet)

        case .dry:
            if timing == .early {
                // Dried out faster than expected — shorten.
                return (0.85, .waterNow, .driedEarly)
            }
            // On-time or late.
            if moisture == .staysMoist {
                // Don't let a moisture-lover dry out next time — shorten.
                return (0.90, .waterNow, .dontDryOut)
            }
            // Dries-out / evenly-moist on target — hold.
            return (1.0, .waterNow, .onTargetDry)

        case .moist:
            if timing == .early {
                // A touch early but moist — fine to top up; lengthen slightly.
                return (1.05, .waterLightly, .touchEarly)
            }
            // On target — water lightly, hold.
            return (1.0, .waterLightly, .onTargetMoist)
        }
    }

    // MARK: - Clamp

    private func clampedAdj(_ value: Double) -> Double {
        min(max(value, Plant.adjRange.lowerBound), Plant.adjRange.upperBound)
    }
}
