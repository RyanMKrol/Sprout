import XCTest
@testable import Sprout

/// Unit tests for the Plant Detail view model (T008): it loads a plant and its
/// check-in history from the repository, derives the due status against an injected
/// `now`, orders history most-recent first, resolves the species' base interval from
/// the care DB, and degrades gracefully when the plant is missing.
///
/// Backed by a fresh in-memory `PlantRepository` (via `PlantStore.inMemory()`) so
/// the view model is exercised through its real persistence boundary.
@MainActor
final class PlantDetailViewModelTests: XCTestCase {
    private var repo: PlantRepository!

    /// A small care DB so the schedule placeholder can resolve a base interval.
    private let careDatabase = CareDatabase(profiles: [
        CareProfile(species: "Peace Lily", baseIntervalDays: 7, minIntervalDays: 4, maxIntervalDays: 12, moisture: .staysMoist),
        CareProfile(species: "Snake Plant", baseIntervalDays: 21, minIntervalDays: 14, maxIntervalDays: 35, moisture: .driesOut),
    ])

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    /// A fixed reference instant (2001-01-10 00:00 UTC) so relative due text is
    /// deterministic regardless of when the test runs.
    private let now = Date(timeIntervalSinceReferenceDate: 9 * 86_400)

    private func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: now)!
    }

    // MARK: load

    func testLoadsPlantSpeciesAndDue() throws {
        let plant = Plant(nickname: "Lily", species: "Peace Lily", nextDue: day(-1))
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertFalse(vm.loadFailed)
        XCTAssertEqual(vm.nickname, "Lily")
        XCTAssertEqual(vm.species, "Peace Lily")
        XCTAssertEqual(vm.due, .overdue(days: 1))
        XCTAssertEqual(vm.baseIntervalDays, 7)
    }

    func testUnscheduledPlantHasUnscheduledDueAndNoHistory() throws {
        let plant = Plant(nickname: "New", species: "Snake Plant")
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertEqual(vm.due, .unscheduled)
        XCTAssertFalse(vm.hasHistory)
        XCTAssertTrue(vm.history.isEmpty)
        XCTAssertEqual(vm.baseIntervalDays, 21)
    }

    // MARK: manual schedule override

    func testDaysUntilDueReflectsDueStatusAndFallsBackToBaseInterval() throws {
        let scheduled = Plant(nickname: "Lily", species: "Peace Lily", nextDue: day(3))
        try repo.add(scheduled)
        let vmScheduled = PlantDetailViewModel(plantID: scheduled.id, repository: repo, careDatabase: careDatabase)
        vmScheduled.load(now: now)
        XCTAssertEqual(vmScheduled.daysUntilDue, 3)

        // Never-scheduled → the species' starting cadence.
        let fresh = Plant(nickname: "New", species: "Snake Plant")
        try repo.add(fresh)
        let vmFresh = PlantDetailViewModel(plantID: fresh.id, repository: repo, careDatabase: careDatabase)
        vmFresh.load(now: now)
        XCTAssertEqual(vmFresh.daysUntilDue, 21)
    }

    func testSetDueInDaysOverridesScheduleAndPersists() throws {
        let plant = Plant(nickname: "Lily", species: "Peace Lily", nextDue: day(-1))
        try repo.add(plant)
        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)
        XCTAssertEqual(vm.due, .overdue(days: 1))

        vm.setDueInDays(5, now: now)

        XCTAssertEqual(vm.due, .due(days: 5))
        // Persisted to the repository, not just the view model.
        let saved = try XCTUnwrap(try repo.plant(id: plant.id))
        XCTAssertEqual(WateringDueStatus(nextDue: saved.nextDue, now: now), .due(days: 5))
    }

    // MARK: check-in history

    func testHistoryIsOrderedMostRecentFirst() throws {
        let oldest = CheckIn(date: day(-10), soil: .dry, leaves: .droopy, watered: true)
        let middle = CheckIn(date: day(-5), soil: .moist, leaves: .fine, watered: false)
        let newest = CheckIn(date: day(-1), soil: .wet, leaves: .fine, watered: false)
        // Insert out of chronological order to prove the view model sorts.
        let plant = Plant(nickname: "Lily", species: "Peace Lily", checkIns: [middle, newest, oldest])
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertTrue(vm.hasHistory)
        XCTAssertEqual(vm.history.map(\.id), [newest.id, middle.id, oldest.id])
        XCTAssertEqual(vm.history.map(\.soil), [.wet, .moist, .dry])
        XCTAssertEqual(vm.history.first?.watered, false)
        XCTAssertEqual(vm.history.last?.leaves, .droopy)
    }

    func testHistoryReflectsCheckInsAppendedViaRepository() throws {
        let plant = Plant(nickname: "Lily", species: "Peace Lily")
        try repo.add(plant)
        try repo.addCheckIn(CheckIn(date: day(-3), soil: .dry, leaves: .fine, watered: true), toPlant: plant.id)
        try repo.addCheckIn(CheckIn(date: day(-1), soil: .moist, leaves: .fine, watered: false), toPlant: plant.id)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertEqual(vm.history.count, 2)
        XCTAssertEqual(vm.history.first?.soil, .moist)
    }

    // MARK: schedule placeholder

    func testScheduleSummaryReportsCadenceAndDue() throws {
        let plant = Plant(nickname: "Lily", species: "Peace Lily", nextDue: day(3))
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertTrue(vm.scheduleSummary.contains("Every ~7 days"))
        XCTAssertTrue(vm.scheduleSummary.contains("Due in 3 days"))
    }

    func testScheduleSummaryWithoutCareRecordFallsBack() throws {
        // A species not in the care DB → no base interval to report.
        let plant = Plant(nickname: "Mystery", species: "Unknown Plant", nextDue: day(1))
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertNil(vm.baseIntervalDays)
        XCTAssertEqual(vm.scheduleSummary, "Watering schedule coming soon.")
    }

    // MARK: rhythm inputs

    func testRhythmInputsExposedFromCareProfile() throws {
        let plant = Plant(nickname: "Lily", species: "Peace Lily", nextDue: day(3))
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertEqual(vm.minDays, 4)
        XCTAssertEqual(vm.maxDays, 12)
        XCTAssertEqual(vm.baseDays, 7)
        XCTAssertEqual(vm.effectiveDays, 3)
    }

    func testEffectiveDaysCalculatedFromNextDue() throws {
        let plant = Plant(nickname: "Snake", species: "Snake Plant", nextDue: day(5))
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        // Effective should be 5 days from now
        XCTAssertEqual(vm.effectiveDays, 5)
        XCTAssertEqual(vm.baseDays, 21)
    }

    func testRhythmInputsWithoutCareProfile() throws {
        let plant = Plant(nickname: "Mystery", species: "Unknown Plant", nextDue: day(7))
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertEqual(vm.minDays, 1)
        XCTAssertEqual(vm.maxDays, 30)
        XCTAssertNil(vm.baseDays)
        XCTAssertEqual(vm.effectiveDays, 7)
    }

    func testEffectiveDaysForOverduePlant() throws {
        let plant = Plant(nickname: "Dry", species: "Peace Lily", nextDue: day(-2))
        try repo.add(plant)

        let vm = PlantDetailViewModel(plantID: plant.id, repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        // Overdue plants show as 1 day (minimum)
        XCTAssertEqual(vm.effectiveDays, 1)
    }

    // MARK: failure

    func testMissingPlantSetsLoadFailed() {
        let vm = PlantDetailViewModel(plantID: UUID(), repository: repo, careDatabase: careDatabase)
        vm.load(now: now)

        XCTAssertTrue(vm.loadFailed)
        XCTAssertEqual(vm.nickname, "")
        XCTAssertTrue(vm.history.isEmpty)
    }
}
