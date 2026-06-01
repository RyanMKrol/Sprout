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
    /// The current forecast-derived weather multiplier (T016), fed into the detail
    /// "why" explanation and the check-in recompute. Neutral until the live fetch
    /// resolves; a fixed warm-spell value under `-seedDemoData` so screenshots are
    /// deterministic (no CoreLocation prompt).
    @State private var weatherFactor: Double = ScheduleEngine.defaultWeatherFactor

    init() {
        let repository = Self.makeRepository()
        let careDatabase = Self.makeCareDatabase()
        _repository = State(initialValue: repository)
        _careDatabase = State(initialValue: careDatabase)
        _listViewModel = StateObject(
            wrappedValue: PlantListViewModel(repository: repository, careDatabase: careDatabase)
        )
        _weatherFactor = State(initialValue: Self.initialWeatherFactor())
    }

    var body: some View {
        PlantListView(
            viewModel: listViewModel,
            makeEditor: makeEditor,
            makeBasket: makeBasket,
            makePhotoCapture: makePhotoCapture,
            makeDetail: makeDetail,
            makeCheckIn: makeCheckIn,
            makeSettings: makeSettings
        )
        .task { await refreshWeatherFactor() }
    }

    /// Build the photo-capture source. The real `AVFoundationCamera` only runs on a
    /// device; the simulator and the demo seed use the stub so screenshots/tests
    /// never touch hardware or trigger a permission prompt.
    private func makeCamera() -> PhotoCapturing {
        #if targetEnvironment(simulator)
        return StubPhotoCapturing()
        #else
        return DemoSeed.isActive ? StubPhotoCapturing() : AVFoundationCamera()
        #endif
    }

    /// Build a photo-capture coordinator for the given targets against the shared
    /// repository + a camera (T206/T207).
    private func makePhotoCapture(_ targets: [PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator {
        PhotoCaptureCoordinator(targets: targets, repository: repository, camera: makeCamera())
    }

    /// Build the Edit view model against the shared repository + care database. (Used
    /// only for the edit-swipe path now; adding goes through the basket — `makeBasket`.)
    private func makeEditor(_ mode: PlantEditViewModel.Mode) -> PlantEditViewModel {
        PlantEditViewModel(mode: mode, repository: repository, careDatabase: careDatabase)
    }

    /// Build the basket add view model (T204) against the shared repository + care
    /// database. Under the demo seed it uses a fixed RNG seed and pre-fills a couple
    /// of entries so the `SPROUT_SCREEN=basket` screenshot shows a populated basket
    /// with stable names.
    private func makeBasket() -> BasketAddViewModel {
        let vm: BasketAddViewModel
        if DemoSeed.isActive {
            vm = BasketAddViewModel(
                repository: repository,
                careDatabase: careDatabase,
                rng: SeededRandomNumberGenerator(seed: 20_260_601)
            )
            for species in DemoSeed.basketSampleSpecies {
                if let profile = careDatabase.profile(forSpecies: species) { vm.add(profile) }
            }
        } else {
            vm = BasketAddViewModel(repository: repository, careDatabase: careDatabase)
        }
        return vm
    }

    /// Build the Plant Detail view model (T008) for a plant id against the shared
    /// repository + care database.
    private func makeDetail(_ plantID: UUID) -> PlantDetailViewModel {
        PlantDetailViewModel(
            plantID: plantID,
            repository: repository,
            careDatabase: careDatabase,
            weatherFactor: weatherFactor
        )
    }

    /// Build the Check-in view model (T011) for a plant id against the shared
    /// repository + care database, with the current weather factor (T016).
    private func makeCheckIn(_ plantID: UUID) -> CheckInViewModel {
        CheckInViewModel(
            plantID: plantID,
            repository: repository,
            careDatabase: careDatabase,
            weatherFactor: weatherFactor
        )
    }

    /// Build the Settings view model (T014): persisted preferences plus the shared
    /// repository so a reminder-time change reschedules every plant's reminder.
    private func makeSettings() -> SettingsViewModel {
        SettingsViewModel(store: UserDefaultsSettingsStore(), repository: repository)
    }

    /// The factor to start with before any live fetch resolves. Under
    /// `-seedDemoData` this is the fixed demo warm-spell factor so screenshots are
    /// deterministic and never trigger a location prompt; otherwise neutral.
    private static func initialWeatherFactor() -> Double {
        DemoSeed.isActive ? DemoSeed.weatherFactor : ScheduleEngine.defaultWeatherFactor
    }

    /// Refresh `weatherFactor` from the live forecast (T015/T016). Skipped under the
    /// demo seed (kept at the fixed factor) and when the user has turned weather
    /// adaptation off in Settings; any location/network failure falls back to the
    /// neutral factor inside `WeatherFactorService`, so this never throws or blocks.
    private func refreshWeatherFactor() async {
        guard !DemoSeed.isActive else { return }
        guard UserDefaultsSettingsStore().load().weatherEnabled else {
            weatherFactor = ScheduleEngine.defaultWeatherFactor
            return
        }
        let service = WeatherFactorService(
            locationProvider: CoreLocationProvider(),
            weatherProvider: OpenMeteoWeatherProvider()
        )
        weatherFactor = await service.currentWeatherFactor()
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
