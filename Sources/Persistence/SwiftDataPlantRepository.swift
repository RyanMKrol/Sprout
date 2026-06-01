import Foundation
import SwiftData

/// SwiftData-backed `PlantRepository`. The only place (besides `StoredModels`)
/// that touches SwiftData — callers go through the protocol.
final class SwiftDataPlantRepository: PlantRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allPlants() throws -> [Plant] {
        let descriptor = FetchDescriptor<StoredPlant>(
            sortBy: [SortDescriptor(\.nickname)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func plant(id: UUID) throws -> Plant? {
        try fetch(id: id)?.toDomain()
    }

    func add(_ plant: Plant) throws {
        context.insert(StoredPlant(domain: plant))
        try context.save()
    }

    func update(_ plant: Plant) throws {
        guard let stored = try fetch(id: plant.id) else {
            throw PlantRepositoryError.notFound(plant.id)
        }
        stored.applyScalars(from: plant)
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let stored = try fetch(id: id) else {
            throw PlantRepositoryError.notFound(id)
        }
        context.delete(stored)
        try context.save()
    }

    func addCheckIn(_ checkIn: CheckIn, toPlant plantID: UUID) throws {
        guard let stored = try fetch(id: plantID) else {
            throw PlantRepositoryError.notFound(plantID)
        }
        let record = StoredCheckIn(domain: checkIn)
        record.plant = stored
        stored.checkIns.append(record)
        try context.save()
    }

    /// Fetch the single stored record for `id`, if any.
    private func fetch(id: UUID) throws -> StoredPlant? {
        var descriptor = FetchDescriptor<StoredPlant>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

/// Builds `PlantRepository` instances, keeping SwiftData container/context
/// construction inside the persistence module so callers (app + tests) never
/// import SwiftData themselves.
enum PlantStore {
    /// The model types this store manages.
    static let schema = Schema([StoredPlant.self, StoredCheckIn.self])

    /// A repository backed by a fresh in-memory container — for tests and
    /// ephemeral previews. Nothing is written to disk.
    static func inMemory() throws -> PlantRepository {
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataPlantRepository(context: ModelContext(container))
    }

    /// A repository backed by the on-disk store — for the running app.
    static func persistent() throws -> PlantRepository {
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: false)
        )
        return SwiftDataPlantRepository(context: ModelContext(container))
    }
}
