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
    @Published private(set) var due: WateringDueStatus = .unscheduled
    /// The species' starting cadence in days (from the care DB), if the species
    /// resolves to a record — shown in the schedule placeholder. `nil` otherwise.
    @Published private(set) var baseIntervalDays: Int?
    /// Minimum watering interval in days from the care profile's minimum interval.
    @Published private(set) var minDays: Int = 1
    /// Maximum watering interval in days from the care profile's maximum interval.
    @Published private(set) var maxDays: Int = 30
    /// Base watering interval (species starting cadence) in days.
    @Published private(set) var baseDays: Int?
    /// Effective (current) watering interval in days, derived from nextDue.
    @Published private(set) var effectiveDays: Int = 7
    /// The "why this schedule" explanation (T012), built from the species' care
    /// profile, the plant's learned `adj`, and its most recent check-in. `nil` when
    /// the species has no care record to anchor the cadence.
    @Published private(set) var explanation: ScheduleExplanation?
    /// Check-in history, **most-recent first** (the repository returns it oldest
    /// first). Empty drives the history empty state.
    @Published private(set) var history: [HistoryItem] = []
    /// The plant's photo (JPEG bytes), shown as a header image (T214). `nil` → placeholder.
    @Published private(set) var photoData: Data?
    /// `true` if the requested plant could not be loaded (deleted / unknown id).
    @Published private(set) var loadFailed: Bool = false

    let plantID: UUID
    private let repository: PlantRepository
    private let careDatabase: CareDatabase
    private let explanationBuilder: ScheduleExplanationBuilder
    /// The plant's room environment multiplier (T212), fed into the "why" explanation
    /// so a bright/dry or dim/humid spot surfaces in the sentence. Neutral (`1.0`)
    /// when the plant has no room; `ContentView` injects the room-derived factor.
    private let environmentFactor: Double

    init(
        plantID: UUID,
        repository: PlantRepository,
        careDatabase: CareDatabase,
        explanationBuilder: ScheduleExplanationBuilder = ScheduleExplanationBuilder(),
        environmentFactor: Double = ScheduleEngine.defaultWeatherFactor
    ) {
        self.plantID = plantID
        self.repository = repository
        self.careDatabase = careDatabase
        self.explanationBuilder = explanationBuilder
        self.environmentFactor = environmentFactor
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
            minDays = 1
            maxDays = 30
            baseDays = nil
            effectiveDays = 7
            explanation = nil
            history = []
            photoData = nil
            return
        }
        loadFailed = false
        nickname = plant.nickname
        species = plant.species
        photoData = plant.photoData
        due = WateringDueStatus(nextDue: plant.nextDue, now: now)

        let profile = careDatabase.profile(forSpecies: plant.species)
        baseIntervalDays = profile?.baseIntervalDays
        minDays = profile?.minIntervalDays ?? 1
        maxDays = profile?.maxIntervalDays ?? 30
        baseDays = profile?.baseIntervalDays

        // Calculate effective days from nextDue
        if let nextDue = plant.nextDue {
            let calendar = Calendar.current
            let nextDueStart = calendar.startOfDay(for: nextDue)
            let nowStart = calendar.startOfDay(for: now)
            let days = calendar.dateComponents([.day], from: nowStart, to: nextDueStart).day ?? 0
            effectiveDays = max(1, days)
        } else {
            effectiveDays = profile?.baseIntervalDays ?? 7
        }

        explanation = profile.map { profile in
            explanationBuilder.explanation(
                species: plant.species,
                profile: profile,
                adj: plant.adj,
                lastCheckIn: plant.checkIns.max { $0.date < $1.date },
                environmentFactor: environmentFactor
            )
        }

        history = plant.checkIns
            .sorted { $0.date > $1.date }
            .map { HistoryItem(id: $0.id, date: $0.date, soil: $0.soil, leaves: $0.leaves, watered: $0.watered) }
    }

    /// `true` when the plant has no check-ins yet — the view shows a history
    /// empty state inviting the first check-in (the flow itself arrives in T011).
    var hasHistory: Bool { !history.isEmpty }

    /// A sensible starting value for the manual "due in N days" wheel: the days left
    /// until due (0 if due today / overdue), or the species' starting cadence (falling
    /// back to a week) when the plant has never been scheduled.
    var daysUntilDue: Int {
        switch due {
        case let .due(days): return days
        case .dueToday, .overdue: return 0
        case .unscheduled: return baseIntervalDays ?? 7
        }
    }

    /// Manually override the schedule: set the next-watering date to `days` calendar
    /// days from today (anchored to the start of the day, matching `WateringDueStatus`), persist
    /// it, and reload. Lets the user tweak the cadence by hand from the detail screen.
    func setDueInDays(_ days: Int, now: Date = Date(), calendar: Calendar = .current) {
        guard var plant = (try? repository.plant(id: plantID)) ?? nil else { return }
        let start = calendar.startOfDay(for: now)
        plant.nextDue = calendar.date(byAdding: .day, value: max(0, days), to: start) ?? now
        try? repository.update(plant)
        load(now: now)
    }

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
