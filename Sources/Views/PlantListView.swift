import SwiftUI
import UIKit

/// The **My Plants** home list (T017). Renders the plants from
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
    @Environment(\.dismiss) private var dismiss
    @State private var editorMode: PlantEditViewModel.Mode?
    @State private var basketPresented = false
    @State private var didDeepLink = false
    @State private var deleteConfirmationPresented = false
    @State private var plantToDelete: PlantListViewModel.Item?
    /// The photo-capture coordinator. **It is the single source of truth for the camera
    /// cover** — the `.fullScreenCover(item:)` presents iff this is non-nil, so the cover
    /// can never appear with a nil coordinator (the black-screen bug). Built once, when
    /// the camera launches (so its single `AVCaptureSession` isn't rebuilt per re-render).
    @State private var photoCoordinator: PhotoCaptureCoordinator?
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
                    PlantListEmptyState(onAddPlants: { basketPresented = true })
                } else {
                    List(viewModel.items) { item in
                        row(for: item)
                            .listRowBackground(SproutTheme.paper)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    plantToDelete = item
                                    deleteConfirmationPresented = true
                                }
                                if makeEditor != nil {
                                    Button("Edit") { editorMode = .edit(plantID: item.id) }
                                        .tint(SproutTheme.swipeEdit)
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .background(SproutTheme.paper)
            .navigationTitle("My Plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if makeBasket != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { basketPresented = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(SproutTheme.brandGreen)
                        .accessibilityLabel("Add plants")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { plantID in
            if let makeDetail {
                PlantDetailView(
                    viewModel: makeDetail(plantID),
                    makeEditor: makeEditor,
                    makeCheckIn: makeCheckIn
                )
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
                    dlog("list: 'Take Photos' tapped — will launch camera for \(promptTargets.count) plant(s)")
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
            _ = dlog("list: fullScreenCover content — presenting camera (targets=\(coordinator.targets.count))")
            return PhotoCaptureView(coordinator: coordinator) {
                self.photoCoordinator = nil
                viewModel.load()
            }
        }
        .sproutAlert(isPresented: $deleteConfirmationPresented) {
            deleteAlert()
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
        dlog("list: prompt dismissed — building coordinator + presenting camera cover")
        // Building the coordinator here sets the cover's `item`, which presents it —
        // one source of truth, so the cover can't appear without a coordinator.
        photoCoordinator = makePhotoCapture?(promptTargets)
    }

    /// Renders the delete confirmation alert, or an empty alert if no plant is selected.
    private func deleteAlert() -> SproutAlert {
        guard let plant = plantToDelete else {
            return SproutAlert(
                icon: .trash,
                tint: SproutTheme.destructive,
                title: "Error",
                message: "No plant selected",
                confirmLabel: "OK",
                onConfirm: {
                    deleteConfirmationPresented = false
                },
                onCancel: {
                    deleteConfirmationPresented = false
                }
            )
        }
        return SproutAlert(
            icon: .trash,
            tint: SproutTheme.destructive,
            title: "Delete \(plant.nickname)?",
            message: "This removes the plant and its check-in history. This can't be undone.",
            confirmLabel: "Delete",
            confirmRole: .destructive,
            onConfirm: {
                viewModel.delete(id: plant.id)
                plantToDelete = nil
                deleteConfirmationPresented = false
            },
            onCancel: {
                plantToDelete = nil
                deleteConfirmationPresented = false
            }
        )
    }

    /// A list row: a tappable `NavigationLink` into the plant's detail (T008) when a
    /// `makeDetail` is wired in, otherwise the plain card (keeps the list usable on
    /// its own).
    @ViewBuilder
    private func row(for item: PlantListViewModel.Item) -> some View {
        if makeDetail != nil {
            // Suppress the List's automatic NavigationLink disclosure chevron on the
            // custom card: the value-based link sits behind the card at zero opacity
            // (still fully tappable), and the card itself carries no caret.
            ZStack {
                NavigationLink(value: item.id) { EmptyView() }
                    .opacity(0)
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

/// First-run state shown when the user owns no plants yet (T017 redesign).
struct PlantListEmptyState: View {
    let onAddPlants: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            PlantToken(icon: .flower, duo: PlantTokenPalette.green, size: 84)

            Text("No plants yet")
                .font(SproutFont.display(22))
                .foregroundStyle(SproutTheme.ink)

            Text("Add the plants you own and Sprout will keep their watering on track.")
                .font(SproutFont.body(14.5))
                .foregroundStyle(SproutTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Button(action: onAddPlants) {
                Text("Add your first plant")
            }
            .buttonStyle(SproutPrimaryButtonStyle())
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.vertical, 40)
    }
}

/// One row in the My Plants list: plant token, name + species, meta + cadence, and a
/// colour-coded next-due chip (T017 redesign).
struct PlantCardView: View {
    let item: PlantListViewModel.Item

    var body: some View {
        HStack(spacing: 14) {
            PlantTokenView(item: item)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.nickname)
                    .font(SproutFont.display(18))
                    .foregroundStyle(SproutTheme.ink)

                Text(item.species)
                    .font(SproutFont.bodyItalic(12.5))
                    .foregroundStyle(SproutTheme.textSecondary)

                if let whySummary = item.whySummary {
                    Text(metaLabel(whySummary))
                        .font(SproutFont.body(11.5, weight: .semibold))
                        .foregroundStyle(SproutTheme.taupe)
                }
            }

            Spacer()

            DueChip(status: dueStatus)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .sproutCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Extracts cadence + adaptation suffix from the why summary.
    /// E.g., "Every 4d · shortened" → "Every 4d · shortened".
    private func metaLabel(_ summary: String) -> String {
        summary
    }

    /// Converts WateringDueStatus to DueStatus for the chip.
    private var dueStatus: DueStatus {
        switch item.due {
        case .overdue(let days):
            return .overdue(days: days)
        case .dueToday:
            return .dueToday
        case .due(let days):
            return .due(inDays: days)
        case .unscheduled:
            return .unscheduled
        }
    }

    /// Spoken label: name, species, due status, and the "why" summary when present.
    private var accessibilityLabel: String {
        var parts = ["\(item.nickname), \(item.species), \(item.due.label)"]
        if let whySummary = item.whySummary {
            parts.append(whySummary)
        }
        return parts.joined(separator: ", ")
    }
}

/// The circular plant token (46pt) with photo clipping or gradient + icon.
private struct PlantTokenView: View {
    let item: PlantListViewModel.Item

    var body: some View {
        let icon = PlantIcon.flower
        let duo = PlantTokenPalette.duo(for: item.id)
        let photo = item.photoData.flatMap { UIImage(data: $0) }

        PlantToken(icon: icon, duo: duo, size: 46, photo: photo)
            .frame(width: 46, height: 46)
    }
}
