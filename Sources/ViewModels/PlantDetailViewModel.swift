import Foundation

/// Drives the **Plant Detail** screen (T008). Loads a single plant from the
/// `PlantRepository` (T005) and projects it into the display state the detail
/// view renders: its name/species, the current watering schedule (a **placeholder
/// summary until the schedule engine lands in T009**), and its chronological
/// check-in history — most-recent first.
///
/// All loading/ordering/derivation lives here behind a plain, testable surface:
/// `load(now:)` takes an injected `now` so the relative due text is deterministic
/// in unit tests, and the view depends on this view model rather than on the
/// repository / care database directly.
@MainActor
final class PlantDetailViewModel: ObservableObject {
    /// One row of check-in history, projected from a `CheckIn`. Carries the
    /// structured observation (soil / leaves / watered) so the view *and* the unit
    /// tests assert the decision, not a brittle formatted string.
    struct HistoryItem: Identifiable, Equatable {
        let id: UUID
        let date: Date
        let soil: SoilMoisture
        let leaves: LeafState
        let watered: Bool
    }

    /// The plant's nickname, or `""` before a successful load.
    @Published private(set) var nickname: String = ""
    /// The plant's species (its care-database key), or `""` before load.
    @Published private(set) var species: String = ""
    /// Relative watering status, derived from `nextDue` versus the injected `now`.
    @Published private(set) var due: DueStatus = .unscheduled
    /// The species' starting cadence in days (from the care DB), if the species
    /// resolves to a record — shown in the schedule placeholder. `nil` otherwise.
    @Published private(set) var baseIntervalDays: Int?
    /// The "why this schedule" explanation (T012), built from the species' care
    /// profile, the plant's learned `adj`, and its most recent check-in. `nil` when
    /// the species has no care record to anchor the cadence.
    @Published private(set) var explanation: ScheduleExplanation?
    /// Check-in history, **most-recent first** (the repository returns it oldest
    /// first). Empty drives the history empty state.
    @Published private(set) var history: [HistoryItem] = []
    /// `true` if the requested plant could not be loaded (deleted / unknown id).
    @Published private(set) var loadFailed: Bool = false

    let plantID: UUID
    private let repository: PlantRepository
    private let careDatabase: CareDatabase
    private let explanationBuilder: ScheduleExplanationBuilder
    /// The current weather multiplier fed into the "why" explanation (T016), so a
    /// warm/cold spell surfaces in the sentence. Neutral (`1.0`) until weather is
    /// wired in; `ContentView` injects the forecast-derived factor.
    private let weatherFactor: Double

    init(
        plantID: UUID,
        repository: PlantRepository,
        careDatabase: CareDatabase,
        explanationBuilder: ScheduleExplanationBuilder = ScheduleExplanationBuilder(),
        weatherFactor: Double = ScheduleEngine.defaultWeatherFactor
    ) {
        self.plantID = plantID
        self.repository = repository
        self.careDatabase = careDatabase
        self.explanationBuilder = explanationBuilder
        self.weatherFactor = weatherFactor
    }

    /// Load (or reload) the plant and its history from the repository. A missing
    /// plant or repository error sets `loadFailed` and clears the display state
    /// rather than crashing the UI.
    func load(now: Date = Date()) {
        guard let plant = (try? repository.plant(id: plantID)) ?? nil else {
            loadFailed = true
            nickname = ""
            species = ""
            due = .unscheduled
            baseIntervalDays = nil
            explanation = nil
            history = []
            return
        }
        loadFailed = false
        nickname = plant.nickname
        species = plant.species
        due = DueStatus(nextDue: plant.nextDue, now: now)

        let profile = careDatabase.profile(forSpecies: plant.species)
        baseIntervalDays = profile?.baseIntervalDays
        explanation = profile.map { profile in
            explanationBuilder.explanation(
                species: plant.species,
                profile: profile,
                adj: plant.adj,
                lastCheckIn: plant.checkIns.max { $0.date < $1.date },
                weatherFactor: weatherFactor
            )
        }

        history = plant.checkIns
            .sorted { $0.date > $1.date }
            .map { HistoryItem(id: $0.id, date: $0.date, soil: $0.soil, leaves: $0.leaves, watered: $0.watered) }
    }

    /// `true` when the plant has no check-ins yet — the view shows a history
    /// empty state inviting the first check-in (the flow itself arrives in T011).
    var hasHistory: Bool { !history.isEmpty }

    /// Plain-language schedule summary. **Placeholder until T009** wires the real
    /// adaptive engine: it reports the species' starting cadence and the relative
    /// next-due, with an explicit note that the adaptive schedule is still to come.
    var scheduleSummary: String {
        guard let baseIntervalDays else {
            return "Watering schedule coming soon."
        }
        let cadence = "Every ~\(baseIntervalDays) \(baseIntervalDays == 1 ? "day" : "days") (starting cadence)"
        return "\(cadence) · \(due.label)"
    }
}
