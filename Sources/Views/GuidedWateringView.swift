import SwiftUI

/// The **guided watering** walkthrough screen (T215). For each plant it shows the
/// photo + name, asks how it looks (leaves) and how the soil feels, then previews a
/// water/skip recommendation; the user records whether they watered and moves on.
/// Driven entirely by `GuidedWateringCoordinator`.
struct GuidedWateringView: View {
    @StateObject private var coordinator: GuidedWateringCoordinator
    private let onFinish: () -> Void

    init(coordinator: GuidedWateringCoordinator, onFinish: @escaping () -> Void = {}) {
        _coordinator = StateObject(wrappedValue: coordinator)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            Group {
                if let plant = coordinator.current {
                    plantForm(plant)
                } else {
                    completion
                }
            }
            .navigationTitle("Water your plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onFinish() }
                }
                if coordinator.current != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Skip") { coordinator.skip() }
                    }
                }
            }
        }
    }

    // MARK: - Per-plant step

    private func plantForm(_ plant: Plant) -> some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    PlantThumbnail(photoData: plant.photoData, tint: PlantPalette.color(for: plant.id), size: 120)
                    Text(plant.nickname).font(.title2.bold())
                    Text(plant.species.capitalisedWords).font(.subheadline).foregroundStyle(.secondary)
                    Text(coordinator.progressText).font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            if coordinator.hasRecommendation {
                recommendationSection
            } else {
                reportSection
            }
        }
    }

    private var reportSection: some View {
        Group {
            Section("How does it look?") {
                Picker("Leaves", selection: $coordinator.leaves) {
                    Text("Fine").tag(LeafState.fine)
                    Text("Droopy").tag(LeafState.droopy)
                }
                .pickerStyle(.segmented)
            }
            Section("How's the soil?") {
                Picker("Soil", selection: $coordinator.soil) {
                    Text("Dry").tag(SoilMoisture.dry)
                    Text("Moist").tag(SoilMoisture.moist)
                    Text("Wet").tag(SoilMoisture.wet)
                }
                .pickerStyle(.segmented)
            }
            Section {
                Button {
                    coordinator.preview()
                } label: {
                    Text("Check").frame(maxWidth: .infinity).fontWeight(.semibold)
                }
            }
        }
    }

    private var recommendationSection: some View {
        Group {
            Section {
                Text(coordinator.message)
                    .font(.callout.weight(.medium))
            }
            Section {
                if coordinator.recommendsWater {
                    Button {
                        coordinator.confirm(watered: true)
                    } label: {
                        Label("I watered it", systemImage: "drop.fill")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    Button("Didn't water — next") { coordinator.confirm(watered: false) }
                        .frame(maxWidth: .infinity)
                } else {
                    Button {
                        coordinator.confirm(watered: false)
                    } label: {
                        Text("Next plant").frame(maxWidth: .infinity).fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Done

    private var completion: some View {
        ContentUnavailableView {
            Label(coordinator.plants.isEmpty ? "Nothing to water" : "All done", systemImage: "checkmark.circle.fill")
        } description: {
            Text(coordinator.plants.isEmpty
                 ? "No plants need water right now."
                 : "You've been through every plant.")
        } actions: {
            Button("Done") { onFinish() }
                .buttonStyle(.borderedProminent)
        }
    }
}
