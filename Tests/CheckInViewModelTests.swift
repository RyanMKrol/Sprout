import XCTest
@testable import Sprout

/// Unit tests for the Check-in view model (T011): it runs the pure `AdaptiveEngine`
/// (T010) over a plant's care profile, **persists** the `CheckIn`, writes the nudged
/// `adj` / `lastWatered` / `nextDue` back onto the plant via the repository, and
/// publishes the structured recommendation + updated next-due.
///
/// Backed by a fresh in-memory `PlantRepository` (via `PlantStore.inMemory()`) so the
/// view model is exercised end-to-end through its real persistence boundary. `now` is
/// injected into `submit` so timing, the persisted date, and next-due are deterministic.
@MainActor
final class CheckInViewModelTests: XCTestCase {
    private var repo: PlantRepository!

    /// One species per moisture preference so the decision table can be exercised.
    private let careDatabase = CareDatabase(profiles: [
        CareProfile(species: "Snake Plant", baseIntervalDays: 21, minIntervalDays: 14, maxIntervalDays: 35, moisture: .driesOut),
        CareProfile(species: "Pothos", baseIntervalDays: 10, minIntervalDays: 7, maxIntervalDays: 18, moisture: .evenlyMoist),
        CareProfile(species: "Peace Lily", baseIntervalDays: 7, minIntervalDays: 4, maxIntervalDays: 12, moisture: .staysMoist),
    ])

    /// A fixed reference instant so timing/next-due are deterministic.
    private let now = Date(timeIntervalSinceReferenceDate: 100 * 86_400)
    private let calendar = Calendar.current

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: now)!
    }

    /// Add a plant scheduled with `nextDue` at `dueOffset` days from `now`, returning it.
    @discardableResult
    private func addPlant(species: String, dueOffset: Int, lastWatered: Date? = nil) throws -> Plant {
        let plant = Plant(
            nickname: "Test",
            species: species,
            lastWatered: lastWatered,
            nextDue: day(dueOffset)
        )
        try repo.add(plant)
        return plant
    }

    private func makeVM(_ plantID: UUID) -> CheckInViewModel {
        CheckInViewModel(plantID: plantID, repository: repo, careDatabase: careDatabase)
    }

    // MARK: - Decision table, end-to-end

    func testWetSoilSkipsLengthensAndDoesNotWater() throws {
        let plant = try addPlant(species: "Snake Plant", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .wet
        vm.leaves = .fine
        vm.watered = true // even if they watered, a "skip" never advances the schedule
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.action, .skip)
        XCTAssertEqual(result.recommendation.reason, .stillWet)
        XCTAssertFalse(result.didWater)
        XCTAssertEqual(result.newAdj, 1.15, accuracy: 0.0001) // ×1.15
        // Skip → recheck window, lastWatered unchanged.
        XCTAssertEqual(result.nextDue, day(AdaptiveEngine.recheckDays))

        let stored = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertNil(stored.lastWatered)
        XCTAssertEqual(stored.adj, result.newAdj, accuracy: 0.0001)
        XCTAssertEqual(stored.nextDue, result.nextDue)
    }

    func testDryFineEarlyShortensAndWaters() throws {
        // Due far in the future → checking in now is "early".
        let plant = try addPlant(species: "Pothos", dueOffset: 15)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .dry
        vm.leaves = .fine
        vm.watered = true
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.action, .waterNow)
        XCTAssertEqual(result.recommendation.reason, .driedEarly)
        XCTAssertTrue(result.didWater)
        XCTAssertEqual(result.newAdj, 0.85, accuracy: 0.0001) // ×0.85

        // Watered → lastWatered = now, next-due from the new interval.
        let interval = Int((10.0 * 0.85).rounded()) // 9, within [7,18]
        XCTAssertEqual(result.nextDue, day(interval))
        let stored = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(stored.lastWatered, now)
        XCTAssertEqual(stored.nextDue, result.nextDue)
    }

    func testDryFineOnTimeDriesOutHolds() throws {
        let plant = try addPlant(species: "Snake Plant", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .dry
        vm.leaves = .fine
        vm.watered = true
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.reason, .onTargetDry)
        XCTAssertEqual(result.recommendation.action, .waterNow)
        XCTAssertEqual(result.newAdj, 1.0, accuracy: 0.0001) // hold
        XCTAssertEqual(result.nextDue, day(21)) // base, unchanged
    }

    func testDryFineStaysMoistShortens() throws {
        let plant = try addPlant(species: "Peace Lily", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .dry
        vm.leaves = .fine
        vm.watered = true
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.reason, .dontDryOut)
        XCTAssertEqual(result.newAdj, 0.90, accuracy: 0.0001) // ×0.90
    }

    func testMoistFineOnTimeWatersLightly() throws {
        let plant = try addPlant(species: "Pothos", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .moist
        vm.leaves = .fine
        vm.watered = true
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.action, .waterLightly)
        XCTAssertEqual(result.recommendation.reason, .onTargetMoist)
        XCTAssertEqual(result.newAdj, 1.0, accuracy: 0.0001)
        XCTAssertTrue(result.didWater)
    }

    func testMoistFineEarlyLengthensSlightly() throws {
        let plant = try addPlant(species: "Pothos", dueOffset: 15)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .moist
        vm.leaves = .fine
        vm.watered = true
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.reason, .touchEarly)
        XCTAssertEqual(result.newAdj, 1.05, accuracy: 0.0001) // ×1.05
    }

    func testDroopyDryWatersAndShortens() throws {
        let plant = try addPlant(species: "Pothos", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .dry
        vm.leaves = .droopy
        vm.watered = true
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.action, .waterNow)
        XCTAssertEqual(result.recommendation.reason, .droopyDry)
        XCTAssertEqual(result.newAdj, 0.80, accuracy: 0.0001) // ×0.80
        XCTAssertTrue(result.didWater)
    }

    func testDroopyWetSkipsAndLengthens() throws {
        let plant = try addPlant(species: "Snake Plant", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .wet
        vm.leaves = .droopy
        vm.watered = false
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.action, .skip)
        XCTAssertEqual(result.recommendation.reason, .droopyWet)
        XCTAssertFalse(result.didWater)
        XCTAssertEqual(result.newAdj, 1.20, accuracy: 0.0001) // ×1.20
    }

    func testDroopyMoistMonitors() throws {
        let plant = try addPlant(species: "Pothos", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .moist
        vm.leaves = .droopy
        vm.watered = false
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.action, .monitor)
        XCTAssertEqual(result.recommendation.reason, .droopyMoist)
        XCTAssertFalse(result.didWater)
        XCTAssertEqual(result.newAdj, 0.95, accuracy: 0.0001) // ×0.95
    }

    // MARK: - Persistence

    func testCheckInIsPersistedToHistory() throws {
        let plant = try addPlant(species: "Pothos", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .moist
        vm.leaves = .fine
        vm.watered = true
        vm.submit(now: now)

        let stored = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(stored.checkIns.count, 1)
        let checkIn = try XCTUnwrap(stored.checkIns.first)
        XCTAssertEqual(checkIn.soil, .moist)
        XCTAssertEqual(checkIn.leaves, .fine)
        XCTAssertTrue(checkIn.watered)
        XCTAssertEqual(checkIn.date, now)
    }

    func testRecommendedWaterButUserDidNotWaterDoesNotAdvanceSchedule() throws {
        let plant = try addPlant(species: "Snake Plant", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .dry
        vm.leaves = .fine
        vm.watered = false // recommended to water, but they didn't
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertEqual(result.recommendation.action, .waterNow)
        XCTAssertFalse(result.didWater)
        // No watering → recheck window, lastWatered stays nil.
        XCTAssertEqual(result.nextDue, day(AdaptiveEngine.recheckDays))
        let stored = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertNil(stored.lastWatered)
    }

    // MARK: - Degraded paths

    func testUnknownSpeciesCannotCheckIn() throws {
        let plant = Plant(nickname: "Mystery", species: "Unknown Plant", nextDue: day(0))
        try repo.add(plant)
        let vm = makeVM(plant.id)
        vm.load()

        XCTAssertFalse(vm.canCheckIn)
        vm.submit(now: now)
        XCTAssertNil(vm.result)
        let stored = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertTrue(stored.checkIns.isEmpty)
    }

    func testMissingPlantSetsLoadFailed() {
        let vm = makeVM(UUID())
        vm.load()
        XCTAssertTrue(vm.loadFailed)
        XCTAssertFalse(vm.canCheckIn)

        vm.submit(now: now)
        XCTAssertNil(vm.result)
    }

    func testResultMessageReflectsReason() throws {
        let plant = try addPlant(species: "Snake Plant", dueOffset: 0)
        let vm = makeVM(plant.id)
        vm.load()
        vm.soil = .wet
        vm.leaves = .fine
        vm.submit(now: now)

        let result = try XCTUnwrap(vm.result)
        XCTAssertTrue(result.message.lowercased().contains("wet"))
    }
}
