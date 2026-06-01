import SwiftUI

/// The **My Plants** home list (T006). Renders the plants from
/// `PlantListViewModel` as cards — nickname, species, a next-due pill and a
/// water-drop indicator — and a first-run empty state when there are none.
///
/// All ordering / due-date logic lives in the view model; this view is pure
/// presentation, verified by the `-seedDemoData YES` screenshot convention (T002).
struct PlantListView: View {
    @StateObject private var viewModel: PlantListViewModel
    /// Builds the editor view model for an add/edit (T007). When `nil`, the add
    /// button and edit affordance are hidden — keeps the list usable on its own
    /// (e.g. in T006 contexts) without an editor wired in.
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    /// Builds the detail view model for a plant (T008). When `nil`, cards are not
    /// tappable into a detail screen — keeps the list usable on its own.
    private let makeDetail: ((UUID) -> PlantDetailViewModel)?
    /// Builds the check-in view model for a plant (T011), threaded through to the
    /// detail screen's "Check in" affordance. When `nil`, detail hides check-in.
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    /// Builds the Settings view model (T014). When `nil`, the settings button is
    /// hidden — keeps the list usable on its own (e.g. in early tests).
    private let makeSettings: (() -> SettingsViewModel)?
    @State private var editorMode: PlantEditViewModel.Mode?
    @State private var path = NavigationPath()
    @State private var settingsPresented = false
    @State private var didDeepLink = false

    init(
        viewModel: PlantListViewModel,
        makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)? = nil,
        makeDetail: ((UUID) -> PlantDetailViewModel)? = nil,
        makeCheckIn: ((UUID) -> CheckInViewModel)? = nil,
        makeSettings: (() -> SettingsViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeEditor = makeEditor
        self.makeDetail = makeDetail
        self.makeCheckIn = makeCheckIn
        self.makeSettings = makeSettings
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.isEmpty {
                    PlantListEmptyState()
                } else {
                    List(viewModel.items) { item in
                        row(for: item)
                            .swipeActions(edge: .trailing) {
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
                if makeSettings != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            settingsPresented = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
                if makeEditor != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            editorMode = .add
                        } label: {
                            Label("Add Plant", systemImage: "plus")
                        }
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
        .sheet(isPresented: $settingsPresented) {
            if let makeSettings {
                SettingsView(viewModel: makeSettings())
            }
        }
        .onAppear {
            viewModel.load()
            deepLinkIfRequested()
        }
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
    /// `SPROUT_SCREEN=add`, auto-present the Add form once; with `SPROUT_SCREEN=detail`
    /// (or `checkin`), push the first plant's detail screen so the seeded run
    /// captures it — the detail screen then auto-opens its check-in sheet for
    /// `checkin`. No-op in release builds (`requestedScreen` is always `"list"`).
    private func deepLinkIfRequested() {
        guard !didDeepLink else { return }
        didDeepLink = true
        switch DemoSeed.requestedScreen {
        case "add" where makeEditor != nil:
            editorMode = .add
        case "settings" where makeSettings != nil:
            settingsPresented = true
        case "detail", "checkin":
            if makeDetail != nil, let first = viewModel.items.first {
                path.append(first.id)
            }
        default:
            break
        }
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
            Image(systemName: "drop.fill")
                .font(.title3)
                .foregroundStyle(dueColor)
                .accessibilityHidden(true)

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
