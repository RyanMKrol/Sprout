import SwiftUI

/// The outcome of the add flow, handed back to the presenter.
enum BasketAddResult: Equatable {
    /// The user cancelled — nothing was created.
    case cancelled
    /// The user committed; the created plants are returned in basket order so the
    /// presenter can refresh the list and (T208) offer to photograph them.
    case created([Plant])
}

/// The **room-first add flow** (T221) — the replacement for the old add-then-pick-room
/// ordering. Two steps over one `BasketAddViewModel`:
///
///  1. **Room** — choose an existing room, or add a new one (reusing the T220
///     `RoomEditorView`). The choice pre-selects the room for the whole batch.
///  2. **Plants** — the basket + species picker, with the chosen room shown in a
///     header. Committing creates every plant with that `roomID` + its initial cadence.
///
/// Pure presentation: all step + basket rules live in `BasketAddViewModel`.
struct AddFlowView: View {
    @StateObject private var viewModel: BasketAddViewModel
    private let onFinish: (BasketAddResult) -> Void
    @State private var addingRoom = false

    init(viewModel: BasketAddViewModel, onFinish: @escaping (BasketAddResult) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .room: roomStep
                case .plants: plantsStep
                }
            }
            .navigationTitle(viewModel.step == .room ? "Where do they live?" : "Add Plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .onAppear { viewModel.loadRooms() }
            .sheet(isPresented: $addingRoom) {
                RoomEditorView(
                    title: "Add Room",
                    room: Room(name: "", directSun: .low, indirectSun: .medium)
                ) { name, direct, indirect, hum in
                    viewModel.createRoom(name: name, directSun: direct, indirectSun: indirect, humidity: hum)
                    addingRoom = false
                } onCancel: { addingRoom = false }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { onFinish(.cancelled) }
        }
        if viewModel.step == .plants {
            ToolbarItem(placement: .confirmationAction) {
                Button(addButtonTitle) {
                    if let created = try? viewModel.commit() {
                        onFinish(.created(created))
                    }
                }
                .disabled(!viewModel.canCommit)
            }
        }
    }

    private var addButtonTitle: String {
        let n = viewModel.commitCount
        return n <= 1 ? "Add Plant" : "Add \(n) Plants"
    }

    // MARK: - Step 1: room

    /// Choose the room the batch lives in, or add a new one. Picking either advances to
    /// the plant-adding step with that room pre-selected for every plant.
    private var roomStep: some View {
        List {
            Section {
                Text("First pick the room these plants live in — its light and humidity set how often they're watered.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if !viewModel.availableRooms.isEmpty {
                Section("Your rooms") {
                    ForEach(viewModel.availableRooms) { room in
                        Button {
                            viewModel.chooseRoom(room)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(room.name).font(.headline).foregroundStyle(.primary)
                                    Text(room.environmentSummary).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            Section {
                Button {
                    addingRoom = true
                } label: {
                    Label("Add a new room", systemImage: "plus.circle.fill")
                }
                Button("Skip — no room for now") {
                    viewModel.chooseRoom(nil)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Step 2: plants (basket + species)

    /// Add plants into the chosen room: the basket the user assembles, plus the species
    /// picker. A header shows which room they'll land in, with a tap to change it.
    private var plantsStep: some View {
        List {
            roomHeaderSection
            basketSection
            speciesSection
        }
    }

    /// Shows the room the batch will land in (chosen in step 1), with a "Change" action
    /// that steps back to room selection without losing the basket.
    private var roomHeaderSection: some View {
        Section("Room") {
            HStack {
                Label(viewModel.selectedRoom?.name ?? "No room", systemImage: "house.fill")
                Spacer()
                Button("Change") { viewModel.backToRoomStep() }
                    .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private var basketSection: some View {
        if viewModel.basket.isEmpty {
            Section {
                Text("Tap a species below to add it. Each plant gets a random name you can edit.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else {
            Section("Basket (\(viewModel.basket.count))") {
                ForEach(viewModel.basket) { entry in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Nickname", text: nameBinding(for: entry))
                                .textInputAutocapitalization(.words)
                                .font(.body)
                            Text(entry.species)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.reroll(entry)
                        } label: {
                            Image(systemName: "shuffle")
                                .accessibilityLabel("New random name")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onDelete { viewModel.remove(atOffsets: $0) }
            }
        }
    }

    /// A read/write binding to a basket entry's nickname for inline editing.
    private func nameBinding(for entry: BasketAddViewModel.Entry) -> Binding<String> {
        Binding(
            get: { viewModel.basket.first { $0.id == entry.id }?.nickname ?? entry.nickname },
            set: { viewModel.rename(entry, to: $0) }
        )
    }

    private var speciesSection: some View {
        Section("Add species") {
            TextField("Search species", text: $viewModel.speciesQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            ForEach(viewModel.speciesResults) { profile in
                Button {
                    viewModel.add(profile)
                } label: {
                    HStack {
                        Text(profile.species)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityLabel("Add \(profile.species)")
                    }
                }
            }
        }
    }
}
