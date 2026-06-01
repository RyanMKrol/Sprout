import Foundation

/// Errors surfaced by a `PlantRepository` implementation.
enum PlantRepositoryError: Error, Equatable {
    /// No record (plant or room) with the given identifier exists in the store.
    case notFound(UUID)
}

/// Persistence boundary for plants and their check-ins.
///
/// The UI and view-models depend on **this protocol**, never on SwiftData
/// directly — so the storage engine (currently SwiftData, see
/// `SwiftDataPlantRepository`) can be swapped or stubbed in tests without
/// touching callers. All inputs and outputs are the pure domain value types
/// (`Plant`, `CheckIn`); nothing SwiftData-shaped leaks across this line.
protocol PlantRepository {
    /// Every stored plant, each with its check-ins in chronological order.
    func allPlants() throws -> [Plant]

    /// The plant with `id`, or `nil` if none exists.
    func plant(id: UUID) throws -> Plant?

    /// Insert a new plant (including any check-ins it already carries).
    func add(_ plant: Plant) throws

    /// Update an existing plant's mutable fields (nickname, species, and the
    /// learned scheduling state `adj`/`lastWatered`/`nextDue`). Check-ins are
    /// appended via `addCheckIn(_:toPlant:)`, not replaced here.
    /// - Throws: `PlantRepositoryError.notFound` if no such plant exists.
    func update(_ plant: Plant) throws

    /// Delete the plant with `id` and (cascading) its check-ins.
    /// - Throws: `PlantRepositoryError.notFound` if no such plant exists.
    func delete(id: UUID) throws

    /// Delete **every** plant (and, cascading, their check-ins). A no-op on an
    /// empty store. Used by the Settings developer reset (T216).
    func deleteAllPlants() throws

    /// Append a check-in to an existing plant.
    /// - Throws: `PlantRepositoryError.notFound` if no such plant exists.
    func addCheckIn(_ checkIn: CheckIn, toPlant plantID: UUID) throws

    // MARK: - Rooms

    /// Every stored room, sorted by name.
    func allRooms() throws -> [Room]

    /// The room with `id`, or `nil` if none exists.
    func room(id: UUID) throws -> Room?

    /// Insert a new room.
    func addRoom(_ room: Room) throws

    /// Update an existing room's fields.
    /// - Throws: `PlantRepositoryError.notFound` if no such room exists.
    func updateRoom(_ room: Room) throws

    /// Delete the room with `id`, clearing `roomID` on any plants assigned to it
    /// (plants are never deleted with their room).
    /// - Throws: `PlantRepositoryError.notFound` if no such room exists.
    func deleteRoom(id: UUID) throws

    /// Delete **every** room. Plants are kept; their `roomID` is cleared so they
    /// fall back to a neutral environment. A no-op on an empty store. Used by the
    /// Settings developer reset (T216).
    func deleteAllRooms() throws
}
