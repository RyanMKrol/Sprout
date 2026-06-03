import SwiftUI

/// The **home** landing screen (T222): a playful 2-column grid of **square tiles** —
/// My Plants, Rooms, Add plants (launches the T221 room-first flow), and two distinct
/// watering tiles, **Water your plants** (plants due now) and **Full check-in** (every
/// plant) — plus a Settings gear. It owns the app's `NavigationStack`; `PlantListView`
/// and `RoomsView` are pushed as destinations (they no longer carry their own stacks).
struct HomeView: View {
    @StateObject private var listViewModel: PlantListViewModel
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    private let makeBasket: (() -> BasketAddViewModel)?
    private let makePhotoCapture: (([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator)?
    private let makeDetail: ((UUID) -> PlantDetailViewModel)?
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    private let makeRooms: () -> RoomsViewModel
    private let makeSettings: () -> SettingsViewModel
    private let makeGuidedWatering: (GuidedWateringCoordinator.Mode) -> GuidedWateringCoordinator

    @State private var path = NavigationPath()
    @State private var settingsPresented = false
    @State private var guided: GuidedWateringCoordinator?
    @State private var guidedPresented = false
    @State private var didDeepLink = false
    // Add-plants flow + its "take photos?" follow-up (T208 pattern), launched from the
    // home Add tile.
    @State private var addFlowPresented = false
    /// The just-created plants the "take photos?" prompt offers to photograph, and whether
    /// that prompt sheet is showing (T223 — now a connected sheet, not a floating dialog).
    @State private var promptTargets: [PhotoCaptureCoordinator.Target] = []
    @State private var photoPromptPresented = false
    /// The photo-capture coordinator. **It is the single source of truth for the camera
    /// cover** — the `.fullScreenCover(item:)` presents iff this is non-nil, so the cover
    /// can never appear with a nil coordinator (the black-screen bug). Built once, when
    /// the camera launches (so its single `AVCaptureSession` isn't rebuilt per re-render).
    @State private var photoCoordinator: PhotoCaptureCoordinator?
    /// Set when the photo prompt's "Take Photos" is tapped, so the camera launches from
    /// the prompt sheet's `onDismiss` (avoids a present-while-dismissing race).
    @State private var startPhotosOnDismiss = false

    /// Push destinations for the tiles.
    private enum Route: Hashable { case plants, rooms }

    /// Two square tiles per row.
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    init(
        listViewModel: PlantListViewModel,
        makeEditor: @escaping (PlantEditViewModel.Mode) -> PlantEditViewModel,
        makeBasket: @escaping () -> BasketAddViewModel,
        makePhotoCapture: @escaping ([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator,
        makeDetail: @escaping (UUID) -> PlantDetailViewModel,
        makeCheckIn: @escaping (UUID) -> CheckInViewModel,
        makeRooms: @escaping () -> RoomsViewModel,
        makeSettings: @escaping () -> SettingsViewModel,
        makeGuidedWatering: @escaping (GuidedWateringCoordinator.Mode) -> GuidedWateringCoordinator
    ) {
        _listViewModel = StateObject(wrappedValue: listViewModel)
        self.makeEditor = makeEditor
        self.makeBasket = makeBasket
        self.makePhotoCapture = makePhotoCapture
        self.makeDetail = makeDetail
        self.makeCheckIn = makeCheckIn
        self.makeRooms = makeRooms
        self.makeSettings = makeSettings
        self.makeGuidedWatering = makeGuidedWatering
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    HomeTile(title: "My Plants", systemImage: "leaf.fill",
                             subtitle: HomeTileText.plantsSubtitle(count: listViewModel.items.count),
                             tint: .green) {
                        path.append(Route.plants)
                    }
                    HomeTile(title: "Rooms", systemImage: "house.fill",
                             subtitle: "Light & humidity", tint: .brown) {
                        path.append(Route.rooms)
                    }
                    HomeTile(title: "Add plants", systemImage: "plus.circle.fill",
                             subtitle: "Pick a room, add its plants", tint: .teal) {
                        addFlowPresented = true
                    }
                    HomeTile(title: "Water your plants", systemImage: "drop.fill",
                             subtitle: HomeTileText.waterSubtitle(dueCount: listViewModel.dueCount),
                             tint: .blue) {
                        startGuided(.due)
                    }
                    HomeTile(title: "Full check-in", systemImage: "checklist",
                             subtitle: HomeTileText.checkInSubtitle(total: listViewModel.items.count),
                             tint: .indigo) {
                        startGuided(.all)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground), ignoresSafeAreaEdges: .all)
            .navigationTitle("Sprout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { settingsPresented = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
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
        .fullScreenCover(item: $photoCoordinator) { coordinator in
            let _ = dlog("home: fullScreenCover content — presenting camera (targets=\(coordinator.targets.count))")
            PhotoCaptureView(coordinator: coordinator) {
                self.photoCoordinator = nil
                listViewModel.load()
            }
        }
        .fullScreenCover(isPresented: $guidedPresented) {
            if let guided {
                GuidedWateringView(coordinator: guided) {
                    guidedPresented = false
                    listViewModel.load()
                }
            }
        }
        .onAppear {
            listViewModel.load()
            deepLinkIfRequested()
        }
    }

    /// After the add-flow sheet closes: refresh the list, and if the user just created
    /// plants, offer to photograph them (T208). Runs in `onDismiss` so the prompt appears
    /// only once the sheet has fully gone.
    private func offerPhotosIfJustCreated() {
        listViewModel.load()
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
        // Building the coordinator here sets the cover's `item`, which presents it —
        // one source of truth, so the cover can't appear without a coordinator.
        photoCoordinator = makePhotoCapture?(promptTargets)
    }

    /// Build the guided coordinator for `mode` and present the walkthrough.
    private func startGuided(_ mode: GuidedWateringCoordinator.Mode) {
        guided = makeGuidedWatering(mode)
        guidedPresented = true
    }

    /// Screenshot deep-link (T002 convention). `home`/`list` (default) lands on the
    /// grid; `plants`/`add`/`basket`/`addflow`/`camera`/`photoprompt`/`edit` push the list
    /// (which handles its own sheet deep-links — `addflow` opens the room-first add flow);
    /// `rooms` pushes Rooms; `settings` opens the settings sheet; `water` starts a check-in.
    private func deepLinkIfRequested() {
        guard !didDeepLink else { return }
        didDeepLink = true
        switch DemoSeed.requestedScreen {
        case "rooms", "roomeditor":
            // `roomeditor` pushes Rooms, which then auto-opens its editor (T220 screenshot).
            path.append(Route.rooms)
        case "settings":
            settingsPresented = true
        case "plants", "add", "basket", "addflow", "camera", "photoprompt", "edit":
            path.append(Route.plants)
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
        count == 0 ? "Add your first plant" : "\(count) \(count == 1 ? "plant" : "plants")"
    }

    static func waterSubtitle(dueCount: Int) -> String {
        dueCount == 0 ? "Nothing due right now" : "\(dueCount) due now"
    }

    static func checkInSubtitle(total: Int) -> String {
        total == 0 ? "No plants yet" : "Check every plant"
    }
}

/// A playful **square** home tile: a tinted icon badge over a bold title and an optional
/// subtitle, filling a grid cell with a 1:1 aspect ratio (T222).
private struct HomeTile: View {
    let title: String
    let systemImage: String
    let subtitle: String?
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundStyle(tint)
                    .frame(width: 56, height: 56)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .aspectRatio(1, contentMode: .fit)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
    }
}
