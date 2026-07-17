import SwiftUI

/// The **guided watering** walkthrough screen (screens 20–22, redesign). For each plant it shows
/// the photo + name, asks how it looks (leaves) and how the soil feels, then previews a
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
        ZStack {
            SproutTheme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                progressBar

                if let plant = coordinator.current {
                    if coordinator.hasRecommendation {
                        actionStep(plant)
                    } else {
                        reportStep(plant)
                    }
                } else {
                    completionStep
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button("Close", action: onFinish)
                .font(SproutFont.body(17, weight: .semibold))
                .foregroundStyle(SproutTheme.brandGreen)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Water your plants")
                .font(SproutFont.display(17, weight: .bold))
                .foregroundStyle(SproutTheme.ink)

            if coordinator.current != nil {
                Button("Skip", action: { coordinator.skip() })
                    .font(SproutFont.body(17, weight: .semibold))
                    .foregroundStyle(SproutTheme.brandGreen)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(SproutTheme.progressTrack)

                if !coordinator.plants.isEmpty {
                    let fillWidth = geo.size.width * CGFloat(coordinator.index) / CGFloat(coordinator.plants.count)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SproutTheme.brandGreen)
                        .frame(width: fillWidth)
                }
            }
        }
        .frame(height: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Report step (screen 20)

    private func reportStep(_ plant: Plant) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection(plant)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionEyebrow(text: "How does it look?")
                            leavesPicker
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionEyebrow(text: "How's the soil?")
                            soilPicker
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }

            Spacer(minLength: 16)

            Button(action: { coordinator.preview() }) {
                Text("Check")
            }
            .buttonStyle(SproutPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Action step (screen 21)

    private func actionStep(_ plant: Plant) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection(plant)
                    .padding(.bottom, 40)

                    VStack(spacing: 12) {
                        recommendationCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.vertical, 20)
            }

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                if coordinator.recommendsWater {
                    Button(action: { coordinator.confirm(watered: true) }) {
                        HStack(spacing: 6) {
                            Text("💧")
                            Text("I watered it")
                        }
                    }
                    .buttonStyle(SproutPrimaryButtonStyle())

                    Button(action: { coordinator.confirm(watered: false) }) {
                        Text("Didn't water — next")
                    }
                    .font(SproutFont.body(17, weight: .semibold))
                    .foregroundStyle(SproutTheme.brandGreen)
                } else {
                    Button(action: { coordinator.confirm(watered: false) }) {
                        Text("Next plant")
                    }
                    .buttonStyle(SproutPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Pickers

    private var leavesPicker: some View {
        SproutSegmentedPicker(
            selection: $coordinator.leaves,
            options: [
                (value: LeafState.fine, label: "Fine"),
                (value: LeafState.droopy, label: "Droopy")
            ]
        )
    }

    private var soilPicker: some View {
        SproutSegmentedPicker(
            selection: $coordinator.soil,
            options: [
                (value: SoilMoisture.dry, label: "Dry"),
                (value: SoilMoisture.moist, label: "Moist"),
                (value: SoilMoisture.wet, label: "Wet")
            ]
        )
    }

    // MARK: - Hero section (report + action)

    private func heroSection(_ plant: Plant) -> some View {
        VStack(spacing: 12) {
            PlantThumbnail(photoData: plant.photoData, tint: PlantPalette.color(for: plant.id), size: 120)

            Text(plant.nickname)
                .font(SproutFont.display(22, weight: .bold))
                .foregroundStyle(SproutTheme.ink)

            Text("\(plant.species.capitalisedWords) · \(coordinator.progressText)")
                .font(SproutFont.body(17).italic())
                .foregroundStyle(SproutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recommendation card

    private var recommendationCard: some View {
        VStack(spacing: 16) {
            let presentation = RecommendationPresentation.present(
                coordinator.recommendation ?? WateringRecommendation(
                    action: .monitor,
                    reason: .droopyMoist,
                    days: 0
                ),
                nextDue: nil,
                calendar: Calendar.current,
                now: Date()
            )

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(presentation.tint.opacity(0.12))
                        .frame(width: 78, height: 78)

                    presentation.icon.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                        .foregroundStyle(presentation.tint)
                }

                Text(presentation.headline)
                    .font(SproutFont.display(20, weight: .bold))
                    .foregroundStyle(SproutTheme.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 26)
        .sproutCard(radius: 22)
    }

    // MARK: - Completion step (screen 22)

    private var completionStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SproutTheme.brandGreen)
                                .frame(width: 104, height: 104)

                            ChromeIcon.circleCheck.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 46, height: 46)
                                .foregroundStyle(Color.white)
                        }

                        Text("All done 🌿")
                            .font(SproutFont.display(27, weight: .bold))
                            .foregroundStyle(SproutTheme.ink)

                        Text("You've been through every plant that needed water today.")
                            .font(SproutFont.body(15))
                            .foregroundStyle(SproutTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 40)
            }

            Spacer(minLength: 16)

            Button(action: onFinish) {
                Text("Done")
            }
            .buttonStyle(SproutPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}
