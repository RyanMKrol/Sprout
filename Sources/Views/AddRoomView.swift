import SwiftUI

/// The **Add Room** flow: pick a common room type from a wheel (Living Room, Kitchen, …)
/// and get sensible default light + humidity automatically, or pick **Other** to name it
/// yourself and choose the settings by hand. Editing an existing room still uses the
/// fuller `RoomEditorView` (free name + manual controls).
///
/// Calls back with the final `(name, directSun, indirectSun, humidity)` so it's a drop-in
/// for the same `onSave` the editor used. Pure presentation over `RoomPreset`.
struct AddRoomView: View {
    let onSave: (String, LightLevel, LightLevel, RoomHumidity) -> Void
    let onCancel: () -> Void

    /// The selected room-type tag: a preset name, or `otherTag` for a custom room.
    @State private var selection: String
    @State private var customName: String = ""
    @State private var directSun: LightLevel
    @State private var indirectSun: LightLevel
    @State private var humidity: RoomHumidity

    private static let otherTag = "__other__"

    init(
        onSave: @escaping (String, LightLevel, LightLevel, RoomHumidity) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        let first = RoomPreset.common[0]
        _selection = State(initialValue: first.name)
        _directSun = State(initialValue: first.directSun)
        _indirectSun = State(initialValue: first.indirectSun)
        _humidity = State(initialValue: first.humidity)
    }

    /// The chosen preset, or `nil` when "Other" (custom) is selected.
    private var selectedPreset: RoomPreset? {
        RoomPreset.common.first { $0.name == selection }
    }

    private var isCustom: Bool { selection == Self.otherTag }

    /// The final room name to save: the preset's name, or the trimmed custom name.
    private var resolvedName: String {
        isCustom ? customName.trimmingCharacters(in: .whitespacesAndNewlines) : (selectedPreset?.name ?? "")
    }

    private var canSave: Bool { !resolvedName.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Add Room",
                confirmLabel: "Add",
                confirmEnabled: canSave,
                onCancel: onCancel,
                onConfirm: {
                    onSave(resolvedName, directSun, indirectSun, humidity)
                }
            )

            ScrollView {
                VStack(spacing: 20) {
                    // ROOM TYPE section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ROOM TYPE")
                            .font(SproutFont.body(11, weight: .semibold))
                            .tracking(0.56)
                            .foregroundStyle(SproutTheme.taupe)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20).padding(.top, 0)

                        VStack(spacing: 0) {
                            Picker("Room type", selection: $selection) {
                                ForEach(RoomPreset.common) { preset in
                                    Text(preset.name).tag(preset.name)
                                }
                                Text("Other…").tag(Self.otherTag)
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 200)

                            if let preset = selectedPreset {
                                Text(preset.name)
                                    .font(SproutFont.display(20))
                                    .foregroundStyle(SproutTheme.ink)
                                    .padding(.vertical, 16)
                            } else {
                                Text("Other…")
                                    .font(SproutFont.display(20))
                                    .foregroundStyle(SproutTheme.ink)
                                    .padding(.vertical, 16)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(SproutTheme.cardSurface)
                        .cornerRadius(SproutTheme.Radius.row)
                        .cardShadow()
                    }

                    // TYPICAL SETTINGS or CUSTOM CONTROLS
                    if isCustom {
                        customControlsSection
                    } else if let preset = selectedPreset {
                        presetSummarySection(preset)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }

            // Footer hint
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom, 16)

                Text(
                    "Pick a common room and Sprout fills in typical light and "
                        + "humidity — fine-tune it later by editing the room."
                )
                    .font(SproutFont.body(12.5))
                    .foregroundStyle(SproutTheme.textHint)
                    .lineLimit(3)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
        .onChange(of: selection) { _, _ in applyPresetDefaults() }
    }

    /// When a preset is chosen, adopt its defaults (so Save uses them even though the
    /// detailed controls are hidden). "Other" keeps whatever's set for manual editing.
    private func applyPresetDefaults() {
        guard let preset = selectedPreset else { return }
        directSun = preset.directSun
        indirectSun = preset.indirectSun
        humidity = preset.humidity
    }

    /// White card showing the typical brightness and humidity for the selected preset.
    @ViewBuilder
    private func presetSummarySection(_ preset: RoomPreset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TYPICAL SETTINGS")
                .font(SproutFont.body(11, weight: .semibold))
                .tracking(0.56)
                .foregroundStyle(SproutTheme.taupe)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(spacing: 0) {
                // Brightness row
                HStack(spacing: 12) {
                    Text("Brightness")
                        .font(SproutFont.body(15))
                        .foregroundStyle(SproutTheme.ink)

                    Spacer()

                    BrightnessChip(text: preset.brightness.label)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                Divider()
                    .padding(.horizontal, 16)

                // Humidity row
                HStack(spacing: 12) {
                    Text("Humidity")
                        .font(SproutFont.body(15))
                        .foregroundStyle(SproutTheme.ink)

                    Spacer()

                    HumidityChip(text: preset.humidity.label)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .background(SproutTheme.cardSurface)
            .cornerRadius(SproutTheme.Radius.row)
            .cardShadow()
            .padding(.horizontal, 0)
        }
    }

    /// Manual name + light + humidity controls, shown for a custom ("Other") room.
    @ViewBuilder
    private var customControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CUSTOM ROOM")
                .font(SproutFont.body(11, weight: .semibold))
                .tracking(0.56)
                .foregroundStyle(SproutTheme.taupe)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Room name", text: $customName)
                        .font(SproutFont.body(15))
                        .foregroundStyle(SproutTheme.ink)
                        .textInputAutocapitalization(.words)
                        .padding(16)
                        .background(SproutTheme.cardSurface)
                        .cornerRadius(SproutTheme.Radius.field)
                }

                // Direct Sun
                VStack(alignment: .leading, spacing: 8) {
                    RoomInfoHeader(
                        title: "Direct Sun",
                        help: "How much direct sunlight lands on the plants — e.g. an "
                            + "unobstructed south-facing windowsill. Direct sun dries the "
                            + "soil fastest."
                    )

                    Picker("Direct Sun", selection: $directSun) {
                        ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // Indirect Sun
                VStack(alignment: .leading, spacing: 8) {
                    RoomInfoHeader(
                        title: "Indirect Sun",
                        help: "The ambient daylight in the room with no direct beam on "
                            + "the leaves — bright rooms away from a window still get "
                            + "plenty."
                    )

                    Picker("Indirect Sun", selection: $indirectSun) {
                        ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // Humidity
                VStack(alignment: .leading, spacing: 8) {
                    RoomInfoHeader(
                        title: "Humidity",
                        help: "How much moisture is in the air. Moist rooms (bathrooms, "
                            + "kitchens) mean slower soil drying; dry rooms (living rooms "
                            + "with heat) mean faster drying."
                    )

                    Picker("Humidity", selection: $humidity) {
                        ForEach(RoomHumidity.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(16)
            .background(SproutTheme.cardSurface)
            .cornerRadius(SproutTheme.Radius.row)
            .cardShadow()
        }
    }
}

// MARK: - Chip components

private struct BrightnessChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SproutFont.body(11, weight: .semibold))
            .foregroundStyle(SproutTheme.brightnessChip)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 217.0 / 255, green: 139.0 / 255, blue: 10.0 / 255, opacity: 0.14))
            .cornerRadius(SproutTheme.Radius.chip)
    }
}

private struct HumidityChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SproutFont.body(11, weight: .semibold))
            .foregroundStyle(SproutTheme.brandGreen)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(SproutTheme.softGreenFill)
            .cornerRadius(SproutTheme.Radius.chip)
    }
}
