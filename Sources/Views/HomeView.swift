import SwiftUI

/// The **home** landing screen (T214): three large tiles — My Plants, Rooms, and
/// "Water your plants" — plus a Settings gear. It owns the app's `NavigationStack`;
/// `PlantListView` and `RoomsView` are pushed as destinations (they no longer carry
/// their own stacks). The Water tile shows how many plants are due.
struct HomeView: View {
    @StateObject private var listViewModel: PlantListViewModel
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    private let makeBasket: (() -> BasketAddViewModel)?
    private let makePhotoCapture: (([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator)?
    private let makeDetail: ((UUID) -> PlantDetailViewModel)?
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    private let makeRooms: () -> RoomsViewModel
    private let makeSettings: () -> SettingsViewModel

    @State private var path = NavigationPath()
    @State private var settingsPresented = false
    @State private var didDeepLink = false

    /// Push destinations for the tiles.
    private enum Route: Hashable { case plants, rooms }

    init(
        listViewModel: PlantListViewModel,
        makeEditor: @escaping (PlantEditViewModel.Mode) -> PlantEditViewModel,
        makeBasket: @escaping () -> BasketAddViewModel,
        makePhotoCapture: @escaping ([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator,
        makeDetail: @escaping (UUID) -> PlantDetailViewModel,
        makeCheckIn: @escaping (UUID) -> CheckInViewModel,
        makeRooms: @escaping () -> RoomsViewModel,
        makeSettings: @escaping () -> SettingsViewModel
    ) {
        _listViewModel = StateObject(wrappedValue: listViewModel)
        self.makeEditor = makeEditor
        self.makeBasket = makeBasket
        self.makePhotoCapture = makePhotoCapture
        self.makeDetail = makeDetail
        self.makeCheckIn = makeCheckIn
        self.makeRooms = makeRooms
        self.makeSettings = makeSettings
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    HomeTile(title: "My Plants", systemImage: "leaf.fill",
                             subtitle: plantsSubtitle, tint: .green) {
                        path.append(Route.plants)
                    }
                    HomeTile(title: "Rooms", systemImage: "house.fill",
                             subtitle: "Light & humidity", tint: .brown) {
                        path.append(Route.rooms)
                    }
                    HomeTile(title: "Water your plants", systemImage: "drop.fill",
                             subtitle: waterSubtitle, tint: .blue) {
                        // T215 replaces this with the guided watering flow.
                        path.append(Route.plants)
                    }
                }
                .padding()
            }
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
        .onAppear {
            listViewModel.load()
            deepLinkIfRequested()
        }
    }

    private var plantsSubtitle: String {
        let n = listViewModel.items.count
        return n == 0 ? "Add your first plant" : "\(n) \(n == 1 ? "plant" : "plants")"
    }

    private var waterSubtitle: String {
        let n = listViewModel.dueCount
        return n == 0 ? "Nothing due — you're on top of it" : "\(n) due now"
    }

    /// Screenshot deep-link (T002 convention). `home`/`list` (default) lands on the
    /// tiles; `plants`/`add`/`basket`/`camera`/`photoprompt` push the list (which
    /// handles its own sheet deep-links); `rooms` pushes Rooms; `settings` opens the
    /// settings sheet.
    private func deepLinkIfRequested() {
        guard !didDeepLink else { return }
        didDeepLink = true
        switch DemoSeed.requestedScreen {
        case "rooms":
            path.append(Route.rooms)
        case "settings":
            settingsPresented = true
        case "plants", "add", "basket", "camera", "photoprompt", "water":
            path.append(Route.plants)
        default:
            break // "home" / "list" → the tiles
        }
    }
}

/// A large, tappable home tile: icon, title, optional subtitle.
private struct HomeTile: View {
    let title: String
    let systemImage: String
    let subtitle: String?
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundStyle(tint)
                    .frame(width: 56, height: 56)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title3.bold()).foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
    }
}
