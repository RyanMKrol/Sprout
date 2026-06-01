import SwiftUI

/// The **Check-in flow** screen (T011). Presented from a plant's detail screen: the
/// user records the soil reading, the leaf state, and whether they watered, taps
/// **Save check-in**, and the screen shows the resulting recommendation and updated
/// next-due. Reached for screenshots via the `SPROUT_SCREEN=checkin` deep-link.
///
/// Pure presentation: all engine + persistence wiring lives in `CheckInViewModel`;
/// this view only binds the form inputs and renders the published result.
struct CheckInView: View {
    @StateObject private var viewModel: CheckInViewModel
    /// Called when the user dismisses after a saved check-in, so the presenter (the
    /// detail screen) can reload its updated schedule.
    private let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CheckInViewModel, onFinish: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.loadFailed {
                    ContentUnavailableView(
                        "Check-in unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text("This plant could not be loaded.")
                    )
                } else if let result = viewModel.result {
                    resultForm(result)
                } else {
                    inputForm
                }
            }
            .navigationTitle(viewModel.hasResult ? "Recommendation" : "Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.hasResult ? "Done" : "Cancel") {
                        onFinish()
                        dismiss()
                    }
                }
            }
            .onAppear { viewModel.load() }
        }
    }

    // MARK: - Input form

    private var inputForm: some View {
        Form {
            Section("Soil") {
                Picker("Soil", selection: $viewModel.soil) {
                    Text("Dry").tag(SoilMoisture.dry)
                    Text("Moist").tag(SoilMoisture.moist)
                    Text("Wet").tag(SoilMoisture.wet)
                }
                .pickerStyle(.segmented)
            }

            Section("Leaves") {
                Picker("Leaves", selection: $viewModel.leaves) {
                    Text("Fine").tag(LeafState.fine)
                    Text("Droopy").tag(LeafState.droopy)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("I watered it", isOn: $viewModel.watered)
            } footer: {
                Text("Sprout learns each plant's true rhythm from these quick reads and adjusts its schedule.")
            }

            Section {
                Button {
                    viewModel.submit()
                } label: {
                    Text("Save check-in")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .disabled(!viewModel.canCheckIn)
            } footer: {
                if !viewModel.canCheckIn {
                    Text("This plant's species isn't in the care database, so its schedule can't be adapted yet.")
                }
            }
        }
    }

    // MARK: - Result

    private func resultForm(_ result: CheckInViewModel.Result) -> some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: actionIcon(result.recommendation.action))
                        .font(.title2)
                        .foregroundStyle(actionColor(result.recommendation.action))
                        .accessibilityHidden(true)
                    Text(result.message)
                        .font(.callout.weight(.medium))
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(result.message)
            } header: {
                Text(viewModel.nickname.isEmpty ? "Recommendation" : viewModel.nickname)
            }

            Section("Next") {
                LabeledContent(
                    result.didWater ? "Next watering" : "Check back",
                    value: result.nextDue.formatted(.dateTime.day().month().year())
                )
            }
        }
    }

    private func actionIcon(_ action: WateringRecommendation.Action) -> String {
        switch action {
        case .waterNow, .waterLightly: return "drop.fill"
        case .skip: return "hand.raised.fill"
        case .monitor: return "eye.fill"
        }
    }

    private func actionColor(_ action: WateringRecommendation.Action) -> Color {
        switch action {
        case .waterNow: return .blue
        case .waterLightly: return .teal
        case .skip: return .orange
        case .monitor: return .secondary
        }
    }
}
