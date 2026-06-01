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

    init(viewModel: PlantDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                        Text(viewModel.scheduleSummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
        .onAppear { viewModel.load() }
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
