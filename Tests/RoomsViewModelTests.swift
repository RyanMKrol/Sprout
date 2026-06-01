import XCTest
@testable import Sprout

/// Unit tests for the Rooms view model (T213): load with plant counts, add, delete.
@MainActor
final class RoomsViewModelTests: XCTestCase {
    private var repo: PlantRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    func testLoadCountsPlantsPerRoom() throws {
        let room = Room(name: "Lounge")
        try repo.addRoom(room)
        var a = Plant(nickname: "A", species: "Pothos"); a.roomID = room.id
        var b = Plant(nickname: "B", species: "Pothos"); b.roomID = room.id
        try repo.add(a)
        try repo.add(b)
        try repo.add(Plant(nickname: "C", species: "Pothos")) // no room

        let vm = RoomsViewModel(repository: repo)
        vm.load()

        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items.first?.plantCount, 2)
    }

    func testAddCreatesRoom() {
        let vm = RoomsViewModel(repository: repo)
        vm.add(name: "Office", sunlight: .direct, humidity: .dry)
        XCTAssertEqual(vm.items.map(\.room.name), ["Office"])
        XCTAssertEqual(vm.items.first?.room.sunlight, .direct)
    }

    func testAddIgnoresBlankName() {
        let vm = RoomsViewModel(repository: repo)
        vm.add(name: "   ", sunlight: .indirect, humidity: .normal)
        XCTAssertTrue(vm.isEmpty)
    }

    func testDeleteRemovesRoom() {
        let vm = RoomsViewModel(repository: repo)
        vm.add(name: "Hall", sunlight: .low, humidity: .normal)
        let item = try! XCTUnwrap(vm.items.first)
        vm.delete(item)
        XCTAssertTrue(vm.isEmpty)
    }
}
