import SwiftUI

/// The **Rooms** screen (T213). Lists the user's rooms (name, environment summary,
/// plant count) and supports add / edit / delete. A room's sunlight + humidity drive
/// the watering cadence of the plants assigned to it. Pure presentation over
/// `RoomsViewModel`.
struct RoomsView: View {
    @StateObject private var viewModel: RoomsViewModel
    @State private var editor: Editor?

    init(viewModel: RoomsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    /// What the editor sheet is doing.
    private enum Editor: Identifiable {
        case add
        case edit(Room)
        var id: String {
            switch self {
            case .add: return "add"
            case let .edit(room): return room.id.uuidString
            }
        }
    }

    var body: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("No rooms yet", systemImage: "house")
                } description: {
                    Text("Add the rooms your plants live in. Their light and humidity set each plant's watering rhythm.")
                }
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        Button {
                            editor = .edit(item.room)
                        } label: {
                            RoomRow(item: item)
                        }
                        .tint(.primary)
                    }
                    .onDelete { viewModel.delete(atOffsets: $0) }
                }
            }
        }
        .navigationTitle("Rooms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editor = .add } label: { Label("Add Room", systemImage: "plus") }
            }
        }
        .sheet(item: $editor) { mode in
            switch mode {
            case .add:
                RoomEditorView(title: "Add Room", room: Room(name: "", directSun: .low, indirectSun: .medium)) { name, direct, indirect, hum in
                    viewModel.add(name: name, directSun: direct, indirectSun: indirect, humidity: hum)
                    editor = nil
                } onCancel: { editor = nil }
            case let .edit(room):
                RoomEditorView(title: "Edit Room", room: room) { name, direct, indirect, hum in
                    var updated = room
                    updated.name = name
                    updated.directSun = direct
                    updated.indirectSun = indirect
                    updated.humidity = hum
                    updated.sunlight = Room.legacySunlight(directSun: direct, indirectSun: indirect)
                    viewModel.update(updated)
                    editor = nil
                } onCancel: { editor = nil }
            }
        }
        .onAppear {
            viewModel.load()
            deepLinkEditorIfRequested()
        }
    }

    /// Screenshot deep-link (T220): `SPROUT_SCREEN=roomeditor` auto-opens the editor
    /// for the first room so the shot shows the two light controls + tooltips. No-op
    /// in release builds (`requestedScreen` is always `"list"`).
    private func deepLinkEditorIfRequested() {
        #if DEBUG
        guard editor == nil, DemoSeed.requestedScreen == "roomeditor",
              let first = viewModel.items.first else { return }
        editor = .edit(first.room)
        #endif
    }
}

/// One room row: name, the sunlight/humidity summary, and a plant count.
private struct RoomRow: View {
    let item: RoomsViewModel.Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.room.name).font(.headline)
                Text(item.room.environmentSummary).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(item.plantCount) \(item.plantCount == 1 ? "plant" : "plants")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Add/Edit form for a room — name + two light inputs (direct/indirect) that infer
/// an overall brightness + humidity. Each light input carries a small info (ⓘ)
/// tooltip explaining what it means (T220).
private struct RoomEditorView: View {
    @State private var name: String
    @State private var directSun: LightLevel
    @State private var indirectSun: LightLevel
    @State private var humidity: RoomHumidity
    let title: String
    let onSave: (String, LightLevel, LightLevel, RoomHumidity) -> Void
    let onCancel: () -> Void

    init(
        title: String,
        room: Room,
        onSave: @escaping (String, LightLevel, LightLevel, RoomHumidity) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        _name = State(initialValue: room.name)
        _directSun = State(initialValue: room.directSun)
        _indirectSun = State(initialValue: room.indirectSun)
        _humidity = State(initialValue: room.humidity)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    /// The brightness inferred live from the two pickers — shown so the user sees how
    /// their light choices combine.
    private var brightness: Brightness {
        Brightness.inferred(directSun: directSun, indirectSun: indirectSun)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Room name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section {
                    Picker("Direct sun", selection: $directSun) {
                        ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    InfoHeader(
                        title: "Direct sun",
                        help: "How much direct sunlight lands on the plants — e.g. an unobstructed south-facing windowsill. Direct sun dries the soil fastest."
                    )
                }
                Section {
                    Picker("Indirect sun", selection: $indirectSun) {
                        ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    InfoHeader(
                        title: "Indirect sun",
                        help: "The ambient daylight in the room with no direct beam on the leaves — bright rooms away from a window still get plenty."
                    )
                }
                Section {
                    HStack {
                        Text("Brightness")
                        Spacer()
                        Text(brightness.label).foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Inferred from direct + indirect light. Brighter rooms dry out faster, so plants there are watered more often.")
                }
                Section {
                    Picker("Humidity", selection: $humidity) {
                        ForEach(RoomHumidity.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Humidity")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name, directSun, indirectSun, humidity) }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

/// A section header with a title and a small info (ⓘ) button that presents a popover
/// explaining the field (T220 light-input tooltips).
private struct InfoHeader: View {
    let title: String
    let help: String
    @State private var showing = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            Button { showing = true } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("\(title) — what's this?")
            .popover(isPresented: $showing) {
                Text(help)
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: 280)
                    .presentationCompactAdaptation(.popover)
            }
            Spacer()
        }
    }
}
