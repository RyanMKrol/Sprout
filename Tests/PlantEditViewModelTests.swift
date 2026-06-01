import XCTest
@testable import Sprout

/// Unit tests for the Add / Edit Plant view model (T007): species sourced from the
/// care database, save → repository in both add and edit modes (preserving learned
/// scheduling state on edit), and the `canSave` form-completeness rules. Backed by a
/// fresh in-memory `PlantRepository` so the view model is exercised through its real
/// persistence boundary.
@MainActor
final class PlantEditViewModelTests: XCTestCase {
    private var repo: PlantRepository!

    /// A small, fixed care database so the picker contents are deterministic and the
    /// tests don't depend on the bundled JSON.
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

    private func addModel() -> PlantEditViewModel {
        PlantEditViewModel(mode: .add, repository: repo, careDatabase: db)
    }

    // MARK: species picker sourced from the care DB

    func testSpeciesOptionsComeFromCareDatabase() {
        let vm = addModel()
        XCTAssertEqual(vm.allSpecies.map(\.species), ["Boston Fern", "Pothos", "Snake Plant"])
    }

    func testSpeciesSearchFiltersOptions() {
        let vm = addModel()
        vm.speciesQuery = "fern"
        XCTAssertEqual(vm.speciesResults.map(\.species), ["Boston Fern"])
    }

    func testSelectMarksSpeciesAsSelected() {
        let vm = addModel()
        let pothos = db.profiles.first { $0.species == "Pothos" }!
        vm.select(pothos)
        XCTAssertEqual(vm.selectedSpecies, "Pothos")
        XCTAssertTrue(vm.isSelected(pothos))
        XCTAssertFalse(vm.isSelected(db.profiles.first { $0.species == "Snake Plant" }!))
    }

    // MARK: add → repository

    func testAddSavesPlantToRepository() throws {
        let vm = addModel()
        vm.nickname = "  Monty  "
        vm.select(db.profiles.first { $0.species == "Pothos" }!)
        XCTAssertTrue(vm.canSave)

        let saved = try vm.save()
        let stored = try repo.allPlants()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.nickname, "Monty") // trimmed
        XCTAssertEqual(stored.first?.species, "Pothos")
        XCTAssertEqual(stored.first?.id, saved.id)
        XCTAssertEqual(stored.first?.adj, Plant.defaultAdj)
        XCTAssertNil(stored.first?.nextDue)
    }

    // MARK: canSave / save guards

    func testCannotSaveWithoutNickname() {
        let vm = addModel()
        vm.select(db.profiles.first!)
        XCTAssertFalse(vm.canSave)
        XCTAssertThrowsError(try vm.save()) { XCTAssertEqual($0 as? PlantEditError, .incomplete) }
    }

    func testCannotSaveWithoutSpecies() {
        let vm = addModel()
        vm.nickname = "Monty"
        XCTAssertFalse(vm.canSave)
        XCTAssertThrowsError(try vm.save()) { XCTAssertEqual($0 as? PlantEditError, .incomplete) }
    }

    func testCannotSaveUnknownSpecies() {
        let vm = addModel()
        vm.nickname = "Monty"
        vm.selectedSpecies = "Triffid" // not in the care DB
        XCTAssertFalse(vm.canSave)
        XCTAssertThrowsError(try vm.save())
    }

    func testWhitespaceNicknameIsNotSavable() {
        let vm = addModel()
        vm.nickname = "   "
        vm.select(db.profiles.first!)
        XCTAssertFalse(vm.canSave)
    }

    // MARK: edit mode

    func testEditPrefillsFromExistingPlant() throws {
        let plant = Plant(nickname: "Spike", species: "Snake Plant")
        try repo.add(plant)

        let vm = PlantEditViewModel(mode: .edit(plantID: plant.id), repository: repo, careDatabase: db)
        XCTAssertTrue(vm.isEditing)
        XCTAssertEqual(vm.title, "Edit Plant")
        XCTAssertEqual(vm.nickname, "Spike")
        XCTAssertEqual(vm.selectedSpecies, "Snake Plant")
        XCTAssertFalse(vm.loadFailed)
    }

    func testEditUpdatesPlantPreservingSchedulingState() throws {
        let due = Date(timeIntervalSinceReferenceDate: 100_000)
        let watered = Date(timeIntervalSinceReferenceDate: 50_000)
        let checkIn = CheckIn(date: watered, soil: .dry, leaves: .fine, watered: true)
        let plant = Plant(
            nickname: "Spike",
            species: "Snake Plant",
            adj: 1.5,
            lastWatered: watered,
            nextDue: due,
            checkIns: [checkIn]
        )
        try repo.add(plant)

        let vm = PlantEditViewModel(mode: .edit(plantID: plant.id), repository: repo, careDatabase: db)
        vm.nickname = "Spike Lee"
        vm.select(db.profiles.first { $0.species == "Pothos" }!)
        let updated = try vm.save()

        let reloaded = try repo.plant(id: plant.id)
        XCTAssertEqual(reloaded?.id, plant.id)
        XCTAssertEqual(reloaded?.nickname, "Spike Lee")
        XCTAssertEqual(reloaded?.species, "Pothos")
        // Learned scheduling state is untouched by the editor.
        XCTAssertEqual(reloaded?.adj, 1.5)
        XCTAssertEqual(reloaded?.lastWatered, watered)
        XCTAssertEqual(reloaded?.nextDue, due)
        XCTAssertEqual(reloaded?.checkIns.count, 1)
        XCTAssertEqual(updated.id, plant.id)
        // No extra plant was inserted.
        XCTAssertEqual(try repo.allPlants().count, 1)
    }

    func testEditMissingPlantFlagsLoadFailure() {
        let vm = PlantEditViewModel(mode: .edit(plantID: UUID()), repository: repo, careDatabase: db)
        XCTAssertTrue(vm.loadFailed)
    }

    // MARK: titles

    func testAddModeTitles() {
        let vm = addModel()
        XCTAssertFalse(vm.isEditing)
        XCTAssertEqual(vm.title, "Add Plant")
        XCTAssertEqual(vm.saveButtonTitle, "Add")
    }
}
