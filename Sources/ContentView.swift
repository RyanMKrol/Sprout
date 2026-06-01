import SwiftUI

/// Root screen. Builds the real **My Plants** list (T006) from a
/// `PlantRepository`: the on-disk store in normal use, or a fresh in-memory store
/// pre-seeded with demo plants when launched with `-seedDemoData YES` (T002) so
/// screenshots show real content. A first-run launch with no plants shows the
/// list's empty state.
struct ContentView: View {
    /// The shared store for this launch — held in `@State` so it is created **once**
    /// and the same instance backs both the list and the Add/Edit editor (T007),
    /// so a saved plant shows up when the list reloads.
    @State private var repository: PlantRepository
    /// The bundled care database (T004), the source of the editor's species picker.
    @State private var careDatabase: CareDatabase
    @StateObject private var listViewModel: PlantListViewModel

    init() {
        let repository = Self.makeRepository()
        _repository = State(initialValue: repository)
        _careDatabase = State(initialValue: Self.makeCareDatabase())
        _listViewModel = StateObject(wrappedValue: PlantListViewModel(repository: repository))
    }

    var body: some View {
        PlantListView(viewModel: listViewModel, makeEditor: makeEditor, makeDetail: makeDetail)
    }

    /// Build the Add/Edit view model against the shared repository + care database.
    private func makeEditor(_ mode: PlantEditViewModel.Mode) -> PlantEditViewModel {
        PlantEditViewModel(mode: mode, repository: repository, careDatabase: careDatabase)
    }

    /// Build the Plant Detail view model (T008) for a plant id against the shared
    /// repository + care database.
    private func makeDetail(_ plantID: UUID) -> PlantDetailViewModel {
        PlantDetailViewModel(plantID: plantID, repository: repository, careDatabase: careDatabase)
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

    /// Load the bundled care database; an empty database if it can't be read so the
    /// editor still presents (with no species to pick) rather than crashing.
    private static func makeCareDatabase() -> CareDatabase {
        (try? CareDatabase.loadBundled()) ?? CareDatabase(profiles: [])
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
