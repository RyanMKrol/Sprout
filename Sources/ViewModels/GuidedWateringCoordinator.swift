import Foundation

/// Drives the **guided watering** walkthrough (T215): steps through an ordered list
/// of plants one at a time. For each, the user reports soil + leaves; `preview()`
/// runs the adaptive engine to show a water/skip recommendation **without
/// persisting**, then `confirm(watered:)` records the real check-in (same path as
/// `CheckInViewModel.submit`) and advances. `skip()` moves on without a check-in.
///
/// Two modes select the plant set (built by `ContentView`): a full check-in over all
/// plants, or just the plants that are due. All logic is here behind the
/// `PhotoCapturing`-free engine seam, so it's unit-tested with an in-memory repo.
@MainActor
final class GuidedWateringCoordinator: ObservableObject {
    /// Which plants the walkthrough covers.
    enum Mode { case due, all }

    let plants: [Plant]
    /// The user's report for the current plant.
    @Published var soil: SoilMoisture = .moist
    @Published var leaves: LeafState = .fine
    /// Index of the plant being checked; equals `plants.count` once finished.
    @Published private(set) var index: Int = 0
    /// The previewed recommendation for the current plant (set by `preview()`,
    /// cleared on advance). `nil` while still reporting.
    @Published private(set) var recommendation: WateringRecommendation?
    @Published private(set) var isFinished: Bool = false

    private let repository: PlantRepository
    private let careDatabase: CareDatabase
    private let engine: AdaptiveEngine
    private let environmentFactor: (Plant) -> Double

    init(
        plants: [Plant],
        repository: PlantRepository,
        careDatabase: CareDatabase,
        engine: AdaptiveEngine = AdaptiveEngine(),
        environmentFactor: @escaping (Plant) -> Double = { _ in ScheduleEngine.defaultWeatherFactor }
    ) {
        self.plants = plants
        self.repository = repository
        self.careDatabase = careDatabase
        self.engine = engine
        self.environmentFactor = environmentFactor
        if plants.isEmpty { isFinished = true }
    }

    // MARK: - Presentation

    /// The plant currently being checked, or `nil` when finished.
    var current: Plant? { index < plants.count ? plants[index] : nil }

    var progressText: String {
        guard !plants.isEmpty else { return "" }
        return "\(min(index + 1, plants.count)) of \(plants.count)"
    }

    /// `true` once `preview()` has produced a recommendation for the current plant.
    var hasRecommendation: Bool { recommendation != nil }

    /// Whether the current recommendation tells the user to water (vs skip/monitor).
    var recommendsWater: Bool { recommendation?.action.recommendsWater ?? false }

    /// A plain-language line for the previewed recommendation.
    var message: String {
        guard let recommendation else { return "" }
        switch recommendation.reason {
        case .stillWet: return "Skip — the soil's still wet. Check back in \(recommendation.days) days."
        case .driedEarly: return "Water now — it dried out faster than expected."
        case .onTargetDry: return "Water now — right on schedule."
        case .dontDryOut: return "Water now — this one likes to stay moist."
        case .onTargetMoist: return "A light water — it's on track."
        case .touchEarly: return "A light top-up — a touch early but fine."
        case .droopyDry: return "Water now — it's drooping and dry."
        case .droopyWet: return "Skip — drooping but the soil's wet; let it dry out."
        case .droopyMoist: return "Hold off — keep an eye on it."
        }
    }

    // MARK: - Actions

    /// Compute (but don't persist) the recommendation for the current plant from the
    /// reported soil/leaves, so the user sees water/skip before deciding.
    func preview(now: Date = Date()) {
        guard
            let plant = current,
            let profile = careDatabase.profile(forSpecies: plant.species)
        else {
            recommendation = nil
            return
        }
        let checkIn = CheckIn(date: now, soil: soil, leaves: leaves, watered: false)
        let update = engine.update(profile: profile, plant: plant, checkIn: checkIn, weatherFactor: environmentFactor(plant))
        recommendation = update.recommendation
    }

    /// Record the real check-in for the current plant (persisting + recomputing its
    /// schedule, like `CheckInViewModel.submit`) and advance.
    func confirm(watered: Bool, now: Date = Date()) {
        defer { advance() }
        guard
            let plant = current,
            let profile = careDatabase.profile(forSpecies: plant.species)
        else { return }
        let checkIn = CheckIn(date: now, soil: soil, leaves: leaves, watered: watered)
        let update = engine.update(profile: profile, plant: plant, checkIn: checkIn, weatherFactor: environmentFactor(plant))
        try? repository.addCheckIn(checkIn, toPlant: plant.id)
        var updated = plant
        updated.adj = update.newAdj
        updated.lastWatered = update.lastWatered
        updated.nextDue = update.nextDue
        try? repository.update(updated)
    }

    /// Move on without recording a check-in for the current plant.
    func skip() { advance() }

    private func advance() {
        recommendation = nil
        soil = .moist
        leaves = .fine
        if index + 1 >= plants.count {
            index = plants.count
            isFinished = true
        } else {
            index += 1
        }
    }
}
