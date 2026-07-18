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
    /// Observable notification-permission state driving the home bell + warning banner +
    /// first-run intro.
    @StateObject private var gatekeeper: NotificationGatekeeper
    @Environment(\.scenePhase) private var scenePhase
    @State private var showNotificationIntro = false
    @State private var showLaunchSplash = true

    /// UserDefaults flag so the first-run notification intro shows at most once.
    private static let introSeenKey = "sprout.notificationIntroSeen"

    init() {
        let repository = Self.makeRepository()
        let careDatabase = Self.makeCareDatabase()
        _repository = State(initialValue: repository)
        _careDatabase = State(initialValue: careDatabase)
        _listViewModel = StateObject(
            wrappedValue: PlantListViewModel(
                repository: repository,
                careDatabase: careDatabase,
                environmentFactor: { Self.environmentFactor(for: $0, repository: repository) }
            )
        )
        _gatekeeper = StateObject(wrappedValue: NotificationGatekeeper(
            onAuthorized: { [repository] in
                let hour = UserDefaultsSettingsStore().load().reminderHour
                await WateringNotificationScheduler(reminderHour: hour)
                    .refreshDailyReminders(for: (try? repository.allPlants()) ?? [])
            }
        ))
    }

    var body: some View {
        ZStack {
            HomeView(
                listViewModel: listViewModel,
                gatekeeper: gatekeeper,
                makeEditor: makeEditor,
                makeBasket: makeBasket,
                makePhotoCapture: makePhotoCapture,
                makeDetail: makeDetail,
                makeCheckIn: makeCheckIn,
                makeRooms: makeRooms,
                makeRoomDetail: makeRoomDetail,
                makeSettings: makeSettings,
                makeGuidedWatering: makeGuidedWatering
            )
            // Notifications: explain + ask on first run, then keep the daily digest in sync
            // with the plant data. We rebuild on launch and on every scene-phase change —
            // crucially when the app backgrounds (just before reminders matter) and
            // re-activates — so the digest always reflects the latest schedules without
            // threading the scheduler through every view model.
            .task { await setUpNotifications() }
            .onChange(of: scenePhase) { _, phase in
                guard !DemoSeed.isActive else { return }
                if phase == .active || phase == .background {
                    Task { await refreshReminders() }
                }
                if phase == .active {
                    Task { await gatekeeper.refresh() }
                }
            }
            .sheet(isPresented: $showNotificationIntro) {
                NotificationIntroView(
                    onEnable: {
                        Self.markIntroSeen()
                        showNotificationIntro = false
                        Task { await gatekeeper.enable() }
                    },
                    onSkip: {
                        Self.markIntroSeen()
                        showNotificationIntro = false
                    }
                )
            }

            // Launch splash overlay
            if showLaunchSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .task {
            // Skip splash delay for demo seed so screenshots don't race it
            if DemoSeed.isActive {
                showLaunchSplash = false
            } else {
                // Fade out the splash 0.6s after appear, with ~0.35s fade duration
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    showLaunchSplash = false
                }
            }
        }
    }

    /// First-launch notification setup: install the foreground presenter, read the
    /// current permission status, build the initial daily digest, and — on a genuinely
    /// first run — show the intro before the system prompt. Skipped under the demo seed
    /// so screenshots never prompt or show the bell.
    private func setUpNotifications() async {
        guard !DemoSeed.isActive else {
            #if DEBUG
            // Screenshot hook: `SPROUT_SCREEN=notifyoff` captures the home "reminders off"
            // bell + banner without touching real notification permissions.
            if DemoSeed.requestedScreen == "notifyoff" { gatekeeper.applyDemoStatus(.notDetermined) }
            #endif
            return
        }
        NotificationForegroundPresenter.activate()
        await gatekeeper.refresh()
        await refreshReminders()
        if gatekeeper.status == .notDetermined, !Self.hasSeenIntro {
            showNotificationIntro = true
        }
    }

    private static var hasSeenIntro: Bool { UserDefaults.standard.bool(forKey: introSeenKey) }
    private static func markIntroSeen() { UserDefaults.standard.set(true, forKey: introSeenKey) }

    /// Recompute the daily watering digest from the current plants.
    private func refreshReminders() async {
        guard !DemoSeed.isActive else { return }
        let plants = (try? repository.allPlants()) ?? []
        await currentScheduler().refreshDailyReminders(for: plants)
    }

    /// A scheduler bound to the user's currently-saved reminder hour.
    private func currentScheduler() -> WateringNotificationScheduler {
        WateringNotificationScheduler(reminderHour: UserDefaultsSettingsStore().load().reminderHour)
    }

    /// Build the Rooms view model (T213) against the shared repository.
    private func makeRooms() -> RoomsViewModel {
        RoomsViewModel(repository: repository)
    }

    private func makeRoomDetail(_ roomID: UUID) -> RoomDetailViewModel {
        RoomDetailViewModel(roomID: roomID, repository: repository)
    }

    /// Build the guided-watering coordinator (T215) for a mode: all plants, or only
    /// those due now — both in due-order, against the shared repository + room factor.
    private func makeGuidedWatering(_ mode: GuidedWateringCoordinator.Mode) -> GuidedWateringCoordinator {
        let ordered = PlantListViewModel.ordered((try? repository.allPlants()) ?? [])
        let plants = mode == .due
            ? ordered.filter { WateringDueStatus(nextDue: $0.nextDue, now: Date()).needsWater }
            : ordered
        return GuidedWateringCoordinator(
            plants: plants,
            repository: repository,
            careDatabase: careDatabase,
            mode: mode,
            environmentFactor: { Self.environmentFactor(for: $0, repository: repository) }
        )
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
        PlantEditViewModel(
            mode: mode,
            repository: repository,
            careDatabase: careDatabase,
            camera: makeCamera()
        )
    }

    /// Build the basket add view model (T204) for the room-first add flow (T221)
    /// against the shared repository + care database. Under the demo seed it uses a
    /// fixed RNG seed and pre-fills a couple of entries so the `SPROUT_SCREEN=basket`
    /// screenshot shows a populated basket with stable names. `addflow` lands on the
    /// room step (the new room-first screenshot); `add`/`basket` skip ahead to the
    /// populated plants step with a room pre-selected.
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
            if DemoSeed.requestedScreen == "add" || DemoSeed.requestedScreen == "basket" {
                vm.loadRooms()
                vm.chooseRoom(vm.availableRooms.first)
            }
        } else {
            vm = BasketAddViewModel(repository: repository, careDatabase: careDatabase)
        }
        return vm
    }

    /// Build the Plant Detail view model (T008) for a plant id against the shared
    /// repository + care database, with the plant's room environment factor (T212).
    private func makeDetail(_ plantID: UUID) -> PlantDetailViewModel {
        PlantDetailViewModel(
            plantID: plantID,
            repository: repository,
            careDatabase: careDatabase,
            environmentFactor: environmentFactor(forPlantID: plantID)
        )
    }

    /// Build the Check-in view model (T011) for a plant id against the shared
    /// repository + care database, with the plant's room environment factor (T212).
    private func makeCheckIn(_ plantID: UUID) -> CheckInViewModel {
        CheckInViewModel(
            plantID: plantID,
            repository: repository,
            careDatabase: careDatabase,
            environmentFactor: environmentFactor(forPlantID: plantID)
        )
    }

    /// The room environment factor for a plant by id (neutral if the plant or its
    /// room can't be resolved).
    private func environmentFactor(forPlantID plantID: UUID) -> Double {
        guard let plant = (try? repository.plant(id: plantID)) ?? nil else {
            return ScheduleEngine.defaultWeatherFactor
        }
        return Self.environmentFactor(for: plant, repository: repository)
    }

    /// Build the Settings view model (T014): persisted preferences plus the shared
    /// repository so a reminder-time change reschedules every plant's reminder.
    private func makeSettings() -> SettingsViewModel {
        SettingsViewModel(
            store: UserDefaultsSettingsStore(),
            repository: repository,
            onDataReset: { [listViewModel] in listViewModel.load() }
        )
    }

    /// The schedule multiplier for a plant, derived from its room's environment
    /// (T212) — the indoor replacement for the retired phone-weather factor. Neutral
    /// when the plant has no room or the room can't be resolved.
    static func environmentFactor(for plant: Plant, repository: PlantRepository) -> Double {
        guard let roomID = plant.roomID,
              let room = (try? repository.room(id: roomID)) ?? nil else {
            return ScheduleEngine.defaultWeatherFactor
        }
        return RoomEnvironment.factor(for: room)
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
    func deleteAllPlants() throws {}
    func addCheckIn(_ checkIn: CheckIn, toPlant plantID: UUID) throws {}
    func allRooms() throws -> [Room] { [] }
    func room(id: UUID) throws -> Room? { nil }
    func addRoom(_ room: Room) throws {}
    func updateRoom(_ room: Room) throws {}
    func deleteRoom(id: UUID) throws {}
    func deleteAllRooms() throws {}
}
