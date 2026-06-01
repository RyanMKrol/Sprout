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

    /// Check-ins for this plant. Cascade-deleting the plant removes them too.
    @Relationship(deleteRule: .cascade, inverse: \StoredCheckIn.plant)
    var checkIns: [StoredCheckIn]

    init(
        id: UUID,
        nickname: String,
        species: String,
        adj: Double,
        lastWatered: Date?,
        nextDue: Date?,
        checkIns: [StoredCheckIn] = []
    ) {
        self.id = id
        self.nickname = nickname
        self.species = species
        self.adj = adj
        self.lastWatered = lastWatered
        self.nextDue = nextDue
        self.checkIns = checkIns
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
            checkIns: plant.checkIns.map(StoredCheckIn.init(domain:))
        )
    }

    /// Project back to the pure domain value type, with check-ins in
    /// chronological order.
    func toDomain() -> Plant {
        Plant(
            id: id,
            nickname: nickname,
            species: species,
            adj: adj,
            lastWatered: lastWatered,
            nextDue: nextDue,
            checkIns: checkIns
                .sorted { $0.date < $1.date }
                .map { $0.toDomain() }
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
    }
}
