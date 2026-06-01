import XCTest
@testable import Sprout

/// Unit tests for the basket add view model (T203): auto-naming, multi-add of the
/// same species, rename/reroll, the `canCommit` guard, and ordered batch commit.
/// Backed by a fresh in-memory repository so it's exercised through its real
/// persistence boundary; the RNG is seeded so auto-names are deterministic.
@MainActor
final class BasketAddViewModelTests: XCTestCase {
    private var repo: PlantRepository!

    private let db = CareDatabase(profiles: [
        CareProfile(species: "Pothos", baseIntervalDays: 7, minIntervalDays: 5, maxIntervalDays: 14, moisture: .evenlyMoist),
        CareProfile(species: "Snake Plant", baseIntervalDays: 14, minIntervalDays: 10, maxIntervalDays: 28, moisture: .driesOut),
        CareProfile(species: "Boston Fern", baseIntervalDays: 4, minIntervalDays: 2, maxIntervalDays: 7, moisture: .staysMoist),
    ])

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    private func makeVM(seed: UInt64 = 1) -> BasketAddViewModel {
        BasketAddViewModel(repository: repo, careDatabase: db, rng: SeededRandomNumberGenerator(seed: seed))
    }

    private func profile(_ name: String) -> CareProfile {
        db.profiles.first { $0.species == name }!
    }

    // MARK: species picker

    func testSpeciesResultsComeFromCareDatabase() {
        let vm = makeVM()
        vm.speciesQuery = "fern"
        XCTAssertEqual(vm.speciesResults.map(\.species), ["Boston Fern"])
    }

    // MARK: add / auto-naming

    func testAddAssignsARandomNameFromThePool() {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        XCTAssertEqual(vm.basket.count, 1)
        XCTAssertEqual(vm.basket[0].species, "Pothos")
        XCTAssertTrue(EnglishNames.all.contains(vm.basket[0].nickname))
    }

    func testAddSameSpeciesTwiceYieldsDistinctNames() {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        vm.add(profile("Pothos"))
        XCTAssertEqual(vm.basket.count, 2)
        XCTAssertEqual(vm.basket.map(\.species), ["Pothos", "Pothos"])
        XCTAssertNotEqual(vm.basket[0].nickname, vm.basket[1].nickname)
    }

    func testAutoNamesAreMutuallyUnique() {
        let vm = makeVM()
        for _ in 0..<8 { vm.add(profile("Pothos")) }
        let names = vm.basket.map(\.nickname)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func testAutoNamesAvoidExistingRepoNicknames() throws {
        // "Monty" is in the curated pool; a plant already named Monty must not be
        // re-used as an auto-name.
        try repo.add(Plant(nickname: "Monty", species: "Pothos"))
        let vm = makeVM(seed: 99)
        for _ in 0..<12 { vm.add(profile("Pothos")) }
        XCTAssertFalse(vm.basket.map(\.nickname).contains("Monty"))
    }

    // MARK: rename / reroll / remove

    func testRenameUpdatesEntry() {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        vm.rename(vm.basket[0], to: "Sir Leafy")
        XCTAssertEqual(vm.basket[0].nickname, "Sir Leafy")
    }

    func testRerollChangesTheName() {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        let before = vm.basket[0].nickname
        vm.reroll(vm.basket[0])
        XCTAssertNotEqual(vm.basket[0].nickname, before)
    }

    func testRemoveDropsEntry() {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        vm.add(profile("Snake Plant"))
        vm.remove(vm.basket[0])
        XCTAssertEqual(vm.basket.map(\.species), ["Snake Plant"])
    }

    // MARK: canCommit

    func testCannotCommitEmptyBasket() {
        XCTAssertFalse(makeVM().canCommit)
    }

    func testCanCommitWithEntries() {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        XCTAssertTrue(vm.canCommit)
        XCTAssertEqual(vm.commitCount, 1)
    }

    // MARK: commit

    func testCommitCreatesAllPlantsInBasketOrder() throws {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        vm.add(profile("Snake Plant"))
        vm.add(profile("Boston Fern"))
        let expected = vm.basket.map { ($0.nickname, $0.species) }

        let created = try vm.commit()

        XCTAssertEqual(created.map(\.nickname), expected.map(\.0))
        XCTAssertEqual(created.map(\.species), expected.map(\.1))
        XCTAssertEqual(try repo.allPlants().count, 3)
        XCTAssertTrue(vm.basket.isEmpty, "basket clears on commit")
    }

    func testCommitResolvesBlankNameToARandomOne() throws {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        vm.rename(vm.basket[0], to: "   ")
        let created = try vm.commit()
        XCTAssertEqual(created.count, 1)
        XCTAssertFalse(created[0].nickname.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    func testCommitEmptyBasketThrows() {
        XCTAssertThrowsError(try makeVM().commit()) { error in
            XCTAssertEqual(error as? BasketAddError, .incomplete)
        }
    }

    // MARK: initial cadence at add-time (T212)

    func testCommitSeedsInitialScheduleFromSpecies() throws {
        let vm = makeVM()
        vm.add(profile("Pothos"))
        let now = Date(timeIntervalSince1970: 1_000_000)
        let created = try vm.commit(now: now)
        XCTAssertEqual(created[0].lastWatered, now)
        XCTAssertNotNil(created[0].nextDue, "a new plant gets an initial cadence, not nil")
    }

    // MARK: room-first flow (T221)

    func testFlowStartsOnTheRoomStep() {
        XCTAssertEqual(makeVM().step, .room)
    }

    func testChooseRoomSelectsItAndAdvancesToPlants() {
        let vm = makeVM()
        let room = Room(name: "Kitchen", sunlight: .indirect, humidity: .normal)
        vm.chooseRoom(room)
        XCTAssertEqual(vm.selectedRoom, room)
        XCTAssertEqual(vm.step, .plants)
    }

    func testChooseNoRoomStillAdvances() {
        let vm = makeVM()
        vm.chooseRoom(nil)
        XCTAssertNil(vm.selectedRoom)
        XCTAssertEqual(vm.step, .plants)
    }

    func testCreateRoomPersistsSelectsAndAdvances() throws {
        let vm = makeVM()
        vm.createRoom(name: "Sunroom", directSun: .high, indirectSun: .high, humidity: .dry)

        // Persisted to the repository…
        let rooms = try repo.allRooms()
        XCTAssertEqual(rooms.map(\.name), ["Sunroom"])
        // …selected for the batch, and the flow advanced.
        XCTAssertEqual(vm.selectedRoom?.name, "Sunroom")
        XCTAssertEqual(vm.step, .plants)
        XCTAssertTrue(vm.availableRooms.contains { $0.name == "Sunroom" })
    }

    func testCreateRoomIgnoresBlankName() throws {
        let vm = makeVM()
        vm.createRoom(name: "   ", directSun: .high, indirectSun: .high, humidity: .dry)
        XCTAssertTrue(try repo.allRooms().isEmpty)
        XCTAssertEqual(vm.step, .room, "a blank room keeps the flow on the room step")
    }

    func testBackToRoomStepKeepsTheBasket() {
        let vm = makeVM()
        vm.chooseRoom(Room(name: "Den"))
        vm.add(profile("Pothos"))
        vm.backToRoomStep()
        XCTAssertEqual(vm.step, .room)
        XCTAssertEqual(vm.basket.map(\.species), ["Pothos"], "stepping back doesn't clear the basket")
    }

    func testRoomFirstCommitLandsEveryPlantInTheChosenRoom() throws {
        let vm = makeVM()
        vm.createRoom(name: "Studio", directSun: .high, indirectSun: .high, humidity: .dry)
        let roomID = try XCTUnwrap(vm.selectedRoom?.id)
        vm.add(profile("Pothos"))
        vm.add(profile("Snake Plant"))
        let created = try vm.commit()
        XCTAssertEqual(created.map(\.roomID), [roomID, roomID])
    }

    func testCommitAssignsRoomAndShortensInABrightDryRoom() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)

        // Neutral (no room) cadence.
        let neutralVM = makeVM()
        neutralVM.add(profile("Pothos"))
        let neutralDue = try XCTUnwrap(neutralVM.commit(now: now).first?.nextDue)

        // Bright + dry room → factor < 1 → sooner due date, and roomID is set.
        let room = Room(name: "Sunroom", sunlight: .direct, humidity: .dry)
        let roomVM = makeVM()
        roomVM.selectedRoom = room
        roomVM.add(profile("Pothos"))
        let created = try roomVM.commit(now: now)
        XCTAssertEqual(created[0].roomID, room.id)
        XCTAssertLessThan(try XCTUnwrap(created[0].nextDue), neutralDue)
    }
}
