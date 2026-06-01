import XCTest
@testable import Sprout

/// Integration tests for the SwiftData-backed `PlantRepository`, exercised
/// through a fresh in-memory `ModelContainer` (built by `PlantStore.inMemory()`
/// so this test never imports SwiftData directly).
final class PersistenceTests: XCTestCase {
    private var repo: PlantRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    // MARK: helpers

    private func date(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }

    private func makePlant(
        nickname: String = "Monty",
        species: String = "Monstera deliciosa",
        checkIns: [CheckIn] = []
    ) -> Plant {
        Plant(
            nickname: nickname,
            species: species,
            adj: 1.0,
            lastWatered: date(1_000),
            nextDue: date(100_000),
            checkIns: checkIns
        )
    }

    // MARK: round-trip

    func testRoundTripPlantWithCheckIns() throws {
        let checkIns = [
            CheckIn(date: date(2_000), soil: .moist, leaves: .fine, watered: true),
            CheckIn(date: date(3_000), soil: .dry, leaves: .droopy, watered: false),
        ]
        let plant = makePlant(checkIns: checkIns)

        try repo.add(plant)

        let fetched = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(fetched, plant)
        XCTAssertEqual(fetched.checkIns.count, 2)
        XCTAssertEqual(fetched.checkIns.map(\.soil), [.moist, .dry])
    }

    func testAddPlantWithNoCheckIns() throws {
        let plant = makePlant()
        try repo.add(plant)
        let fetched = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(fetched, plant)
        XCTAssertTrue(fetched.checkIns.isEmpty)
    }

    // MARK: photo (T201)

    func testPlantPhotoRoundTrips() throws {
        var plant = makePlant()
        plant.photoData = Data([0x01, 0x02, 0x03, 0x04])
        try repo.add(plant)

        let fetched = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(fetched.photoData, Data([0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(fetched, plant)
    }

    func testPlantWithoutPhotoRoundTripsAsNil() throws {
        // The additive, migration-free guarantee: a plant added without a photo
        // reads back with `photoData == nil`.
        let plant = makePlant()
        try repo.add(plant)
        XCTAssertNil(try XCTUnwrap(repo.plant(id: plant.id)).photoData)
    }

    func testUpdateSetsAndClearsPhoto() throws {
        var plant = makePlant()
        try repo.add(plant)

        plant.photoData = Data([0xAA, 0xBB])
        try repo.update(plant)
        XCTAssertEqual(try XCTUnwrap(repo.plant(id: plant.id)).photoData, Data([0xAA, 0xBB]))

        plant.photoData = nil
        try repo.update(plant)
        XCTAssertNil(try XCTUnwrap(repo.plant(id: plant.id)).photoData)
    }

    // MARK: rooms (T211)

    func testRoomRoundTrips() throws {
        let room = Room(name: "Office", sunlight: .direct, humidity: .dry)
        try repo.addRoom(room)
        let fetched = try XCTUnwrap(repo.room(id: room.id))
        XCTAssertEqual(fetched, room)
    }

    func testAllRoomsSortedByName() throws {
        try repo.addRoom(Room(name: "Lounge"))
        try repo.addRoom(Room(name: "Bedroom"))
        XCTAssertEqual(try repo.allRooms().map(\.name), ["Bedroom", "Lounge"])
    }

    func testUpdateRoomPersists() throws {
        var room = Room(name: "Hall", sunlight: .low, humidity: .normal)
        try repo.addRoom(room)
        room.name = "Hallway"
        room.sunlight = .indirect
        try repo.updateRoom(room)
        let fetched = try XCTUnwrap(repo.room(id: room.id))
        XCTAssertEqual(fetched.name, "Hallway")
        XCTAssertEqual(fetched.sunlight, .indirect)
    }

    func testUpdateMissingRoomThrows() {
        XCTAssertThrowsError(try repo.updateRoom(Room(name: "Ghost")))
    }

    func testRoomLightLevelsRoundTrip() throws {
        // T220: the two-input light model persists and infers brightness on read-back.
        let room = Room(name: "Sunroom", directSun: .high, indirectSun: .medium, humidity: .dry)
        try repo.addRoom(room)
        let fetched = try XCTUnwrap(repo.room(id: room.id))
        XCTAssertEqual(fetched.directSun, .high)
        XCTAssertEqual(fetched.indirectSun, .medium)
        XCTAssertEqual(fetched.brightness, .bright)
        XCTAssertEqual(fetched, room)
    }

    func testUpdateRoomLightLevelsPersist() throws {
        var room = Room(name: "Study", directSun: .low, indirectSun: .low, humidity: .normal)
        try repo.addRoom(room)
        XCTAssertEqual(room.brightness, .dark)
        room.directSun = .high
        room.indirectSun = .high
        try repo.updateRoom(room)
        let fetched = try XCTUnwrap(repo.room(id: room.id))
        XCTAssertEqual(fetched.directSun, .high)
        XCTAssertEqual(fetched.indirectSun, .high)
        XCTAssertEqual(fetched.brightness, .bright)
    }

    func testPlantRoomIDRoundTrips() throws {
        let room = Room(name: "Kitchen")
        try repo.addRoom(room)
        var plant = makePlant()
        plant.roomID = room.id
        try repo.add(plant)
        XCTAssertEqual(try XCTUnwrap(repo.plant(id: plant.id)).roomID, room.id)
    }

    func testPlantWithoutRoomRoundTripsAsNil() throws {
        let plant = makePlant()
        try repo.add(plant)
        XCTAssertNil(try XCTUnwrap(repo.plant(id: plant.id)).roomID)
    }

    func testDeleteRoomNilsAssignedPlantsButKeepsThem() throws {
        let room = Room(name: "Studio")
        try repo.addRoom(room)
        var a = makePlant(nickname: "A")
        var b = makePlant(nickname: "B")
        a.roomID = room.id
        b.roomID = room.id
        try repo.add(a)
        try repo.add(b)

        try repo.deleteRoom(id: room.id)

        XCTAssertNil(try repo.room(id: room.id))
        XCTAssertEqual(try repo.allPlants().count, 2, "plants survive their room")
        XCTAssertNil(try XCTUnwrap(repo.plant(id: a.id)).roomID)
        XCTAssertNil(try XCTUnwrap(repo.plant(id: b.id)).roomID)
    }

    func testDeleteMissingRoomThrows() {
        XCTAssertThrowsError(try repo.deleteRoom(id: UUID()))
    }

    // MARK: bulk reset (T216)

    func testDeleteAllPlantsAndRoomsEmptiesStore() throws {
        let room = Room(name: "Studio")
        try repo.addRoom(room)
        try repo.addRoom(Room(name: "Bedroom"))
        var a = makePlant(nickname: "A")
        a.roomID = room.id
        try repo.add(a)
        try repo.add(makePlant(nickname: "B"))

        try repo.deleteAllPlants()
        try repo.deleteAllRooms()

        XCTAssertTrue(try repo.allPlants().isEmpty)
        XCTAssertTrue(try repo.allRooms().isEmpty)
    }

    func testDeleteAllRoomsKeepsPlantsButClearsRoomID() throws {
        let room = Room(name: "Studio")
        try repo.addRoom(room)
        var a = makePlant(nickname: "A")
        a.roomID = room.id
        try repo.add(a)

        try repo.deleteAllRooms()

        XCTAssertTrue(try repo.allRooms().isEmpty)
        XCTAssertEqual(try repo.allPlants().count, 1, "plants survive a room wipe")
        XCTAssertNil(try XCTUnwrap(repo.plant(id: a.id)).roomID)
    }

    func testDeleteAllOnEmptyStoreIsNoOp() throws {
        try repo.deleteAllPlants()
        try repo.deleteAllRooms()
        XCTAssertTrue(try repo.allPlants().isEmpty)
        XCTAssertTrue(try repo.allRooms().isEmpty)
    }

    func testPlantNotFoundReturnsNil() throws {
        XCTAssertNil(try repo.plant(id: UUID()))
    }

    // MARK: read all

    func testAllPlantsSortedByNickname() throws {
        try repo.add(makePlant(nickname: "Zelda", species: "Pothos"))
        try repo.add(makePlant(nickname: "Audrey", species: "Boston Fern"))
        try repo.add(makePlant(nickname: "Monty"))

        let names = try repo.allPlants().map(\.nickname)
        XCTAssertEqual(names, ["Audrey", "Monty", "Zelda"])
    }

    func testAllPlantsEmptyStore() throws {
        XCTAssertTrue(try repo.allPlants().isEmpty)
    }

    // MARK: update

    func testUpdateScalarsPersistsAndKeepsCheckIns() throws {
        var plant = makePlant(checkIns: [
            CheckIn(date: date(2_000), soil: .wet, leaves: .fine, watered: false),
        ])
        try repo.add(plant)

        plant.nickname = "Big Monty"
        plant.adj = 1.5
        plant.nextDue = date(200_000)
        try repo.update(plant)

        let fetched = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(fetched.nickname, "Big Monty")
        XCTAssertEqual(fetched.adj, 1.5)
        XCTAssertEqual(fetched.nextDue, date(200_000))
        XCTAssertEqual(fetched.checkIns.count, 1, "update must not drop check-ins")
    }

    func testUpdateMissingPlantThrows() throws {
        let plant = makePlant()
        XCTAssertThrowsError(try repo.update(plant)) { error in
            XCTAssertEqual(error as? PlantRepositoryError, .notFound(plant.id))
        }
    }

    // MARK: delete

    func testDeleteRemovesPlantAndCascadesCheckIns() throws {
        let plant = makePlant(checkIns: [
            CheckIn(date: date(2_000), soil: .moist, leaves: .fine, watered: true),
        ])
        try repo.add(plant)

        try repo.delete(id: plant.id)

        XCTAssertNil(try repo.plant(id: plant.id))
        XCTAssertTrue(try repo.allPlants().isEmpty)
    }

    func testDeleteMissingPlantThrows() throws {
        let id = UUID()
        XCTAssertThrowsError(try repo.delete(id: id)) { error in
            XCTAssertEqual(error as? PlantRepositoryError, .notFound(id))
        }
    }

    // MARK: append check-ins

    func testAddCheckInAppends() throws {
        let plant = makePlant()
        try repo.add(plant)

        try repo.addCheckIn(
            CheckIn(date: date(5_000), soil: .dry, leaves: .fine, watered: true),
            toPlant: plant.id
        )
        try repo.addCheckIn(
            CheckIn(date: date(6_000), soil: .moist, leaves: .droopy, watered: false),
            toPlant: plant.id
        )

        let fetched = try XCTUnwrap(repo.plant(id: plant.id))
        XCTAssertEqual(fetched.checkIns.count, 2)
        XCTAssertEqual(fetched.checkIns.map(\.date), [date(5_000), date(6_000)])
    }

    func testCheckInsReturnedChronologically() throws {
        let plant = makePlant()
        try repo.add(plant)
        // Append out of chronological order.
        try repo.addCheckIn(
            CheckIn(date: date(9_000), soil: .dry, leaves: .fine, watered: true),
            toPlant: plant.id
        )
        try repo.addCheckIn(
            CheckIn(date: date(1_000), soil: .wet, leaves: .fine, watered: false),
            toPlant: plant.id
        )

        let dates = try XCTUnwrap(repo.plant(id: plant.id)).checkIns.map(\.date)
        XCTAssertEqual(dates, [date(1_000), date(9_000)])
    }

    func testAddCheckInMissingPlantThrows() throws {
        let id = UUID()
        let checkIn = CheckIn(date: date(1), soil: .dry, leaves: .fine, watered: true)
        XCTAssertThrowsError(try repo.addCheckIn(checkIn, toPlant: id)) { error in
            XCTAssertEqual(error as? PlantRepositoryError, .notFound(id))
        }
    }
}
