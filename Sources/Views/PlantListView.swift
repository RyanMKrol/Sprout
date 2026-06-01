import SwiftUI

/// The **My Plants** home list (T006). Renders the plants from
/// `PlantListViewModel` as cards — nickname, species, a next-due pill and a
/// water-drop indicator — and a first-run empty state when there are none.
///
/// All ordering / due-date logic lives in the view model; this view is pure
/// presentation, verified by the `-seedDemoData YES` screenshot convention (T002).
struct PlantListView: View {
    @StateObject private var viewModel: PlantListViewModel

    init(viewModel: PlantListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    PlantListEmptyState()
                } else {
                    List(viewModel.items) { item in
                        PlantCardView(item: item)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Plants")
        }
        .onAppear { viewModel.load() }
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
        .accessibilityLabel("\(item.nickname), \(item.species), \(item.due.label)")
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
