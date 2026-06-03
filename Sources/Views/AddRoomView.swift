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
        NavigationStack {
            Form {
                Section {
                    Picker("Room type", selection: $selection) {
                        ForEach(RoomPreset.common) { preset in
                            Text(preset.name).tag(preset.name)
                        }
                        Text("Other…").tag(Self.otherTag)
                    }
                    .pickerStyle(.wheel)
                } header: {
                    Text("Room type")
                } footer: {
                    Text(isCustom
                         ? "Name your room and choose its light and humidity."
                         : "Pick a common room and Sprout fills in typical light and humidity — you can fine-tune it later by editing the room.")
                }

                if isCustom {
                    customControls
                } else if let preset = selectedPreset {
                    presetSummary(preset)
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selection) { _, _ in applyPresetDefaults() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(resolvedName, directSun, indirectSun, humidity)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    /// When a preset is chosen, adopt its defaults (so Save uses them even though the
    /// detailed controls are hidden). "Other" keeps whatever's set for manual editing.
    private func applyPresetDefaults() {
        guard let preset = selectedPreset else { return }
        directSun = preset.directSun
        indirectSun = preset.indirectSun
        humidity = preset.humidity
    }

    /// Read-only summary of the typical environment a preset will use.
    private func presetSummary(_ preset: RoomPreset) -> some View {
        Section("Typical settings") {
            LabeledContent("Brightness", value: preset.brightness.label)
            LabeledContent("Humidity", value: preset.humidity.label)
        }
    }

    /// Manual name + light + humidity controls, shown for a custom ("Other") room —
    /// mirrors the editor's controls (with the same info tooltips).
    @ViewBuilder
    private var customControls: some View {
        Section("Name") {
            TextField("Room name", text: $customName)
                .textInputAutocapitalization(.words)
        }
        Section {
            Picker("Direct Sun", selection: $directSun) {
                ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        } header: {
            RoomInfoHeader(title: "Direct Sun",
                           help: "How much direct sunlight lands on the plants — e.g. an unobstructed south-facing windowsill. Direct sun dries the soil fastest.")
        }
        Section {
            Picker("Indirect Sun", selection: $indirectSun) {
                ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        } header: {
            RoomInfoHeader(title: "Indirect Sun",
                           help: "The ambient daylight in the room with no direct beam on the leaves — bright rooms away from a window still get plenty.")
        }
        Section("Humidity") {
            Picker("Humidity", selection: $humidity) {
                ForEach(RoomHumidity.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }
}
