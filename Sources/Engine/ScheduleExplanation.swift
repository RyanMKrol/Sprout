import Foundation

/// A plain-language **"why this schedule"** explanation (T012). Built **purely**
/// from the schedule inputs — the species' base cadence, the computed effective
/// interval, the learned `adj`, the (injected) `weatherFactor`, and the most recent
/// check-in — so the resulting sentence is asserted directly in unit tests rather
/// than scraped out of a view.
///
/// As elsewhere in the engine, the *structured* value (direction + cause + day
/// counts) is what the tests assert; the human-readable `sentence` / `pillSummary`
/// strings are derived from it. This mirrors the "structured decision, not a brittle
/// string" pattern the schedule (T009) and adaptive (T010) engines use.
struct ScheduleExplanation: Equatable, Sendable {
    /// How the effective interval compares to the species' seed cadence.
    enum Direction: Equatable, Sendable {
        /// Effective `< base` — Sprout waters more often than the seed cadence.
        case shortened
        /// Effective `> base` — Sprout waters less often than the seed cadence.
        case lengthened
        /// Effective `== base` — sitting on the seed cadence.
        case unchanged
    }

    /// The dominant influence on where the schedule currently sits. One case per
    /// distinct plain-language reason, so a unit-test table asserts the *decision*.
    enum Cause: Equatable, Sendable {
        /// Last check-in found dry soil (leaves fine) — it dries out faster.
        case driedOut
        /// Last check-in found wet soil (leaves fine) — it stays wet longer.
        case stayedWet
        /// Last check-in found moist soil (leaves fine) — a gentle nudge.
        case stillMoist
        /// Last check-in: droopy leaves over dry/moist soil — needs water sooner.
        case drooping
        /// Last check-in: droopy leaves over wet soil — looked overwatered.
        case overwatered
        /// A warm spell pulled the interval in (`weatherFactor < 1`). Wired for T016.
        case warmSpell
        /// A cold spell stretched the interval out (`weatherFactor > 1`). Wired for T016.
        case coldSpell
        /// No check-ins yet and neutral weather — the species' starting cadence.
        case startingCadence
        /// Learned cadence has settled back onto the species seed (`adj ≈ 1`, with history).
        case settled
    }

    /// The plant's species (its care-database key) — woven into the sentence.
    var species: String
    /// The current effective interval in days (what Sprout actually schedules to).
    var effectiveDays: Int
    /// The species' seed cadence in days, for the "shortened from N" comparison.
    var baseDays: Int
    var direction: Direction
    var cause: Cause

    /// The full sentence shown on the Plant Detail screen, e.g.
    /// *"Every 5 days — shortened from 6 because it dried out faster than expected."*
    var sentence: String {
        let every = "Every \(effectiveDays) \(Self.dayWord(effectiveDays))"
        switch direction {
        case .unchanged:
            switch cause {
            case .startingCadence:
                return "\(every) — the starting cadence for \(species)."
            case .settled:
                return "\(every) — settled back to its usual cadence."
            default:
                return "\(every) — holding at \(species)'s usual cadence."
            }
        case .shortened, .lengthened:
            let verb = direction == .shortened ? "shortened" : "stretched"
            return "\(every) — \(verb) from \(baseDays) because \(causeClause)."
        }
    }

    /// A compact summary for the My Plants list card, e.g. *"Every 5d · shortened"*.
    var pillSummary: String {
        let stem = "Every \(effectiveDays)d"
        switch direction {
        case .shortened: return "\(stem) · shortened"
        case .lengthened: return "\(stem) · stretched"
        case .unchanged: return stem
        }
    }

    /// The "because …" fragment, naming the cause in plain language.
    private var causeClause: String {
        switch cause {
        case .driedOut: return "it dried out faster than expected"
        case .stayedWet: return "the soil was still wet last time"
        case .stillMoist: return "the soil was still moist last time"
        case .drooping: return "its leaves were drooping"
        case .overwatered: return "it looked overwatered"
        case .warmSpell: return "of a warm spell"
        case .coldSpell: return "of a cold spell"
        case .startingCadence, .settled: return "of your check-ins"
        }
    }

    private static func dayWord(_ days: Int) -> String { days == 1 ? "day" : "days" }
}

/// Pure builder that maps the schedule inputs to a `ScheduleExplanation`. Holds no
/// state beyond an (injectable) `ScheduleEngine`, so the same effective-interval
/// rounding/clamping the rest of the app uses also drives the explanation.
struct ScheduleExplanationBuilder {
    private let schedule: ScheduleEngine

    init(schedule: ScheduleEngine = ScheduleEngine()) {
        self.schedule = schedule
    }

    /// Build the explanation for a plant of species `profile` with learned `adj`,
    /// optionally informed by its most recent `lastCheckIn` and the current
    /// `weatherFactor` (1.0 until T015/T016 feed a real forecast).
    func explanation(
        species: String,
        profile: CareProfile,
        adj: Double,
        lastCheckIn: CheckIn?,
        weatherFactor: Double = ScheduleEngine.defaultWeatherFactor
    ) -> ScheduleExplanation {
        let effective = schedule.effectiveInterval(for: profile, adj: adj, weatherFactor: weatherFactor)
        let base = profile.baseIntervalDays

        let direction: ScheduleExplanation.Direction
        if effective < base {
            direction = .shortened
        } else if effective > base {
            direction = .lengthened
        } else {
            direction = .unchanged
        }

        let cause = chooseCause(adj: adj, weatherFactor: weatherFactor, lastCheckIn: lastCheckIn)

        return ScheduleExplanation(
            species: species,
            effectiveDays: effective,
            baseDays: base,
            direction: direction,
            cause: cause
        )
    }

    /// Pick the dominant influence. A recent check-in that actually moved the learned
    /// `adj` explains the schedule first; otherwise an off-neutral `weatherFactor`
    /// does (the hook T016 leans on); otherwise it's the seed cadence (or a settled
    /// one if there's history).
    private func chooseCause(
        adj: Double,
        weatherFactor: Double,
        lastCheckIn: CheckIn?
    ) -> ScheduleExplanation.Cause {
        let adjMoved = abs(adj - Plant.defaultAdj) > 0.0001
        if let last = lastCheckIn, adjMoved {
            return causeFromCheckIn(last)
        }
        if weatherFactor < 1.0 { return .warmSpell }
        if weatherFactor > 1.0 { return .coldSpell }
        return lastCheckIn == nil ? .startingCadence : .settled
    }

    /// Map a check-in's measurable observation to the matching cause — mirroring the
    /// adaptive decision table's groupings (droopy overrides, then soil).
    private func causeFromCheckIn(_ checkIn: CheckIn) -> ScheduleExplanation.Cause {
        if checkIn.leaves == .droopy {
            return checkIn.soil == .wet ? .overwatered : .drooping
        }
        switch checkIn.soil {
        case .dry: return .driedOut
        case .wet: return .stayedWet
        case .moist: return .stillMoist
        }
    }
}
