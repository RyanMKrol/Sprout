import Foundation
import UIKit

/// Drives the **Check-in flow** (T031): from a plant, the user records the three
/// measurable observations — soil (`Dry`/`Moist`/`Wet`), leaves (`Fine`/`Droopy`),
/// and whether they watered — then `submit(now:)` runs the pure `AdaptiveEngine`
/// (T010), **persists** the `CheckIn`, writes the nudged `adj` / `lastWatered` /
/// `nextDue` back onto the plant via the `PlantRepository`, and publishes the
/// structured recommendation plus the updated next-due for the view to render.
///
/// All decision logic stays in the (pure, unit-tested) engine; this view model is
/// the thin, testable wiring between the form inputs, persistence, and the result.
/// `now` is injected into `submit` so the persisted check-in date, the timing
/// classification, and the next-due are deterministic in unit tests.
@MainActor
final class CheckInViewModel: ObservableObject {
    // MARK: Form inputs (user-selected)

    /// Soil reading. Defaults to `moist` — the neutral middle option.
    @Published var soil: SoilMoisture = .moist
    /// Leaf state. Defaults to `fine`.
    @Published var leaves: LeafState = .fine
    /// Whether the user actually watered at this check-in.
    @Published var watered: Bool = false

    // MARK: Loaded plant context

    /// The full plant object loaded from the repository, for display.
    @Published private(set) var plant: Plant?
    /// The plant's nickname, or `""` before a successful `load()`.
    @Published private(set) var nickname: String = ""
    /// The plant's species (its care-database key), or `""` before load.
    @Published private(set) var species: String = ""
    /// The plant's photo as UIImage, if available.
    @Published private(set) var plantPhoto: UIImage?
    /// `true` once the plant **and** its care-database profile resolve — the check-in
    /// needs a profile to run the engine. `false` blocks submission (and the view
    /// shows an unavailable state) rather than guessing a schedule.
    @Published private(set) var canCheckIn: Bool = false

    // MARK: Result

    /// The outcome of a submitted check-in: the structured recommendation, the new
    /// next-due the schedule moved to, and the learned `adj` after the nudge. A
    /// value type so the view *and* the unit tests assert the decision, not a
    /// brittle string. `nil` until `submit` succeeds.
    struct Result: Equatable {
        let recommendation: WateringRecommendation
        /// `lastWatered + interval` when we watered, else `checkIn.date + recheckDays`.
        let nextDue: Date
        /// Whether the schedule advanced (recommended water **and** user watered).
        let didWater: Bool
        /// The learned multiplier after this check-in's nudge.
        let newAdj: Double

        /// Plain-language indication for this recommendation — the design's
        /// per-row text. (The richer "why this schedule" sentence is T012; this is
        /// the immediate confirmation the check-in screen shows.)
        var message: String {
            switch recommendation.reason {
            case .stillWet:
                return "Skip — the soil's still wet. Check back in \(recommendation.days) days."
            case .driedEarly:
                return "Water now — it dried out faster than expected."
            case .onTargetDry:
                return "Water now — right on schedule."
            case .dontDryOut:
                return "Water now — let's not let it dry out next time."
            case .onTargetMoist:
                return "Water lightly — right on schedule."
            case .touchEarly:
                return "A touch early, but fine to top up."
            case .droopyDry:
                return "Water now — the leaves are drooping."
            case .droopyWet:
                return "Leaves droop but the soil's wet — let it dry out; it may be overwatered."
            case .droopyMoist:
                return "Keep an eye on it — check back in \(recommendation.days) days."
            }
        }
    }

    /// The recommendation + updated schedule, set when `submit` succeeds.
    @Published private(set) var result: Result?
    /// `true` if the plant could not be loaded or persistence failed — the view
    /// degrades to an error state instead of crashing.
    @Published private(set) var loadFailed: Bool = false

    let plantID: UUID
    private let repository: PlantRepository
    private let careDatabase: CareDatabase
    private let engine: AdaptiveEngine
    /// The plant's room environment multiplier (T212), fed into the adaptive
    /// recompute so a watering advances the schedule at the room's cadence. Neutral
    /// (`1.0`) when the plant has no room; `ContentView` injects the room factor.
    private let environmentFactor: Double

    init(
        plantID: UUID,
        repository: PlantRepository,
        careDatabase: CareDatabase,
        engine: AdaptiveEngine = AdaptiveEngine(),
        environmentFactor: Double = ScheduleEngine.defaultWeatherFactor
    ) {
        self.plantID = plantID
        self.repository = repository
        self.careDatabase = careDatabase
        self.engine = engine
        self.environmentFactor = environmentFactor
    }

    /// Load the plant and resolve its care profile so the form can show the plant's
    /// name and know whether a check-in can run. A missing plant or an unknown
    /// species (no care record) sets the appropriate flag rather than crashing.
    func load() {
        guard let loadedPlant = (try? repository.plant(id: plantID)) ?? nil else {
            loadFailed = true
            canCheckIn = false
            return
        }
        loadFailed = false
        plant = loadedPlant
        nickname = loadedPlant.nickname
        species = loadedPlant.species
        canCheckIn = careDatabase.profile(forSpecies: loadedPlant.species) != nil

        if let photoData = loadedPlant.photoData {
            plantPhoto = UIImage(data: photoData)
        }
    }

    /// Run the check-in: build the `CheckIn` from the form inputs at `now`, apply the
    /// adaptive engine, persist the check-in, write the learned state back onto the
    /// plant, and publish the `Result`. No-op (sets `loadFailed`) if the plant or its
    /// profile can't be resolved or persistence fails — so the screen never advances
    /// to a result it didn't actually save.
    func submit(now: Date = Date()) {
        guard
            let loadedPlant = (try? repository.plant(id: plantID)) ?? nil,
            let profile = careDatabase.profile(forSpecies: loadedPlant.species)
        else {
            loadFailed = true
            canCheckIn = false
            return
        }

        let checkIn = CheckIn(date: now, soil: soil, leaves: leaves, watered: watered)
        let update = engine.update(profile: profile, plant: loadedPlant, checkIn: checkIn, weatherFactor: environmentFactor)

        var updated = loadedPlant
        updated.adj = update.newAdj
        updated.lastWatered = update.lastWatered
        updated.nextDue = update.nextDue

        do {
            try repository.addCheckIn(checkIn, toPlant: loadedPlant.id)
            try repository.update(updated)
        } catch {
            loadFailed = true
            return
        }

        result = Result(
            recommendation: update.recommendation,
            nextDue: update.nextDue,
            didWater: update.didWater,
            newAdj: update.newAdj
        )
    }

    /// `true` once a check-in has been submitted and a recommendation is showing.
    var hasResult: Bool { result != nil }
}
