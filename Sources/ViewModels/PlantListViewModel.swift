import Foundation

/// Relative watering status for a plant, derived from its `nextDue` date versus
/// "now". A small value type (an enum case + day count) so the list pill text
/// *and* the unit tests assert the *decision*, not a brittle string — the same
/// pattern the engine tasks (T009/T010) use for their recommendations.
enum DueStatus: Equatable {
    /// No `nextDue` yet — the plant has never been scheduled (e.g. just added).
    case unscheduled
    /// Watering was due `days` calendar days ago (`days ≥ 1`).
    case overdue(days: Int)
    /// Watering is due today.
    case dueToday
    /// Watering is due in `days` calendar days (`days ≥ 1`).
    case due(days: Int)

    /// Classify a plant's `nextDue` against `now`, comparing **calendar days**
    /// (start-of-day to start-of-day) so "due today" doesn't hinge on the clock
    /// time. `nil` `nextDue` is `.unscheduled`.
    init(nextDue: Date?, now: Date, calendar: Calendar = .current) {
        guard let nextDue else {
            self = .unscheduled
            return
        }
        let startNow = calendar.startOfDay(for: now)
        let startDue = calendar.startOfDay(for: nextDue)
        let days = calendar.dateComponents([.day], from: startNow, to: startDue).day ?? 0
        if days == 0 {
            self = .dueToday
        } else if days < 0 {
            self = .overdue(days: -days)
        } else {
            self = .due(days: days)
        }
    }

    /// Short, human-readable pill label, e.g. "Due today", "Due in 3 days",
    /// "Overdue by 1 day", "No schedule".
    var label: String {
        switch self {
        case .unscheduled:
            return "No schedule"
        case .dueToday:
            return "Due today"
        case let .due(days):
            return "Due in \(days) \(Self.dayWord(days))"
        case let .overdue(days):
            return "Overdue by \(days) \(Self.dayWord(days))"
        }
    }

    /// `true` when the plant needs water now or is past due — drives the pill /
    /// water-drop emphasis in the list.
    var needsWater: Bool {
        switch self {
        case .dueToday, .overdue:
            return true
        case .due, .unscheduled:
            return false
        }
    }

    private static func dayWord(_ days: Int) -> String { days == 1 ? "day" : "days" }
}

/// Drives the **My Plants** home list (T006). Loads plants from the repository,
/// orders them by watering urgency (soonest-due first), and projects each into a
/// small `Item` of display state.
///
/// All ordering and due-date logic lives here behind a plain, testable surface:
/// `load(now:)` takes an injected `now` so the relative due text is deterministic
/// in unit tests, and the view depends on this view model rather than on the
/// `PlantRepository` directly.
@MainActor
final class PlantListViewModel: ObservableObject {
    /// One card's worth of display state, derived from a `Plant`.
    struct Item: Identifiable, Equatable {
        let id: UUID
        let nickname: String
        let species: String
        let due: DueStatus
        /// Compact "why this schedule" summary (T012), e.g. *"Every 5d · shortened"*.
        /// `nil` when no care database is wired in or the species has no record.
        let whySummary: String?
        /// The plant's photo (JPEG bytes), shown as a card thumbnail (T214). `nil` → leaf placeholder.
        let photoData: Data?
    }

    /// Number of plants that need water now (due today or overdue) — drives the home
    /// "Water" tile's count (T214).
    var dueCount: Int { items.filter { $0.due.needsWater }.count }

    /// The plants to display, already in due-order. Empty drives the first-run
    /// empty state (`isEmpty`).
    @Published private(set) var items: [Item] = []

    private let repository: PlantRepository
    /// Optional care database — when wired in, each card carries a compact
    /// "why this schedule" summary (T012). Defaults to `nil` so contexts that only
    /// need the list (e.g. early tests) keep working unchanged.
    private let careDatabase: CareDatabase?
    private let explanationBuilder: ScheduleExplanationBuilder
    /// Resolves a plant's room environment factor (T212) so the card's "why" summary
    /// reflects its room. Defaults to neutral so contexts without rooms are unchanged.
    private let environmentFactor: (Plant) -> Double

    init(
        repository: PlantRepository,
        careDatabase: CareDatabase? = nil,
        explanationBuilder: ScheduleExplanationBuilder = ScheduleExplanationBuilder(),
        environmentFactor: @escaping (Plant) -> Double = { _ in ScheduleEngine.defaultWeatherFactor }
    ) {
        self.repository = repository
        self.careDatabase = careDatabase
        self.explanationBuilder = explanationBuilder
        self.environmentFactor = environmentFactor
    }

    /// `true` when there are no plants — the view shows the first-run empty state.
    var isEmpty: Bool { items.isEmpty }

    /// Reload from the repository, ordered soonest-due first (unscheduled last).
    /// Repository errors degrade to an empty list rather than crashing the UI.
    func load(now: Date = Date()) {
        let plants = (try? repository.allPlants()) ?? []
        items = Self.ordered(plants).map { plant in
            Item(
                id: plant.id,
                nickname: plant.nickname,
                species: plant.species,
                due: DueStatus(nextDue: plant.nextDue, now: now),
                whySummary: whySummary(for: plant),
                photoData: plant.photoData
            )
        }
    }

    /// The compact "why" summary for a plant's card, or `nil` when no care database
    /// is wired in or the species has no record to anchor a cadence.
    private func whySummary(for plant: Plant) -> String? {
        guard
            let careDatabase,
            let profile = careDatabase.profile(forSpecies: plant.species)
        else { return nil }
        return explanationBuilder.explanation(
            species: plant.species,
            profile: profile,
            adj: plant.adj,
            lastCheckIn: plant.checkIns.max { $0.date < $1.date },
            environmentFactor: environmentFactor(plant)
        ).pillSummary
    }

    /// Plants in due-order: earliest `nextDue` first; unscheduled plants (no
    /// `nextDue`) last; nickname (case-insensitive) as a stable tie-breaker.
    static func ordered(_ plants: [Plant]) -> [Plant] {
        plants.sorted { lhs, rhs in
            switch (lhs.nextDue, rhs.nextDue) {
            case let (l?, r?):
                if l != r { return l < r }
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                break
            }
            return lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname) == .orderedAscending
        }
    }
}
