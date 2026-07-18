import Foundation

/// Drives the **Room detail** screen (screen 15): the room's environment (brightness /
/// humidity), the derived watering-impact copy, and the plants that live in it. Reads
/// from the same `PlantRepository` as the rest of the app; owns no persistence of its own.
@MainActor
final class RoomDetailViewModel: ObservableObject {
    /// One plant row on the room detail screen — enough to render a token + name +
    /// species + due chip, and to navigate into the plant's detail.
    struct PlantRow: Identifiable, Equatable {
        let id: UUID
        let nickname: String
        let species: String
        let icon: PlantIcon
        let photoData: Data?
        let due: WateringDueStatus
    }

    @Published private(set) var room: Room?
    @Published private(set) var plants: [PlantRow] = []
    /// True when the room id no longer resolves (e.g. deleted while the screen was open).
    @Published private(set) var loadFailed = false

    private let roomID: UUID
    private let repository: PlantRepository

    init(roomID: UUID, repository: PlantRepository) {
        self.roomID = roomID
        self.repository = repository
    }

    /// The room's schedule factor (neutral `1.0` before the first load).
    var factor: Double { RoomEnvironment.factor(for: room) }

    /// The watering-impact banner sentence for the current room.
    var impactLine: String { RoomImpactCopy.impactLine(factor: factor) }

    /// Reload the room and its plants from the repository, ordered by nickname.
    func load(now: Date = Date()) {
        let rooms = (try? repository.allRooms()) ?? []
        guard let match = rooms.first(where: { $0.id == roomID }) else {
            room = nil
            plants = []
            loadFailed = true
            return
        }
        room = match
        loadFailed = false
        let all = (try? repository.allPlants()) ?? []
        plants = all
            .filter { $0.roomID == roomID }
            .map { plant in
                PlantRow(
                    id: plant.id,
                    nickname: plant.nickname,
                    species: plant.species,
                    icon: plant.icon,
                    photoData: plant.photoData,
                    due: WateringDueStatus(nextDue: plant.nextDue, now: now)
                )
            }
            .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
    }

    /// Persist an edit made through the room editor, then reload so the screen reflects it.
    func update(name: String, directSun: LightLevel, indirectSun: LightLevel, humidity: RoomHumidity) {
        guard var updated = room else { return }
        updated.name = name
        updated.directSun = directSun
        updated.indirectSun = indirectSun
        updated.humidity = humidity
        updated.sunlight = Room.legacySunlight(directSun: directSun, indirectSun: indirectSun)
        try? repository.updateRoom(updated)
        load()
    }
}
