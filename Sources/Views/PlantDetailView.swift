import SwiftUI

/// The **Plant Detail** screen (T008). Shows a plant's name/species, its current
/// watering schedule (a placeholder summary until the engine lands in T009), and
/// its chronological check-in history. Reached by tapping a card in the My Plants
/// list, and verified by the `-seedDemoData YES` screenshot convention
/// (`SPROUT_SCREEN=detail`).
///
/// Pure presentation: all loading / ordering / derivation lives in
/// `PlantDetailViewModel`; this view only renders its published state.
struct PlantDetailView: View {
    @StateObject private var viewModel: PlantDetailViewModel
    /// Builds the check-in view model (T011) for this plant. When `nil`, the
    /// "Check in" affordance is hidden — keeps the detail screen usable on its own.
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    @State private var checkingIn = false
    @State private var didDeepLink = false

    init(
        viewModel: PlantDetailViewModel,
        makeCheckIn: ((UUID) -> CheckInViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                    Section("Species") {
                        LabeledContent("Species", value: viewModel.species)
                    }

                    Section("Schedule") {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(dueColor)
                                .accessibilityHidden(true)
                            Text(viewModel.due.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(dueColor)
                        }
                        Text(viewModel.explanation?.sentence ?? viewModel.scheduleSummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if makeCheckIn != nil {
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
            }
        }
        .navigationTitle(viewModel.loadFailed ? "Plant" : viewModel.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $checkingIn) {
            if let makeCheckIn {
                CheckInView(viewModel: makeCheckIn(viewModel.plantID)) {
                    // Reload so the updated schedule + new history row show.
                    viewModel.load()
                }
            }
        }
        .onAppear {
            viewModel.load()
            deepLinkIfRequested()
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
