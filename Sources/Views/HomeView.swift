import SwiftUI

/// The **home** landing screen (Botanical Editorial redesign, T016): a logo lockup +
/// toolbar top bar, a time/status-aware greeting, the `HomeHeroCard` (due / empty /
/// all-watered), a sage/oat bento row (My Plants, Rooms), and a ghost-button row
/// (Add a plant, Check in). It owns the app's `NavigationStack`; `PlantListView` and
/// `RoomsView` are pushed as destinations (they no longer carry their own stacks).
struct HomeView: View {
    @StateObject private var listViewModel: PlantListViewModel
    /// Notification-permission state for the bell indicator + "reminders off" banner.
    @ObservedObject private var gatekeeper: NotificationGatekeeper
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    private let makeBasket: (() -> BasketAddViewModel)?
    private let makePhotoCapture: (([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator)?
    private let makeDetail: ((UUID) -> PlantDetailViewModel)?
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    private let makeRooms: () -> RoomsViewModel
    private let makeRoomDetail: (UUID) -> RoomDetailViewModel
    private let makeSettings: () -> SettingsViewModel
    private let makeGuidedWatering: (GuidedWateringCoordinator.Mode) -> GuidedWateringCoordinator

    /// Backs the Rooms bento tile's "{N} spaces" subtitle — a second, independent
    /// instance of the same view model the Rooms screen itself uses.
    @StateObject private var roomsViewModel: RoomsViewModel

    @State private var path = NavigationPath()
    @State private var settingsPresented = false
    @State private var didDeepLink = false
    // Add-plants flow + its "take photos?" follow-up (T208 pattern), launched from the
    // home Add tile.
    @State private var addFlowPresented = false
    /// The just-created plants the "take photos?" prompt offers to photograph, and whether
    /// that prompt sheet is showing (T223 — now a connected sheet, not a floating dialog).
    @State private var promptTargets: [PhotoCaptureCoordinator.Target] = []
    @State private var photoPromptPresented = false
    /// The single full-screen flow currently presented (camera or guided watering). **One
    /// `.fullScreenCover(item:)` for both** — two separate covers on the same view conflict
    /// on device (one presents an empty/black screen), so they share one source of truth.
    @State private var cover: FullScreenFlow?
    /// Set when the photo prompt's "Take Photos" is tapped, so the camera launches from
    /// the prompt sheet's `onDismiss` (avoids a present-while-dismissing race).
    @State private var startPhotosOnDismiss = false

    /// The mutually-exclusive full-screen flows the home can present. Identifiable so a
    /// single `.fullScreenCover(item:)` drives both — it presents iff non-nil and hands
    /// the unwrapped value to the content closure, so neither can present empty.
    private enum FullScreenFlow: Identifiable {
        case camera(PhotoCaptureCoordinator)
        case guided(GuidedWateringCoordinator)
        var id: UUID {
            switch self {
            case let .camera(coordinator): return coordinator.id
            case let .guided(coordinator): return coordinator.id
            }
        }
    }

    /// Push destinations for the tiles.
    private enum Route: Hashable { case plants, rooms }

    init(
        listViewModel: PlantListViewModel,
        gatekeeper: NotificationGatekeeper,
        makeEditor: @escaping (PlantEditViewModel.Mode) -> PlantEditViewModel,
        makeBasket: @escaping () -> BasketAddViewModel,
        makePhotoCapture: @escaping ([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator,
        makeDetail: @escaping (UUID) -> PlantDetailViewModel,
        makeCheckIn: @escaping (UUID) -> CheckInViewModel,
        makeRooms: @escaping () -> RoomsViewModel,
        makeRoomDetail: @escaping (UUID) -> RoomDetailViewModel,
        makeSettings: @escaping () -> SettingsViewModel,
        makeGuidedWatering: @escaping (GuidedWateringCoordinator.Mode) -> GuidedWateringCoordinator
    ) {
        _listViewModel = StateObject(wrappedValue: listViewModel)
        _gatekeeper = ObservedObject(wrappedValue: gatekeeper)
        _roomsViewModel = StateObject(wrappedValue: makeRooms())
        self.makeEditor = makeEditor
        self.makeBasket = makeBasket
        self.makePhotoCapture = makePhotoCapture
        self.makeDetail = makeDetail
        self.makeCheckIn = makeCheckIn
        self.makeRooms = makeRooms
        self.makeRoomDetail = makeRoomDetail
        self.makeSettings = makeSettings
        self.makeGuidedWatering = makeGuidedWatering
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        HomeLogoLockup()
                        Spacer()
                        if gatekeeper.needsAttention {
                            CircularToolbarButton(icon: .bellSlash, tint: SproutTheme.warningTerracotta) {
                                Task { await gatekeeper.enable() }
                            }
                            .accessibilityLabel("Notifications are off — tap to enable")
                        }
                        CircularToolbarButton(icon: .gear, tint: HomeView.gearTint) {
                            settingsPresented = true
                        }
                        .accessibilityLabel("Settings")
                    }

                    let greeting = HomeHeroCard.greeting(for: heroState, hour: Calendar.current.component(.hour, from: Date()))
                    VStack(alignment: .leading, spacing: 6) {
                        SectionEyebrow(text: greeting.eyebrow)
                        Text(greeting.headline)
                            .font(SproutFont.display(31, weight: .bold))
                            .foregroundStyle(SproutTheme.ink)
                            .lineSpacing(2)
                    }

                    // Visible warning when reminders are off — tapping it prompts / opens Settings.
                    if gatekeeper.needsAttention {
                        HomeRemindersOffBanner { Task { await gatekeeper.enable() } }
                    }

                    HomeHeroCard(state: heroState, onPrimaryTap: heroPrimaryTapped)
                        .frame(minHeight: 300)

                    // Bento row: My Plants (sage) + Rooms (oat).
                    HStack(spacing: 16) {
                        HomeBentoTile(
                            surface: .sage,
                            title: "My Plants",
                            subtitle: HomeTileText.plantsSubtitle(count: listViewModel.items.count),
                            leading: { HomePlantStack(plants: heroPlants) },
                            action: { path.append(Route.plants) }
                        )

                        HomeBentoTile(
                            surface: .oat,
                            title: "Rooms",
                            subtitle: HomeTileText.roomsSubtitle(count: roomsViewModel.items.count),
                            leading: { HomeBentoIconBubble(icon: .house, tint: SproutTheme.oatIcon) },
                            action: { path.append(Route.rooms) }
                        )
                    }

                    // Ghost row: add a plant / check in on everything.
                    HStack(spacing: 12) {
                        Button {
                            addFlowPresented = true
                        } label: {
                            HStack(spacing: 8) {
                                ChromeIcon.plus.image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                Text("Add a plant")
                            }
                        }
                        .buttonStyle(SproutGhostButtonStyle())

                        Button {
                            startGuided(.all)
                        } label: {
                            HStack(spacing: 8) {
                                ChromeIcon.listCheck.image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                Text("Check in")
                            }
                        }
                        .buttonStyle(SproutGhostButtonStyle())
                    }
                }
                .padding()
            }
            .background(SproutTheme.paper, ignoresSafeAreaEdges: .all)
            .navigationBarHidden(true)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .plants:
                    PlantListView(
                        viewModel: listViewModel,
                        makeEditor: makeEditor,
                        makeBasket: makeBasket,
                        makePhotoCapture: makePhotoCapture,
                        makeDetail: makeDetail,
                        makeCheckIn: makeCheckIn
                    )
                case .rooms:
                    RoomsView(viewModel: makeRooms())
                }
            }
            .navigationDestination(for: RoomDetailRoute.self) { route in
                RoomDetailView(
                    viewModel: makeRoomDetail(route.roomID),
                    makeDetail: makeDetail,
                    makeEditor: makeEditor,
                    makeCheckIn: makeCheckIn
                )
            }
        }
        .sheet(isPresented: $settingsPresented) {
            SettingsView(viewModel: makeSettings())
        }
        .sheet(isPresented: $addFlowPresented, onDismiss: offerPhotosIfJustCreated) {
            if let makeBasket {
                AddFlowView(viewModel: makeBasket()) { result in
                    if case let .created(plants) = result {
                        promptTargets = plants.map(PhotoCaptureCoordinator.Target.init(plant:))
                    }
                    addFlowPresented = false
                }
            }
        }
        .sheet(isPresented: $photoPromptPresented, onDismiss: launchPhotosIfRequested) {
            PhotoPromptView(
                plants: promptTargets,
                onTakePhotos: {
                    // Defer building the coordinator until the prompt has fully dismissed
                    // (launchPhotosIfRequested) — avoids a present-while-dismissing race.
                    dlog("home: 'Take Photos' tapped — will launch camera for \(promptTargets.count) plant(s)")
                    startPhotosOnDismiss = true
                    photoPromptPresented = false
                },
                onSkip: {
                    promptTargets = []
                    photoPromptPresented = false
                }
            )
        }
        .fullScreenCover(item: $cover) { flow in
            switch flow {
            case let .camera(coordinator):
                PhotoCaptureView(coordinator: coordinator) {
                    cover = nil
                    listViewModel.load()
                }
            case let .guided(coordinator):
                GuidedWateringView(coordinator: coordinator) {
                    cover = nil
                    listViewModel.load()
                }
            }
        }
        .onAppear {
            listViewModel.load()
            roomsViewModel.load()
            deepLinkIfRequested()
        }
    }

    /// Gear icon tint (`#4A5142`) — a design-token color not needed elsewhere in the
    /// shared `SproutTheme`, so it lives beside its one use.
    private static let gearTint = Color(red: 74.0 / 255, green: 81.0 / 255, blue: 66.0 / 255)

    /// The plants that need water now, in list order — feeds both the hero card's
    /// avatar stack and the My Plants bento tile's token stack.
    private var heroPlants: [Plant] {
        listViewModel.items
            .filter { $0.due.needsWater }
            .map(HomeView.plant(from:))
    }

    /// Reconstructs a display-only `Plant` from a list item (the view model doesn't
    /// retain the original `icon`/room fields, so this uses the species' default icon
    /// — acceptable since the token prefers the plant's photo when one exists).
    private static func plant(from item: PlantListViewModel.Item) -> Plant {
        Plant(id: item.id, nickname: item.nickname, species: item.species, photoData: item.photoData)
    }

    /// The soonest-scheduled plant among those *not* needing water now, for the
    /// all-watered hero's "Next up: {plant} in {N} days." line.
    private var soonestScheduled: (name: String, days: Int)? {
        for item in listViewModel.items {
            if case let .due(days) = item.due {
                return (item.nickname, days)
            }
        }
        return nil
    }

    /// The hero card's state, derived from the list's due data (T016 spec §3, screens
    /// 02/03/03b): no plants → empty; some due → due; none due → all watered.
    private var heroState: HomeHeroState {
        if listViewModel.items.isEmpty {
            return .empty
        }
        let due = heroPlants
        if !due.isEmpty {
            return .due(count: due.count, plants: due)
        }
        return .allWatered(next: soonestScheduled)
    }

    /// The hero card's primary button routes to guided watering when plants are due,
    /// or the add flow when the garden is empty; it has no button in the all-watered state.
    private func heroPrimaryTapped() {
        switch heroState {
        case .due:
            startGuided(.due)
        case .empty:
            addFlowPresented = true
        case .allWatered:
            break
        }
    }

    /// After the add-flow sheet closes: refresh the list, and if the user just created
    /// plants, offer to photograph them (T208). Runs in `onDismiss` so the prompt appears
    /// only once the sheet has fully gone.
    private func offerPhotosIfJustCreated() {
        listViewModel.load()
        roomsViewModel.load()
        if makePhotoCapture != nil, !promptTargets.isEmpty {
            photoPromptPresented = true
        }
    }

    /// After the photo-prompt sheet closes: if the user chose "Take Photos", launch the
    /// sequential camera now (the prompt has fully dismissed, so no presentation race).
    private func launchPhotosIfRequested() {
        guard startPhotosOnDismiss else { return }
        startPhotosOnDismiss = false
        dlog("home: prompt dismissed — building coordinator + presenting camera cover")
        // Setting the cover's `item` presents it — one source of truth, so it can't
        // appear without a coordinator.
        if let coordinator = makePhotoCapture?(promptTargets) {
            cover = .camera(coordinator)
        }
    }

    /// Build the guided coordinator for `mode` and present the walkthrough.
    private func startGuided(_ mode: GuidedWateringCoordinator.Mode) {
        cover = .guided(makeGuidedWatering(mode))
    }

    /// Screenshot deep-link (T002 convention). `home`/`list` (default) lands on the
    /// grid; `plants`/`add`/`basket`/`addflow`/`camera`/`photoprompt`/`edit` push the list
    /// (which handles its own sheet deep-links — `addflow` opens the room-first add flow);
    /// `rooms` pushes Rooms; `settings` opens the settings sheet; `water` starts a check-in.
    private func deepLinkIfRequested() {
        guard !didDeepLink else { return }
        didDeepLink = true
        switch DemoSeed.requestedScreen {
        case "rooms", "roomeditor", "addroom":
            // `roomeditor`/`addroom` push Rooms, which then auto-opens its editor / add flow.
            path.append(Route.rooms)
        case "roomdetail":
            // Push Rooms, then the first room's detail (screen 15).
            path.append(Route.rooms)
            if let first = roomsViewModel.items.first?.room.id {
                path.append(RoomDetailRoute(roomID: first))
            }
        case "settings":
            settingsPresented = true
        case "plants", "add", "basket", "addflow", "camera", "photoprompt", "edit":
            path.append(Route.plants)
        case "detail", "checkin":
            // Push the list, then the first plant's detail (the detail screen itself
            // opens its check-in sheet when the screen is `checkin`).
            path.append(Route.plants)
            if let first = listViewModel.items.first?.id { path.append(first) }
        case "water":
            startGuided(.all)
        default:
            break // "home" / "list" → the grid
        }
    }
}

/// Pure tile-subtitle text, factored out so the home grid's copy is unit-testable
/// without instantiating the SwiftUI view (T222).
enum HomeTileText {
    static func plantsSubtitle(count: Int) -> String {
        count == 0 ? "None yet" : "\(count) growing"
    }

    /// The Rooms bento tile's subtitle (T016 §3): "{N} spaces" once any room
    /// exists, else a nudge to set one up.
    static func roomsSubtitle(count: Int) -> String {
        count == 0 ? "Set one up" : "\(count) \(count == 1 ? "space" : "spaces")"
    }

    static func waterSubtitle(dueCount: Int) -> String {
        dueCount == 0 ? "Nothing due right now" : "\(dueCount) due now"
    }

    static func checkInSubtitle(total: Int) -> String {
        total == 0 ? "No plants yet" : "Check every plant"
    }

    /// The friendly, status-aware greeting line shown above the tiles.
    static func statusLine(dueCount: Int, total: Int) -> String {
        if total == 0 { return "Let's add your first plant 🌱" }
        if dueCount == 0 { return "Everything's watered — nice work 🌿" }
        return "\(dueCount) \(dueCount == 1 ? "plant needs" : "plants need") water today 💧"
    }
}
