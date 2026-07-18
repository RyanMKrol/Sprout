import XCTest
@testable import Sprout

/// Unit tests for the guided watering coordinator (T215): preview without persisting,
/// confirm persists + advances, skip advances, finish, empty set.
@MainActor
final class GuidedWateringCoordinatorTests: XCTestCase {
    private var repo: PlantRepository!

    private let db = CareDatabase(profiles: [
        CareProfile(species: "Pothos", baseIntervalDays: 7, minIntervalDays: 5, maxIntervalDays: 14, moisture: .evenlyMoist),
        CareProfile(species: "Snake Plant", baseIntervalDays: 14, minIntervalDays: 10, maxIntervalDays: 28, moisture: .driesOut),
    ])

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    private func makeCoordinator(_ plants: [Plant]) -> GuidedWateringCoordinator {
        for plant in plants { try? repo.add(plant) }
        return GuidedWateringCoordinator(plants: plants, repository: repo, careDatabase: db)
    }

    func testStartsOnFirstPlant() {
        let c = makeCoordinator([Plant(nickname: "A", species: "Pothos")])
        XCTAssertEqual(c.current?.nickname, "A")
        XCTAssertFalse(c.isFinished)
        XCTAssertEqual(c.progressText, "1 of 1")
    }

    func testPreviewDoesNotPersist() throws {
        let plant = Plant(nickname: "A", species: "Pothos")
        let c = makeCoordinator([plant])
        c.soil = .dry
        c.leaves = .fine
        c.preview(now: Date(timeIntervalSince1970: 1000))

        XCTAssertNotNil(c.recommendation)
        XCTAssertTrue(c.recommendsWater) // dry → water
        // Nothing written: no check-ins, schedule untouched.
        let stored = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertTrue(stored.checkIns.isEmpty)
        XCTAssertNil(stored.nextDue)
    }

    func testConfirmWateredPersistsAndAdvances() throws {
        let plant = Plant(nickname: "A", species: "Pothos")
        let c = makeCoordinator([plant, Plant(nickname: "B", species: "Pothos")])
        c.soil = .dry
        c.preview()
        c.confirm(watered: true, now: Date(timeIntervalSince1970: 5000))

        let stored = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(stored.checkIns.count, 1)
        XCTAssertEqual(stored.checkIns.first?.watered, true)
        XCTAssertNotNil(stored.nextDue, "watering recomputed the schedule")
        XCTAssertEqual(c.index, 1, "advanced to the next plant")
        XCTAssertNil(c.recommendation, "recommendation cleared on advance")
    }

    func testSkipAdvancesWithoutPersisting() throws {
        let plant = Plant(nickname: "A", species: "Pothos")
        let c = makeCoordinator([plant, Plant(nickname: "B", species: "Pothos")])
        c.skip()
        XCTAssertEqual(c.index, 1)
        XCTAssertTrue(try XCTUnwrap(repo.plant(id: plant.id)).checkIns.isEmpty)
    }

    func testWalkingAllPlantsFinishes() {
        let c = makeCoordinator([Plant(nickname: "A", species: "Pothos"), Plant(nickname: "B", species: "Pothos")])
        c.confirm(watered: false)
        c.confirm(watered: false)
        XCTAssertTrue(c.isFinished)
        XCTAssertNil(c.current)
    }

    func testEmptySetFinishesImmediately() {
        let c = GuidedWateringCoordinator(plants: [], repository: repo, careDatabase: db)
        XCTAssertTrue(c.isFinished)
        XCTAssertNil(c.current)
    }

    func testInputsResetBetweenPlants() {
        let c = makeCoordinator([Plant(nickname: "A", species: "Pothos"), Plant(nickname: "B", species: "Pothos")])
        c.soil = .wet
        c.leaves = .droopy
        c.confirm(watered: false)
        XCTAssertEqual(c.soil, .moist, "soil resets for the next plant")
        XCTAssertEqual(c.leaves, .fine, "leaves reset for the next plant")
    }

    func testCompletionBodyForDueMode() {
        let body = GuidedWateringCoordinator.completionBody(for: .due)
        XCTAssertEqual(body, "You've been through every plant that needed water today.")
    }

    func testCompletionBodyForAllMode() {
        let body = GuidedWateringCoordinator.completionBody(for: .all)
        XCTAssertEqual(body, "You've checked in on every plant.")
    }
}
