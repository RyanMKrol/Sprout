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
                RoomEditorView(title: "Add Room", room: Room(name: "")) { name, sun, hum in
                    viewModel.add(name: name, sunlight: sun, humidity: hum)
                    editor = nil
                } onCancel: { editor = nil }
            case let .edit(room):
                RoomEditorView(title: "Edit Room", room: room) { name, sun, hum in
                    var updated = room
                    updated.name = name
                    updated.sunlight = sun
                    updated.humidity = hum
                    viewModel.update(updated)
                    editor = nil
                } onCancel: { editor = nil }
            }
        }
        .onAppear { viewModel.load() }
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

/// Add/Edit form for a room — name + sunlight + humidity.
private struct RoomEditorView: View {
    @State private var name: String
    @State private var sunlight: SunlightLevel
    @State private var humidity: RoomHumidity
    let title: String
    let onSave: (String, SunlightLevel, RoomHumidity) -> Void
    let onCancel: () -> Void

    init(
        title: String,
        room: Room,
        onSave: @escaping (String, SunlightLevel, RoomHumidity) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        _name = State(initialValue: room.name)
        _sunlight = State(initialValue: room.sunlight)
        _humidity = State(initialValue: room.humidity)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Room name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Light") {
                    Picker("Sunlight", selection: $sunlight) {
                        ForEach(SunlightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Humidity") {
                    Picker("Humidity", selection: $humidity) {
                        ForEach(RoomHumidity.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name, sunlight, humidity) }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
