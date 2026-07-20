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
                        // The row is a custom card, so we suppress the List's automatic
                        // NavigationLink disclosure chevron: the value-based link sits
                        // behind the row at zero opacity (still fully tappable), and the
                        // visible RoomRow carries no caret of its own.
                        ZStack {
                            NavigationLink(value: RoomDetailRoute(roomID: item.room.id)) {
                                EmptyView()
                            }
                            .opacity(0)

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
            .navigationTitle("Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editor = .add } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(SproutTheme.brandGreen)
                    .accessibilityLabel("Add room")
                }
            }
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
                let item = viewModel.items.first { $0.room.id == room.id }
                RoomEditorView(
                    title: "Edit Room",
                    room: room,
                    plantCount: item?.plantCount ?? 0,
                    onSave: { name, direct, indirect, hum in
                        var updated = room
                        updated.name = name
                        updated.directSun = direct
                        updated.indirectSun = indirect
                        updated.humidity = hum
                        updated.sunlight = Room.legacySunlight(directSun: direct, indirectSun: indirect)
                        viewModel.update(updated)
                        editor = nil
                    },
                    onCancel: { editor = nil },
                    onDelete: {
                        if let item {
                            viewModel.delete(item)
                        }
                        editor = nil
                    }
                )
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
    @State private var showDeleteConfirm = false
    let title: String
    let room: Room
    let plantCount: Int
    let onSave: (String, LightLevel, LightLevel, RoomHumidity) -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?

    init(
        title: String,
        room: Room,
        plantCount: Int = 0,
        onSave: @escaping (String, LightLevel, LightLevel, RoomHumidity) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.room = room
        self.plantCount = plantCount
        _name = State(initialValue: room.name)
        _directSun = State(initialValue: room.directSun)
        _indirectSun = State(initialValue: room.indirectSun)
        _humidity = State(initialValue: room.humidity)
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
    }

    /// The brightness inferred live from the two pickers — shown so the user sees how
    /// their light choices combine.
    private var brightness: Brightness {
        Brightness.inferred(directSun: directSun, indirectSun: indirectSun)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Edit Room",
                confirmLabel: "Save",
                confirmEnabled: canSave,
                onCancel: onCancel,
                onConfirm: {
                    onSave(name, directSun, indirectSun, humidity)
                }
            )

            ScrollView {
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Room name", text: $name)
                            .font(SproutFont.body(16))
                            .foregroundStyle(SproutTheme.ink)
                            .textInputAutocapitalization(.words)
                            .padding(16)
                            .background(SproutTheme.cardSurface)
                            .cornerRadius(SproutTheme.Radius.field)
                    }

                    // Direct Sun section
                    VStack(alignment: .leading, spacing: 8) {
                        RoomInfoHeader(
                            title: "Direct Sun",
                            help: "How much direct sunlight lands on the plants, e.g. an "
                                + "unobstructed south-facing windowsill. Direct sun dries the soil fastest."
                        )

                        SproutSegmentedPicker(
                            selection: $directSun,
                            options: LightLevel.allCases.map { ($0, $0.label) }
                        )
                    }

                    // Indirect Sun section
                    VStack(alignment: .leading, spacing: 8) {
                        RoomInfoHeader(
                            title: "Indirect Sun",
                            help: "The ambient daylight in the room with no direct beam on the "
                                + "leaves, bright rooms away from a window still get plenty."
                        )

                        SproutSegmentedPicker(
                            selection: $indirectSun,
                            options: LightLevel.allCases.map { ($0, $0.label) }
                        )
                    }

                    // Brightness readout card
                    HStack(spacing: 12) {
                        ChromeIcon.sun.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(SproutTheme.sun)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Brightness")
                                .font(SproutFont.body(16))
                                .foregroundStyle(SproutTheme.ink)

                            Text(
                                "Inferred from direct + indirect light. Brighter rooms dry out "
                                    + "faster, so plants there are watered more often."
                            )
                                .font(SproutFont.body(12.5))
                                .foregroundStyle(SproutTheme.textHint)
                        }

                        Spacer()

                        Text(brightness.label)
                            .font(SproutFont.body(11, weight: .semibold))
                            .foregroundStyle(SproutTheme.brightnessChip)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 217.0 / 255, green: 139.0 / 255, blue: 10.0 / 255, opacity: 0.14))
                            .cornerRadius(SproutTheme.Radius.chip)
                    }
                    .padding(16)
                    .background(SproutTheme.cardSurface)
                    .cornerRadius(SproutTheme.Radius.field)

                    // Humidity section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HUMIDITY")
                            .font(SproutFont.body(11, weight: .semibold))
                            .tracking(0.56)
                            .foregroundStyle(SproutTheme.taupe)
                            .textCase(.uppercase)

                        SproutSegmentedPicker(
                            selection: $humidity,
                            options: RoomHumidity.allCases.map { ($0, $0.label) }
                        )
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }

            // Delete Room row (only when editing an existing room)
            if onDelete != nil {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.bottom, 12)

                    Button(
                        action: { showDeleteConfirm = true },
                        label: {
                            HStack(spacing: 12) {
                                ChromeIcon.trash.image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(SproutTheme.destructive)

                                Text("Delete Room")
                                    .font(SproutFont.body(17, weight: .semibold))
                                    .foregroundStyle(SproutTheme.destructive)

                                Spacer()
                            }
                            .padding(16)
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SproutTheme.cardSurface)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                Color(red: 196.0 / 255, green: 85.0 / 255, blue: 59.0 / 255, opacity: 0.2),
                                lineWidth: 1
                            )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(SproutTheme.paper)
            }
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
        .sproutAlert(isPresented: $showDeleteConfirm) {
            let message = plantCount == 0
                ? "This can't be undone."
                : "Its \(plantCount) \(plantCount == 1 ? "plant" : "plants") stay in your garden "
                    + "without a room's light and humidity. This can't be undone."

            SproutAlert(
                icon: .trash,
                tint: SproutTheme.destructive,
                title: "Delete \(room.name)?",
                message: message,
                confirmLabel: "Delete",
                confirmRole: .destructive,
                onConfirm: {
                    showDeleteConfirm = false
                    onDelete?()
                    onCancel()
                },
                onCancel: {
                    showDeleteConfirm = false
                }
            )
        }
    }
}
