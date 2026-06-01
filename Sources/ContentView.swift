import SwiftUI

/// Root screen. Builds the real **My Plants** list (T006) from a
/// `PlantRepository`: the on-disk store in normal use, or a fresh in-memory store
/// pre-seeded with demo plants when launched with `-seedDemoData YES` (T002) so
/// screenshots show real content. A first-run launch with no plants shows the
/// list's empty state.
struct ContentView: View {
    var body: some View {
        PlantListView(viewModel: PlantListViewModel(repository: Self.makeRepository()))
    }

    /// Resolve the repository for this launch: seeded in-memory under
    /// `-seedDemoData YES`, otherwise the persistent on-disk store. Any
    /// construction failure degrades to an empty in-memory store so the UI still
    /// renders (its empty state) rather than crashing.
    private static func makeRepository() -> PlantRepository {
        do {
            return DemoSeed.isActive ? try DemoSeed.seededRepository() : try PlantStore.persistent()
        } catch {
            return (try? PlantStore.inMemory()) ?? EmptyPlantRepository()
        }
    }
}

/// Last-resort no-op repository so `ContentView` can always render. Only reached
/// if even an in-memory `ModelContainer` fails to build.
private struct EmptyPlantRepository: PlantRepository {
    func allPlants() throws -> [Plant] { [] }
    func plant(id: UUID) throws -> Plant? { nil }
    func add(_ plant: Plant) throws {}
    func update(_ plant: Plant) throws {}
    func delete(id: UUID) throws {}
    func addCheckIn(_ checkIn: CheckIn, toPlant plantID: UUID) throws {}
}
