import SwiftUI

/// The **Plant Detail** screen (T008). Shows a plant's photo + name as a prominent
/// header, its current watering schedule (tappable to override the cadence by hand),
/// and its chronological check-in history. An **Edit** button (top right) opens the
/// edit form to change the nickname, room, or photo. Reached by tapping a card in the
/// My Plants list, and verified by the `-seedDemoData YES` screenshot convention
/// (`SPROUT_SCREEN=detail`).
///
/// Pure presentation: all loading / ordering / derivation lives in
/// `PlantDetailViewModel`; this view only renders its published state.
struct PlantDetailView: View {
    @StateObject private var viewModel: PlantDetailViewModel
    /// Builds the edit form (T007/T218) for this plant. When `nil`, the Edit button is
    /// hidden — keeps the detail screen usable on its own.
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    /// Builds the check-in view model (T011) for this plant. When `nil`, the
    /// "Check in" affordance is hidden — keeps the detail screen usable on its own.
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    @State private var checkingIn = false
    @State private var editingPlant = false
    @State private var editingSchedule = false
    /// The value bound to the manual "due in N days" wheel while its sheet is open.
    @State private var scheduleDays = 7
    @State private var didDeepLink = false

    init(
        viewModel: PlantDetailViewModel,
        makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)? = nil,
        makeCheckIn: ((UUID) -> CheckInViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeEditor = makeEditor
        self.makeCheckIn = makeCheckIn
    }

    var body: some View {
        Group {
            if viewModel.loadFailed {
                ContentUnavailableView(
                    "Plant unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This plant could not be loaded.")
                )
            } else {
                Form {
                    header
                    scheduleSection
                    if makeCheckIn != nil { checkInSection }
                    historySection
                }
                // Pull the form up under the bar so the photo isn't floating in empty space.
                .contentMargins(.top, 8, for: .scrollContent)
            }
        }
        // No title text in the bar: the big in-content header already names the plant,
        // so a bar title would just duplicate it. (Inline + empty keeps the back chevron.)
        .navigationTitle(viewModel.loadFailed ? "Plant" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if makeEditor != nil, !viewModel.loadFailed {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { editingPlant = true }
                }
            }
        }
        .sheet(isPresented: $checkingIn) {
            if let makeCheckIn {
                CheckInView(viewModel: makeCheckIn(viewModel.plantID)) {
                    // Reload so the updated schedule + new history row show.
                    viewModel.load()
                }
            }
        }
        .sheet(isPresented: $editingPlant) {
            if let makeEditor {
                PlantEditView(viewModel: makeEditor(.edit(plantID: viewModel.plantID))) {
                    // Reload so an edited nickname / room / photo shows immediately.
                    editingPlant = false
                    viewModel.load()
                }
            }
        }
        .sheet(isPresented: $editingSchedule) {
            ScheduleEditorSheet(days: $scheduleDays) {
                viewModel.setDueInDays(scheduleDays)
                editingSchedule = false
            } onCancel: {
                editingSchedule = false
            }
        }
        .onAppear {
            viewModel.load()
            deepLinkIfRequested()
        }
    }

    // MARK: - Sections

    /// The prominent header: a photo, the nickname, and the species below it. Flush at
    /// the top (no extra section padding) so it doesn't float in empty space.
    private var header: some View {
        Section {
            VStack(spacing: 12) {
                PlantThumbnail(
                    photoData: viewModel.photoData,
                    tint: PlantPalette.color(for: viewModel.plantID),
                    size: 170
                )
                VStack(spacing: 4) {
                    Text(viewModel.nickname)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(viewModel.species.capitalisedWords)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private var scheduleSection: some View {
        Section("Schedule") {
            Button {
                scheduleDays = viewModel.daysUntilDue
                editingSchedule = true
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(dueColor)
                        .accessibilityHidden(true)
                    Text(viewModel.due.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(dueColor)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
            .accessibilityHint("Adjust when this plant is next due")

            Text(viewModel.explanation?.sentence ?? viewModel.scheduleSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var checkInSection: some View {
        Section {
            Button {
                checkingIn = true
            } label: {
                Label("Check in", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
        }
    }

    private var historySection: some View {
        Section("Check-in history") {
            if viewModel.hasHistory {
                ForEach(viewModel.history) { item in
                    CheckInRow(item: item)
                }
            } else {
                Text("No check-ins yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Screenshot deep-link (T002 convention): when launched with
    /// `SPROUT_SCREEN=checkin`, auto-present the check-in sheet once so the seeded
    /// run captures it. No-op otherwise / in release builds.
    private func deepLinkIfRequested() {
        guard !didDeepLink else { return }
        didDeepLink = true
        if DemoSeed.requestedScreen == "checkin", makeCheckIn != nil {
            checkingIn = true
        }
    }

    /// Maps the (pure) due status to a presentation colour — matching the list pill.
    private var dueColor: Color {
        switch viewModel.due {
        case .overdue: return .red
        case .dueToday: return .orange
        case .due: return .blue
        case .unscheduled: return .secondary
        }
    }
}

/// A small sheet with a day wheel for overriding when a plant is next due by hand.
private struct ScheduleEditorSheet: View {
    @Binding var days: Int
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Adjust schedule",
                confirmLabel: "Save",
                onCancel: onCancel,
                onConfirm: onSave
            )

            ScrollView {
                VStack(spacing: 16) {
                    Text("Water this plant in")
                        .font(SproutFont.body(15, weight: .semibold))
                        .foregroundStyle(SproutTheme.textMuted)
                        .frame(maxWidth: .infinity)

                    Picker("Days until due", selection: $days) {
                        ForEach(0...365, id: \.self) { day in
                            Text(day == 0 ? "Today" : "\(day) \(day == 1 ? "day" : "days")").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 200)

                    Text("Sets the next-watering date. Future check-ins keep adapting it.")
                        .font(SproutFont.body(13))
                        .foregroundStyle(SproutTheme.textHint)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }

            Spacer()
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
        .presentationDetents([.medium])
    }
}

#Preview {
    VStack {
        Text("Sheet Preview")
            .font(.title)
            .foregroundStyle(SproutTheme.ink)
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SproutTheme.paper)
    .sheet(isPresented: .constant(true)) {
        ScheduleEditorSheet(
            days: .constant(7),
            onSave: {},
            onCancel: {}
        )
    }
}

/// One row of check-in history: when, what the soil/leaves looked like, and whether
/// the user watered.
private struct CheckInRow: View {
    let item: PlantDetailViewModel.HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.date, format: .dateTime.day().month().year())
                    .font(.subheadline.weight(.medium))
                Spacer()
                if item.watered {
                    Label("Watered", systemImage: "drop.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.blue)
                        .accessibilityLabel("Watered")
                }
            }
            Text("Soil \(soilLabel) · Leaves \(leafLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var soilLabel: String {
        switch item.soil {
        case .dry: return "dry"
        case .moist: return "moist"
        case .wet: return "wet"
        }
    }

    private var leafLabel: String {
        switch item.leaves {
        case .fine: return "fine"
        case .droopy: return "droopy"
        }
    }
}
