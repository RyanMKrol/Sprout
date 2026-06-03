import SwiftUI
import UIKit

/// The **My Plants** home list (T006). Renders the plants from
/// `PlantListViewModel` as cards — nickname, species, a next-due pill and a
/// water-drop indicator — and a first-run empty state when there are none.
///
/// All ordering / due-date logic lives in the view model; this view is pure
/// presentation, verified by the `-seedDemoData YES` screenshot convention (T002).
struct PlantListView: View {
    @StateObject private var viewModel: PlantListViewModel
    /// Builds the editor view model for editing an existing plant (T007). When
    /// `nil`, the edit swipe-action is hidden. (Adding now goes through the basket
    /// flow — see `makeBasket` — so this drives the edit path only.)
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    /// Builds the basket add view model (T204) — the "+" multi-add flow. When `nil`,
    /// the add button is hidden — keeps the list usable on its own.
    private let makeBasket: (() -> BasketAddViewModel)?
    /// Builds the sequential photo-capture coordinator (T207) for a set of targets.
    /// When `nil`, the photo flow is unavailable.
    private let makePhotoCapture: (([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator)?
    /// Builds the detail view model for a plant (T008). When `nil`, cards are not
    /// tappable into a detail screen — keeps the list usable on its own.
    private let makeDetail: ((UUID) -> PlantDetailViewModel)?
    /// Builds the check-in view model for a plant (T011), threaded through to the
    /// detail screen's "Check in" affordance. When `nil`, detail hides check-in.
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    @State private var editorMode: PlantEditViewModel.Mode?
    @State private var basketPresented = false
    @State private var didDeepLink = false
    /// The photo-capture coordinator, built **once** when the camera launches and held
    /// here so the `.fullScreenCover` doesn't rebuild it (and a fresh `AVCaptureSession`)
    /// on every re-render — multiple sessions crash on device.
    @State private var photoCoordinator: PhotoCaptureCoordinator?
    @State private var photoPresented = false
    /// The just-created plants the "take photos?" prompt offers to photograph (T208),
    /// and whether that prompt sheet is showing (T223 — now a connected sheet).
    @State private var promptTargets: [PhotoCaptureCoordinator.Target] = []
    @State private var photoPromptPresented = false
    /// Set when the photo prompt's "Take Photos" is tapped, so the camera launches from
    /// the prompt sheet's `onDismiss` (avoids a present-while-dismissing race).
    @State private var startPhotosOnDismiss = false

    init(
        viewModel: PlantListViewModel,
        makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)? = nil,
        makeBasket: (() -> BasketAddViewModel)? = nil,
        makePhotoCapture: (([PhotoCaptureCoordinator.Target]) -> PhotoCaptureCoordinator)? = nil,
        makeDetail: ((UUID) -> PlantDetailViewModel)? = nil,
        makeCheckIn: ((UUID) -> CheckInViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeEditor = makeEditor
        self.makeBasket = makeBasket
        self.makePhotoCapture = makePhotoCapture
        self.makeDetail = makeDetail
        self.makeCheckIn = makeCheckIn
    }

    /// De-nested: the host (`HomeView`) provides the `NavigationStack`. This view
    /// supplies the list, its plant-detail destination, the add button, and its sheets.
    var body: some View {
        Group {
            if viewModel.isEmpty {
                PlantListEmptyState()
            } else {
                List(viewModel.items) { item in
                    row(for: item)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(id: item.id)
                            }
                            if makeEditor != nil {
                                Button("Edit") { editorMode = .edit(plantID: item.id) }
                                    .tint(.blue)
                            }
                        }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("My Plants")
        .navigationDestination(for: UUID.self) { plantID in
            if let makeDetail {
                PlantDetailView(
                    viewModel: makeDetail(plantID),
                    makeCheckIn: makeCheckIn
                )
            }
        }
        .toolbar {
            if makeBasket != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        basketPresented = true
                    } label: {
                        Label("Add Plants", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(item: $editorMode) { mode in
            if let makeEditor {
                PlantEditView(viewModel: makeEditor(mode)) {
                    editorMode = nil
                    viewModel.load()
                }
            }
        }
        .sheet(isPresented: $basketPresented, onDismiss: offerPhotosIfJustCreated) {
            if let makeBasket {
                AddFlowView(viewModel: makeBasket()) { result in
                    // Stash created plants (as photo targets) so `onDismiss` can offer to
                    // photograph them once the sheet has fully closed (avoids a present-
                    // while-dismissing race).
                    if case let .created(plants) = result {
                        promptTargets = plants.map(PhotoCaptureCoordinator.Target.init(plant:))
                    }
                    basketPresented = false
                }
            }
        }
        .sheet(isPresented: $photoPromptPresented, onDismiss: launchPhotosIfRequested) {
            PhotoPromptView(
                plants: promptTargets,
                onTakePhotos: {
                    // Build the coordinator (and its single camera session) once, now.
                    dlog("list: 'Take Photos' tapped — building coordinator for \(promptTargets.count) plant(s)")
                    photoCoordinator = makePhotoCapture?(promptTargets)
                    startPhotosOnDismiss = true
                    photoPromptPresented = false
                },
                onSkip: {
                    promptTargets = []
                    photoPromptPresented = false
                }
            )
        }
        .fullScreenCover(isPresented: $photoPresented) {
            let _ = dlog("list: fullScreenCover content — coordinator present=\(photoCoordinator != nil)")
            if let photoCoordinator {
                PhotoCaptureView(coordinator: photoCoordinator) {
                    photoPresented = false
                    self.photoCoordinator = nil
                    viewModel.load()
                }
            }
        }
        .onAppear {
            viewModel.load()
            deepLinkIfRequested()
        }
    }

    /// Called after the basket sheet closes: refresh the list, and if the user just
    /// created plants, offer to photograph them (T208). Runs in `onDismiss` so the
    /// prompt appears only once the sheet has fully gone.
    private func offerPhotosIfJustCreated() {
        viewModel.load()
        if makePhotoCapture != nil, !promptTargets.isEmpty {
            photoPromptPresented = true
        }
    }

    /// After the photo-prompt sheet closes: if the user chose "Take Photos", launch the
    /// sequential camera now (the prompt has fully dismissed, so no presentation race).
    private func launchPhotosIfRequested() {
        guard startPhotosOnDismiss else { return }
        startPhotosOnDismiss = false
        dlog("list: prompt dismissed — presenting camera cover")
        photoPresented = true
    }

    /// A list row: a tappable `NavigationLink` into the plant's detail (T008) when a
    /// `makeDetail` is wired in, otherwise the plain card (keeps the list usable on
    /// its own).
    @ViewBuilder
    private func row(for item: PlantListViewModel.Item) -> some View {
        if makeDetail != nil {
            NavigationLink(value: item.id) {
                PlantCardView(item: item)
            }
        } else {
            PlantCardView(item: item)
        }
    }

    /// Screenshot deep-link (T002 convention): when launched with
    /// `SPROUT_SCREEN=add`/`basket`/`addflow`, auto-present the room-first add flow once; with
    /// `SPROUT_SCREEN=edit`, open the narrowed edit form (T218) for the first plant;
    /// with `SPROUT_SCREEN=detail` (or `checkin`), push the first plant's detail screen
    /// so the seeded run captures it — the detail screen then auto-opens its check-in
    /// sheet for `checkin`. No-op in release builds (`requestedScreen` is always
    /// `"list"`).
    private func deepLinkIfRequested() {
        guard !didDeepLink else { return }
        didDeepLink = true
        switch DemoSeed.requestedScreen {
        case "add", "basket", "addflow":
            if makeBasket != nil { basketPresented = true }
        case "edit" where makeEditor != nil:
            if let first = viewModel.items.first { editorMode = .edit(plantID: first.id) }
        case "camera" where makePhotoCapture != nil:
            let targets = viewModel.items.map {
                PhotoCaptureCoordinator.Target(id: $0.id, nickname: $0.nickname, species: $0.species)
            }
            photoCoordinator = makePhotoCapture?(targets)
            photoPresented = true
        case "photoprompt" where makePhotoCapture != nil:
            // Seed the prompt with the seeded plants so the screenshot shows the
            // connected sheet with real content (T223).
            promptTargets = viewModel.items.map {
                PhotoCaptureCoordinator.Target(id: $0.id, nickname: $0.nickname, species: $0.species)
            }
            photoPromptPresented = true
        default:
            break
        }
    }
}

/// A small rounded plant photo, or a tinted leaf placeholder when there's no photo
/// (T214). Shared by the list card and other compact contexts.
struct PlantThumbnail: View {
    let photoData: Data?
    var tint: Color = .green
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    tint.opacity(0.15)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(tint)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityHidden(true)
    }
}

/// First-run state shown when the user owns no plants yet.
struct PlantListEmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("No plants yet", systemImage: "leaf.fill")
        } description: {
            Text("Add the plants you own and Sprout will keep their watering on track.")
        }
    }
}

/// One row in the My Plants list: water-drop indicator, name + species, and a
/// colour-coded next-due pill.
struct PlantCardView: View {
    let item: PlantListViewModel.Item

    var body: some View {
        HStack(spacing: 12) {
            PlantThumbnail(photoData: item.photoData, tint: dueColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.nickname)
                    .font(.headline)
                Text(item.species)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let whySummary = item.whySummary {
                    Text(whySummary)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(item.due.label)
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(dueColor.opacity(0.15), in: Capsule())
                .foregroundStyle(dueColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Spoken label: name, species, due status, and the "why" summary when present.
    private var accessibilityLabel: String {
        var parts = ["\(item.nickname), \(item.species), \(item.due.label)"]
        if let whySummary = item.whySummary {
            parts.append(whySummary)
        }
        return parts.joined(separator: ", ")
    }

    /// Maps the (pure) due status to a presentation colour — overdue/today read
    /// as urgent, future as calm blue, unscheduled as muted.
    private var dueColor: Color {
        switch item.due {
        case .overdue:
            return .red
        case .dueToday:
            return .orange
        case .due:
            return .blue
        case .unscheduled:
            return .secondary
        }
    }
}
