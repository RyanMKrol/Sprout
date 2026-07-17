import Foundation
import SwiftData

/// SwiftData persistence record for a `Plant`. Lives behind the
/// `PlantRepository` boundary — callers never see this type, only the pure
/// domain `Plant` it maps to/from.
@Model
final class StoredPlant {
    /// Mirrors `Plant.id`; unique so a domain plant maps to exactly one record.
    @Attribute(.unique) var id: UUID
    var nickname: String
    var species: String
    var adj: Double
    var lastWatered: Date?
    var nextDue: Date?

    /// An optional plant photo (JPEG bytes). `.externalStorage` spills the blob to
    /// a sidecar file rather than inlining it in the SQLite row, so the common
    /// `allPlants()` fetch (which only needs scalars) stays cheap.
    @Attribute(.externalStorage) var photoData: Data?

    /// The id of the room this plant lives in, if any (linked by id, not a SwiftData
    /// relationship — `RoomRepository` deletion nils this rather than cascading).
    var roomID: UUID?

    /// Check-ins for this plant. Cascade-deleting the plant removes them too.
    @Relationship(deleteRule: .cascade, inverse: \StoredCheckIn.plant)
    var checkIns: [StoredCheckIn]

    /// The chosen `PlantIcon` rawValue, if set. Optional so existing rows open via
    /// lightweight migration; `nil` (or an unrecognised value) falls back to
    /// `PlantIcon.default(forSpecies:)` on the way back to the domain model.
    var iconName: String?

    init(
        id: UUID,
        nickname: String,
        species: String,
        adj: Double,
        lastWatered: Date?,
        nextDue: Date?,
        checkIns: [StoredCheckIn] = [],
        photoData: Data? = nil,
        roomID: UUID? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.species = species
        self.adj = adj
        self.lastWatered = lastWatered
        self.nextDue = nextDue
        self.checkIns = checkIns
        self.photoData = photoData
        self.roomID = roomID
        self.iconName = iconName
    }
}

/// SwiftData persistence record for a `Room`. Linked to plants by `StoredPlant.roomID`
/// (no SwiftData relationship), so deleting a room simply nils its plants' `roomID`.
@Model
final class StoredRoom {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Legacy coarse sunlight (T211) — kept defaulted so existing stores still open.
    var sunlight: SunlightLevel
    /// T220 light inputs. Optional + additive: existing rows open as `nil` and fall
    /// back to values derived from `sunlight`, so there is no migration.
    var directSun: LightLevel?
    var indirectSun: LightLevel?
    var humidity: RoomHumidity

    init(
        id: UUID,
        name: String,
        sunlight: SunlightLevel,
        directSun: LightLevel? = nil,
        indirectSun: LightLevel? = nil,
        humidity: RoomHumidity
    ) {
        self.id = id
        self.name = name
        self.sunlight = sunlight
        self.directSun = directSun
        self.indirectSun = indirectSun
        self.humidity = humidity
    }
}

/// SwiftData persistence record for a `CheckIn`.
@Model
final class StoredCheckIn {
    /// Mirrors `CheckIn.id`.
    @Attribute(.unique) var id: UUID
    var date: Date
    var soil: SoilMoisture
    var leaves: LeafState
    var watered: Bool

    /// The owning plant (inverse of `StoredPlant.checkIns`).
    var plant: StoredPlant?

    init(
        id: UUID,
        date: Date,
        soil: SoilMoisture,
        leaves: LeafState,
        watered: Bool,
        plant: StoredPlant? = nil
    ) {
        self.id = id
        self.date = date
        self.soil = soil
        self.leaves = leaves
        self.watered = watered
        self.plant = plant
    }
}

// MARK: - Domain mapping

extension StoredCheckIn {
    /// Build a persistence record from a domain check-in.
    convenience init(domain checkIn: CheckIn) {
        self.init(
            id: checkIn.id,
            date: checkIn.date,
            soil: checkIn.soil,
            leaves: checkIn.leaves,
            watered: checkIn.watered
        )
    }

    /// Project back to the pure domain value type.
    func toDomain() -> CheckIn {
        CheckIn(id: id, date: date, soil: soil, leaves: leaves, watered: watered)
    }
}

extension StoredPlant {
    /// Build a persistence record (and its check-in children) from a domain plant.
    convenience init(domain plant: Plant) {
        self.init(
            id: plant.id,
            nickname: plant.nickname,
            species: plant.species,
            adj: plant.adj,
            lastWatered: plant.lastWatered,
            nextDue: plant.nextDue,
            checkIns: plant.checkIns.map(StoredCheckIn.init(domain:)),
            photoData: plant.photoData,
            roomID: plant.roomID,
            iconName: plant.icon.rawValue
        )
    }

    /// Project back to the pure domain value type, with check-ins in
    /// chronological order. `iconName` is decoded via `PlantIcon(rawValue:)`,
    /// falling back to the species default when `nil` or unrecognised.
    func toDomain() -> Plant {
        let icon = iconName.flatMap(PlantIcon.init(rawValue:)) ?? PlantIcon.default(forSpecies: species)
        return Plant(
            id: id,
            nickname: nickname,
            species: species,
            adj: adj,
            lastWatered: lastWatered,
            nextDue: nextDue,
            checkIns: checkIns
                .sorted { $0.date < $1.date }
                .map { $0.toDomain() },
            photoData: photoData,
            roomID: roomID,
            icon: icon
        )
    }

    /// Copy the mutable scalar fields of a domain plant onto this record.
    /// Check-ins are managed separately via `addCheckIn(_:toPlant:)`.
    func applyScalars(from plant: Plant) {
        nickname = plant.nickname
        species = plant.species
        adj = plant.adj
        lastWatered = plant.lastWatered
        nextDue = plant.nextDue
        photoData = plant.photoData
        roomID = plant.roomID
        iconName = plant.icon.rawValue
    }
}

extension StoredRoom {
    /// Build a persistence record from a domain room.
    convenience init(domain room: Room) {
        self.init(
            id: room.id,
            name: room.name,
            sunlight: room.sunlight,
            directSun: room.directSun,
            indirectSun: room.indirectSun,
            humidity: room.humidity
        )
    }

    /// Project back to the pure domain value type. Rows written before T220 have nil
    /// light levels — fall back to values derived from the legacy `sunlight` field.
    func toDomain() -> Room {
        let fallback = Room.lightLevels(for: sunlight)
        return Room(
            id: id,
            name: name,
            directSun: directSun ?? fallback.direct,
            indirectSun: indirectSun ?? fallback.indirect,
            humidity: humidity,
            sunlight: sunlight
        )
    }

    /// Copy the mutable scalar fields of a domain room onto this record.
    func applyScalars(from room: Room) {
        name = room.name
        sunlight = room.sunlight
        directSun = room.directSun
        indirectSun = room.indirectSun
        humidity = room.humidity
    }
}
