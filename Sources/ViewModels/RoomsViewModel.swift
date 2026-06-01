import Foundation

/// Drives the **Rooms** screen (T213): lists the user's rooms with a plant count and
/// supports add / edit / delete via the repository's room CRUD. A room's environment
/// (sunlight + humidity) drives the watering cadence of the plants assigned to it.
///
/// All logic lives here behind a testable surface; the view is pure presentation.
@MainActor
final class RoomsViewModel: ObservableObject {
    /// One row: the room plus how many plants live in it.
    struct Item: Identifiable, Equatable {
        let room: Room
        let plantCount: Int
        var id: UUID { room.id }
    }

    @Published private(set) var items: [Item] = []

    private let repository: PlantRepository

    init(repository: PlantRepository) {
        self.repository = repository
    }

    var isEmpty: Bool { items.isEmpty }

    /// Reload rooms (with plant counts) from the repository.
    func load() {
        let rooms = (try? repository.allRooms()) ?? []
        let plants = (try? repository.allPlants()) ?? []
        var counts: [UUID: Int] = [:]
        for plant in plants {
            if let roomID = plant.roomID { counts[roomID, default: 0] += 1 }
        }
        items = rooms.map { Item(room: $0, plantCount: counts[$0.id] ?? 0) }
    }

    /// Create a new room, then reload. Blank names are ignored.
    func add(name: String, sunlight: SunlightLevel, humidity: RoomHumidity) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try? repository.addRoom(Room(name: trimmed, sunlight: sunlight, humidity: humidity))
        load()
    }

    /// Create a new room from the T220 two-input light model, then reload. Blank
    /// names are ignored.
    func add(name: String, directSun: LightLevel, indirectSun: LightLevel, humidity: RoomHumidity) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try? repository.addRoom(
            Room(name: trimmed, directSun: directSun, indirectSun: indirectSun, humidity: humidity)
        )
        load()
    }

    /// Persist edits to an existing room, then reload. Blank names are ignored.
    func update(_ room: Room) {
        guard !room.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        try? repository.updateRoom(room)
        load()
    }

    /// Delete a room (its plants are detached, not deleted), then reload.
    func delete(_ item: Item) {
        try? repository.deleteRoom(id: item.room.id)
        load()
    }

    /// Delete rooms at list offsets (swipe-to-delete).
    func delete(atOffsets offsets: IndexSet) {
        for index in offsets where items.indices.contains(index) {
            try? repository.deleteRoom(id: items[index].room.id)
        }
        load()
    }
}
