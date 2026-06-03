import SwiftUI

/// The **home** landing screen: a status-aware greeting over a **bento layout** of
/// vibrant gradient tiles — two square "place" tiles (My Plants, Rooms), a full-width
/// **Add plants** call-to-action, and a "Today" row of two watering actions (**Water**
/// — plants due now, with a count badge — and **Full check-in** — every plant) — plus a
/// Settings gear. It owns the app's `NavigationStack`; `PlantListView` and `RoomsView`
/// are pushed as destinations (they no longer carry their own stacks).
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
    private let makeSettings: () -> SettingsViewModel
    private let makeGuidedWatering: (GuidedWateringCoordinator.Mode) -> GuidedWateringCoordinator

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
        makeSettings: @escaping () -> SettingsViewModel,
        makeGuidedWatering: @escaping (GuidedWateringCoordinator.Mode) -> GuidedWateringCoordinator
    ) {
        _listViewModel = StateObject(wrappedValue: listViewModel)
        _gatekeeper = ObservedObject(wrappedValue: gatekeeper)
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
                VStack(spacing: 16) {
                    // A friendly, status-aware greeting so the screen feels alive.
                    Text(HomeTileText.statusLine(dueCount: listViewModel.dueCount,
                                                 total: listViewModel.items.count))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 2)

                    // Visible warning when reminders are off — tapping it prompts / opens Settings.
                    if gatekeeper.needsAttention {
                        NotificationsOffBanner { Task { await gatekeeper.enable() } }
                    }

                    // Top row: the two "places" — your plants and your rooms.
                    HStack(spacing: 16) {
                        HomeSquareTile(
                            title: "My Plants",
                            caption: HomeTileText.plantsSubtitle(count: listViewModel.items.count),
                            systemImage: "leaf.fill",
                            style: .plants
                        ) { path.append(Route.plants) }

                        HomeSquareTile(
                            title: "Rooms",
                            caption: "Light & humidity",
                            systemImage: "house.fill",
                            style: .rooms
                        ) { path.append(Route.rooms) }
                    }

                    // Full-width primary call-to-action.
                    HomeWideTile(
                        title: "Add plants",
                        subtitle: "Pick a room, then add its plants",
                        systemImage: "plus.circle.fill",
                        style: .add
                    ) { addFlowPresented = true }

                    // Section heading for the two watering actions.
                    Text("Today")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    // Bottom row: the two distinct watering actions.
                    HStack(spacing: 16) {
                        HomeActionTile(
                            title: "Water",
                            subtitle: HomeTileText.waterSubtitle(dueCount: listViewModel.dueCount),
                            systemImage: "drop.fill",
                            style: .water,
                            badge: listViewModel.dueCount > 0 ? "\(listViewModel.dueCount)" : nil,
                            // Draw the eye to watering when something's actually due.
                            pulsing: listViewModel.dueCount > 0
                        ) { startGuided(.due) }

                        HomeActionTile(
                            title: "Full check-in",
                            subtitle: HomeTileText.checkInSubtitle(total: listViewModel.items.count),
                            systemImage: "checklist",
                            style: .checkIn,
                            badge: nil,
                            pulsing: false
                        ) { startGuided(.all) }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground), ignoresSafeAreaEdges: .all)
            .navigationTitle("Sprout")
            .toolbar {
                // A bell with a slash next to the title when reminders are off — tap to
                // enable (prompt, or open Settings if previously denied).
                if gatekeeper.needsAttention {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { Task { await gatekeeper.enable() } } label: {
                            Image(systemName: "bell.slash.fill")
                                .foregroundStyle(.orange)
                        }
                        .accessibilityLabel("Notifications are off — tap to enable")
                    }
                }
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
        count == 0 ? "Add your first plant" : "\(count) \(count == 1 ? "plant" : "plants")"
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

/// The colour treatment for a home tile — a two-tone diagonal gradient and a matching
/// soft shadow, so the grid reads as a vibrant, intentional set rather than flat squares.
struct HomeTileStyle {
    let colors: [Color]

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var shadow: Color { colors.first ?? .black }

    static let plants = HomeTileStyle(colors: [Color(red: 0.36, green: 0.80, blue: 0.46),
                                               Color(red: 0.13, green: 0.62, blue: 0.40)])
    static let rooms = HomeTileStyle(colors: [Color(red: 0.97, green: 0.64, blue: 0.28),
                                              Color(red: 0.88, green: 0.42, blue: 0.24)])
    static let add = HomeTileStyle(colors: [Color(red: 0.22, green: 0.76, blue: 0.70),
                                            Color(red: 0.15, green: 0.52, blue: 0.74)])
    static let water = HomeTileStyle(colors: [Color(red: 0.27, green: 0.67, blue: 0.96),
                                              Color(red: 0.16, green: 0.46, blue: 0.87)])
    static let checkIn = HomeTileStyle(colors: [Color(red: 0.52, green: 0.43, blue: 0.93),
                                                Color(red: 0.37, green: 0.31, blue: 0.82)])
}

/// A frosted icon badge used across the home tiles.
private struct TileIcon: View {
    let systemImage: String
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(.white.opacity(0.22), in: Circle())
    }
}

/// A common gradient-tile container: white content over a gradient with a soft tinted shadow.
private struct TileBackground: ViewModifier {
    let style: HomeTileStyle
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .background(style.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: style.shadow.opacity(0.35), radius: 10, y: 6)
    }
}

/// A square "place" tile (My Plants / Rooms): icon top-left, then title + caption.
private struct HomeSquareTile: View {
    let title: String
    let caption: String
    let systemImage: String
    let style: HomeTileStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                TileIcon(systemImage: systemImage)
                Spacer(minLength: 12)
                Text(title)
                    .font(.title3.bold())
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .aspectRatio(1, contentMode: .fit)
            .padding(18)
            .modifier(TileBackground(style: style))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(caption)")
    }
}

/// A full-width primary call-to-action tile: icon, title + subtitle, trailing chevron.
private struct HomeWideTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let style: HomeTileStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                TileIcon(systemImage: systemImage, size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.title3.bold())
                    Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .modifier(TileBackground(style: style))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

/// A watering-action tile (Water / Full check-in): icon + optional count badge, title, subtitle.
/// When `pulsing`, it gently breathes (scale + glow) to draw the eye to plants needing water.
private struct HomeActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let style: HomeTileStyle
    let badge: String?
    var pulsing: Bool = false
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    TileIcon(systemImage: systemImage)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(.footnote.bold())
                            .foregroundStyle(style.shadow)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.white, in: Capsule())
                    }
                }
                Spacer(minLength: 12)
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(18)
            .modifier(TileBackground(style: style))
            // Breathing glow + scale while plants are due, so the Water tile stands out.
            .scaleEffect(pulsing && pulse ? 1.03 : 1)
            .shadow(color: pulsing ? style.shadow.opacity(pulse ? 0.7 : 0.25) : .clear,
                    radius: pulsing ? (pulse ? 18 : 8) : 0, y: 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            guard pulsing else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(badge.map { "\(title), \($0), \(subtitle)" } ?? "\(title), \(subtitle)")
    }
}

/// A tappable "reminders are off" warning shown on the home when notifications aren't
/// authorised, so the user understands why they're not getting watering reminders.
private struct NotificationsOffBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminders are off")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Turn on notifications so Sprout can remind you to water.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.orange.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Enable notifications")
    }
}
