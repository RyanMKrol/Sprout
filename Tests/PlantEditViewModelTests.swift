import XCTest
import UIKit
@testable import Sprout

/// Unit tests for the Edit Plant view model (T007, narrowed by T218): the form edits
/// **nickname + room only** — species is fixed once a plant exists — and a save routes
/// through the repository, preserving the plant's learned scheduling state and species.
/// Backed by a fresh in-memory `PlantRepository` so the view model is exercised through
/// its real persistence boundary.
@MainActor
final class PlantEditViewModelTests: XCTestCase {
    private var repo: PlantRepository!

    /// A small, fixed care database so the view model's dependency is deterministic
    /// and the tests don't depend on the bundled JSON.
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

    private func editModel(
        for plantID: UUID,
        camera: PhotoCapturing? = nil
    ) -> PlantEditViewModel {
        PlantEditViewModel(
            mode: .edit(plantID: plantID),
            repository: repo,
            careDatabase: db,
            camera: camera ?? StubPhotoCapturing()
        )
    }

    // MARK: canSave / save guards (nickname only — species is no longer part of the form)

    func testCannotSaveWithoutNickname() throws {
        let plant = Plant(nickname: "Spike", species: "Snake Plant")
        try repo.add(plant)
        let vm = editModel(for: plant.id)
        vm.nickname = ""
        XCTAssertFalse(vm.canSave)
        XCTAssertThrowsError(try vm.save()) { XCTAssertEqual($0 as? PlantEditError, .incomplete) }
    }

    func testWhitespaceNicknameIsNotSavable() throws {
        let plant = Plant(nickname: "Spike", species: "Snake Plant")
        try repo.add(plant)
        let vm = editModel(for: plant.id)
        vm.nickname = "   "
        XCTAssertFalse(vm.canSave)
    }

    func testCanSaveWithNicknameOnly() throws {
        let plant = Plant(nickname: "Spike", species: "Snake Plant")
        try repo.add(plant)
        let vm = editModel(for: plant.id)
        XCTAssertTrue(vm.canSave)
    }

    // MARK: edit mode

    func testEditPrefillsNicknameAndRoom() throws {
        let room = Room(name: "Kitchen")
        try repo.addRoom(room)
        let plant = Plant(nickname: "Spike", species: "Snake Plant", roomID: room.id)
        try repo.add(plant)

        let vm = editModel(for: plant.id)
        XCTAssertTrue(vm.isEditing)
        XCTAssertEqual(vm.title, "Edit Plant")
        XCTAssertEqual(vm.saveButtonTitle, "Save")
        XCTAssertEqual(vm.nickname, "Spike")
        XCTAssertEqual(vm.selectedRoomID, room.id)
        XCTAssertFalse(vm.loadFailed)
    }

    func testEditUpdatesNicknameAndRoomPreservingSpeciesAndSchedulingState() throws {
        let room = Room(name: "Bedroom")
        try repo.addRoom(room)
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

        let vm = editModel(for: plant.id)
        vm.nickname = "  Spike Lee  "
        vm.selectedRoomID = room.id
        let updated = try vm.save()

        let reloaded = try repo.plant(id: plant.id)
        XCTAssertEqual(reloaded?.id, plant.id)
        XCTAssertEqual(reloaded?.nickname, "Spike Lee") // trimmed
        XCTAssertEqual(reloaded?.roomID, room.id)
        // Species is fixed — the edit form never changes it.
        XCTAssertEqual(reloaded?.species, "Snake Plant")
        // Learned scheduling state is untouched by the editor.
        XCTAssertEqual(reloaded?.adj, 1.5)
        XCTAssertEqual(reloaded?.lastWatered, watered)
        XCTAssertEqual(reloaded?.nextDue, due)
        XCTAssertEqual(reloaded?.checkIns.count, 1)
        XCTAssertEqual(updated.id, plant.id)
        // No extra plant was inserted.
        XCTAssertEqual(try repo.allPlants().count, 1)
    }

    func testEditCanClearRoom() throws {
        let room = Room(name: "Office")
        try repo.addRoom(room)
        let plant = Plant(nickname: "Spike", species: "Snake Plant", roomID: room.id)
        try repo.add(plant)

        let vm = editModel(for: plant.id)
        vm.selectedRoomID = nil
        try vm.save()

        XCTAssertNil(try repo.plant(id: plant.id)?.roomID)
    }

    func testEditMissingPlantFlagsLoadFailure() {
        let vm = editModel(for: UUID())
        XCTAssertTrue(vm.loadFailed)
    }

    // MARK: photo (T219)

    func testEditPrefillsExistingPhoto() throws {
        let existing = Data([0x01, 0x02, 0x03])
        let plant = Plant(nickname: "Spike", species: "Snake Plant", photoData: existing)
        try repo.add(plant)
        let vm = editModel(for: plant.id)
        XCTAssertEqual(vm.photoData, existing)
        XCTAssertTrue(vm.hasPhoto)
    }

    func testNoPhotoMeansNoExistingPhoto() throws {
        let plant = Plant(nickname: "Spike", species: "Snake Plant")
        try repo.add(plant)
        let vm = editModel(for: plant.id)
        XCTAssertNil(vm.photoData)
        XCTAssertFalse(vm.hasPhoto)
    }

    func testStagePhotoStagesAndPersistsOnSave() throws {
        let plant = Plant(nickname: "Spike", species: "Snake Plant")
        try repo.add(plant)
        let vm = editModel(for: plant.id)

        vm.stage(StubPhotoCapturing.placeholderImage())
        // Staged in-memory immediately…
        XCTAssertNotNil(vm.photoData)
        XCTAssertTrue(vm.hasPhoto)
        // …but not persisted until save (transactional form).
        XCTAssertNil(try repo.plant(id: plant.id)?.photoData)

        try vm.save()
        XCTAssertEqual(try repo.plant(id: plant.id)?.photoData, vm.photoData)
    }

    func testStagePhotoReplacesExistingPhotoOnSave() throws {
        let old = Data([0xAA])
        let plant = Plant(nickname: "Spike", species: "Snake Plant", photoData: old)
        try repo.add(plant)
        let vm = editModel(for: plant.id)

        vm.stage(StubPhotoCapturing.placeholderImage())
        try vm.save()

        let reloaded = try repo.plant(id: plant.id)
        XCTAssertNotNil(reloaded?.photoData)
        XCTAssertNotEqual(reloaded?.photoData, old)
    }

    func testStageIgnoresUnencodableImage() throws {
        let existing = Data([0xBB, 0xCC])
        let plant = Plant(nickname: "Spike", species: "Snake Plant", photoData: existing)
        try repo.add(plant)
        let vm = editModel(for: plant.id)

        vm.stage(UIImage()) // no CGImage → PlantPhoto.encode returns nil → ignored
        XCTAssertEqual(vm.photoData, existing)
    }
}
