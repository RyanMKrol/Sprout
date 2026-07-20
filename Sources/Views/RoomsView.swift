import SwiftUI

/// The **Rooms** screen (redesign screen 14, T027). Lists the user's rooms with per-room
/// icons, plant counts, and tappable rows that navigate to the room detail. Tap navigates
/// to room detail (screen 15), not the editor. Editor is now behind the detail screen's
/// "Edit" button. Swipe-to-delete with confirmation alert.
struct RoomsView: View {
    @StateObject private var viewModel: RoomsViewModel
    @State private var editor: Editor?
    @State private var showDeleteConfirm = false
    @State private var deleteItem: RoomsViewModel.Item?

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
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    // Back button — NavigationStack at HomeView level handles the pop
                } label: {
                    HStack(spacing: 4) {
                        ChromeIcon.chevronLeft.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                        Text("Home")
                            .font(SproutFont.body(17, weight: .semibold))
                    }
                    .foregroundStyle(SproutTheme.brandGreen)
                }

                Spacer()

                Text("Rooms")
                    .font(SproutFont.display(32, weight: .bold))
                    .foregroundStyle(SproutTheme.ink)

                Spacer()

                if viewModel.isEmpty {
                    Color.clear.frame(width: 40, height: 40)
                } else {
                    SproutFAB { editor = .add }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(SproutTheme.paper)

            Group {
                if viewModel.isEmpty {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("No rooms yet")
                                .font(SproutFont.display(22, weight: .bold))
                                .foregroundStyle(SproutTheme.ink)

                            Text("Add the rooms your plants live in. Their light and humidity set each plant's watering rhythm.")
                                .font(SproutFont.body(13))
                                .foregroundStyle(SproutTheme.textHint)
                                .multilineTextAlignment(.center)
                        }

                        Button(
                            action: { editor = .add },
                            label: {
                                Text("Add a room")
                                    .font(SproutFont.body(15, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(SproutTheme.brandGreen)
                                    .cornerRadius(14)
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List(viewModel.items) { item in
                        NavigationLink(value: RoomDetailRoute(roomID: item.room.id)) {
                            RoomRow(item: item)
                        }
                        .listRowBackground(SproutTheme.paper)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteItem = item
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(SproutTheme.paper)
        }
        .background(SproutTheme.paper)
        .navigationDestination(for: RoomDetailRoute.self) { _ in
            // HomeView's NavigationStack handles this with proper repository injection
            EmptyView()
        }
        .sheet(item: $editor) { mode in
            switch mode {
            case .add:
                AddRoomView { name, direct, indirect, hum in
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
        .sproutAlert(isPresented: $showDeleteConfirm) {
            SproutAlert(
                icon: .trash,
                tint: SproutTheme.destructive,
                title: deleteItem.map { "Delete \($0.room.name)?" } ?? "Delete Room?",
                message: deleteItem.map { deleteConfirmationMessage(plantCount: $0.plantCount) } ?? "This can't be undone.",
                confirmLabel: "Delete",
                confirmRole: .destructive,
                onConfirm: {
                    if let item = deleteItem {
                        viewModel.delete(item)
                    }
                    deleteItem = nil
                },
                onCancel: {
                    deleteItem = nil
                }
            )
        }
        .onAppear {
            viewModel.load()
            deepLinkEditorIfRequested()
        }
    }

    private func deleteConfirmationMessage(plantCount: Int) -> String {
        if plantCount == 0 {
            return "This can't be undone."
        } else {
            let plants = plantCount == 1 ? "plant" : "plants"
            return "Its \(plantCount) \(plants) stay in your garden without a room's light and humidity. This can't be undone."
        }
    }

    /// Screenshot deep-link (T220): `SPROUT_SCREEN=roomeditor` auto-opens the editor
    /// for the first room so the shot shows the two light controls + tooltips. No-op
    /// in release builds (`requestedScreen` is always `"list"`).
    private func deepLinkEditorIfRequested() {
        #if DEBUG
        guard editor == nil else { return }
        switch DemoSeed.requestedScreen {
        case "roomeditor":
            if let first = viewModel.items.first { editor = .edit(first.room) }
        case "addroom":
            editor = .add
        default:
            break
        }
        #endif
    }
}

/// One room row: 44×44 oat icon bubble with room icon, name (Bricolage 18),
/// env summary (body 12.5), and trailing plant count + chevron.
private struct RoomRow: View {
    let item: RoomsViewModel.Item

    var body: some View {
        HStack(spacing: 12) {
            // 44×44 oat bubble with per-room icon
            ZStack {
                Circle()
                    .fill(SproutTheme.oatSurface)
                    .frame(width: 44, height: 44)

                iconForRoom(name: item.room.name)
                    .image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(SproutTheme.oatIcon)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.room.name)
                    .font(SproutFont.display(18, weight: .bold))
                    .foregroundStyle(SproutTheme.ink)

                Text(item.room.environmentSummary)
                    .font(SproutFont.body(12.5))
                    .foregroundStyle(SproutTheme.textMuted)
            }

            Spacer()

            Text("\(item.plantCount) \(item.plantCount == 1 ? "plant" : "plants")")
                .font(SproutFont.body(13, weight: .semibold))
                .foregroundStyle(SproutTheme.taupe)
        }
        .padding(14)
        .sproutCard(radius: 20)
    }

    private func iconForRoom(name: String) -> ChromeIcon {
        let lowercased = name.lowercased()
        if lowercased.contains("living") {
            return .couch
        } else if lowercased.contains("bed") {
            return .bed
        } else if lowercased.contains("bath") {
            return .bath
        } else if lowercased.contains("kitchen") {
            return .utensils
        } else if lowercased.contains("dining") {
            return .mugSaucer
        } else {
            return .house
        }
    }
}

/// Add/Edit form for a room — name + two light inputs (direct/indirect) that infer
/// an overall brightness + humidity. Each light input carries a small info (ⓘ)
/// tooltip explaining what it means (T220). Internal (not `private`) so the room-first
/// add flow (T221) can reuse the very same editor for its "add a new room" step.
struct RoomEditorView: View {
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
                    Picker("Direct Sun", selection: $directSun) {
                        ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    RoomInfoHeader(
                        title: "Direct Sun",
                        help: "How much direct sunlight lands on the plants — e.g. an unobstructed south-facing windowsill. Direct sun dries the soil fastest."
                    )
                }
                Section {
                    Picker("Indirect Sun", selection: $indirectSun) {
                        ForEach(LightLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    RoomInfoHeader(
                        title: "Indirect Sun",
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
