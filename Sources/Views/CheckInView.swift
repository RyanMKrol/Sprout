import SwiftUI
import UIKit

/// The **Check-in flow** screen (T031). Presented from a plant's detail screen: the
/// user records the soil reading, the leaf state, and whether they watered, taps
/// **Save check-in**, and the screen shows the resulting recommendation and updated
/// next-due. Reached for screenshots via the `SPROUT_SCREEN=checkin` deep-link.
///
/// Pure presentation: all engine + persistence wiring lives in `CheckInViewModel`;
/// this view only binds the form inputs and renders the published result.
struct CheckInView: View {
    @StateObject private var viewModel: CheckInViewModel
    private let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CheckInViewModel, onFinish: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        Group {
            if viewModel.loadFailed {
                VStack {
                    Text("Check-in unavailable")
                        .font(SproutFont.display(18))
                        .foregroundStyle(SproutTheme.ink)
                    Text("This plant could not be loaded.")
                        .font(SproutFont.body(14.5))
                        .foregroundStyle(SproutTheme.textMuted)
                }
                .padding()
            } else if let result = viewModel.result {
                resultForm(result)
            } else {
                inputForm
            }
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Input form

    private var inputForm: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Check in",
                confirmLabel: nil,
                onCancel: {
                    onFinish()
                    dismiss()
                },
                onConfirm: {}
            )

            ScrollView {
                VStack(spacing: 20) {
                    // Header: plant token + name + species
                    VStack(spacing: 12) {
                        if let plant = viewModel.plant {
                            PlantToken(
                                icon: plant.icon,
                                duo: PlantTokenPalette.duo(for: plant.id),
                                size: 60,
                                photo: viewModel.plantPhoto
                            )
                        }

                        VStack(spacing: 4) {
                            Text(viewModel.nickname)
                                .font(SproutFont.display(21))
                                .foregroundStyle(SproutTheme.ink)

                            Text(viewModel.species)
                                .font(SproutFont.body(15, weight: .semibold))
                                .italic()
                                .foregroundStyle(SproutTheme.textSecondary)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    // SOIL section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionEyebrow(text: "Soil")
                            .padding(.horizontal, 20)

                        SproutSegmentedPicker(
                            selection: $viewModel.soil,
                            options: [
                                (value: SoilMoisture.dry, label: "Dry"),
                                (value: SoilMoisture.moist, label: "Moist"),
                                (value: SoilMoisture.wet, label: "Wet")
                            ]
                        )
                        .padding(.horizontal, 20)
                    }

                    // LEAVES section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionEyebrow(text: "Leaves")
                            .padding(.horizontal, 20)

                        SproutSegmentedPicker(
                            selection: $viewModel.leaves,
                            options: [
                                (value: LeafState.fine, label: "Fine"),
                                (value: LeafState.droopy, label: "Droopy")
                            ]
                        )
                        .padding(.horizontal, 20)
                    }

                    // Toggle row: "I watered it"
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Text("I watered it")
                                .font(SproutFont.body(17))
                                .foregroundStyle(SproutTheme.ink)

                            Spacer()

                            Toggle("", isOn: $viewModel.watered)
                                .tint(SproutTheme.brandGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .background(SproutTheme.cardSurface)
                    .cornerRadius(SproutTheme.Radius.row)
                    .cardShadow()
                    .padding(.horizontal, 20)

                    // Helper text
                    Text("Sprout learns each plant's true rhythm from these quick reads and adjusts its schedule.")
                        .font(SproutFont.body(12.5))
                        .foregroundStyle(SproutTheme.textHint)
                        .lineLimit(3)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    Spacer()
                }
            }

            // Pinned primary button
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom, 12)

                Button("Save check-in", action: { viewModel.submit() })
                    .buttonStyle(SproutPrimaryButtonStyle())
                .disabled(!viewModel.canCheckIn)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
    }

    // MARK: - Result

    private func resultForm(_ result: CheckInViewModel.Result) -> some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Recommendation",
                confirmLabel: "Done",
                onCancel: {
                    onFinish()
                    dismiss()
                },
                onConfirm: {
                    onFinish()
                    dismiss()
                }
            )

            ScrollView {
                VStack(spacing: 20) {
                    // Centered result card
                    VStack(spacing: 12) {
                        Text(result.message)
                            .font(SproutFont.body(14.5))
                            .foregroundStyle(SproutTheme.ink)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Next watering row
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Text(result.didWater ? "Next watering" : "Check back")
                                .font(SproutFont.body(17))
                                .foregroundStyle(SproutTheme.ink)

                            Spacer()

                            Text(result.nextDue.formatted(.dateTime.day().month().year()))
                                .font(SproutFont.display(17, weight: .semibold))
                                .foregroundStyle(SproutTheme.brandGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .background(SproutTheme.cardSurface)
                    .cornerRadius(SproutTheme.Radius.row)
                    .cardShadow()
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }

            Spacer()
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
    }
}
