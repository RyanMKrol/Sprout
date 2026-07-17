import SwiftUI

/// A circular icon token matching `PlantToken`'s look, but with the glyph made
/// `.resizable()` — `PlantToken`'s own glyph isn't, so on a real bundled asset
/// (not an SF Symbol) it renders at the asset's native size and spills across
/// the surrounding UI instead of sitting inside the token (see the same
/// workaround in `HomePlantAvatar`, `HomeComponents.swift`). Used wherever this
/// file and `IconPickerView` need a small tappable/preview token.
struct FixedGlyphPlantToken: View {
    let icon: PlantIcon
    let duo: PlantTokenPalette.Duo
    let size: CGFloat

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [duo.light, duo.dark]),
                center: UnitPoint(x: 0.3, y: 0.25),
                startRadius: 0,
                endRadius: size * 0.75
            )
            .clipShape(Circle())

            icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.45, height: size * 0.45)
                .foregroundStyle(Color.white)
        }
        .frame(width: size, height: size)
        .shadow(color: duo.dark.opacity(0.28), radius: 5, y: 2)
    }
}

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
    @State private var editingIconEntry: BasketAddViewModel.Entry?

    init(viewModel: BasketAddViewModel, onFinish: @escaping (BasketAddResult) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .room: roomStep
            case .plants: plantsStep
            }
        }
        .onAppear { viewModel.loadRooms() }
        .sheet(isPresented: $addingRoom) {
            AddRoomView { name, direct, indirect, hum in
                viewModel.createRoom(name: name, directSun: direct, indirectSun: indirect, humidity: hum)
                addingRoom = false
            } onCancel: { addingRoom = false }
        }
        .sheet(item: $editingIconEntry) { entry in
            IconPickerView(
                icon: entry.icon,
                name: entry.nickname,
                species: entry.species,
                tokenID: entry.id,
                onSave: { icon in viewModel.updateIcon(icon, for: entry) },
                onFinish: { editingIconEntry = nil }
            )
        }
    }

    private var addButtonTitle: String {
        let n = viewModel.commitCount
        return n <= 1 ? "Add 1 Plant" : "Add \(n) Plants"
    }

    // MARK: - Step 1: room

    /// Choose the room the batch lives in, or add a new one. Picking either advances to
    /// the plant-adding step with that room pre-selected for every plant.
    private var roomStep: some View {
        VStack(spacing: 0) {
            // Handle
            VStack {
                Capsule()
                    .fill(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
            }

            // Header with Cancel on right
            HStack(spacing: 16) {
                Spacer()
                Text("Where do they\nlive?")
                    .font(SproutFont.display(28))
                    .foregroundStyle(SproutTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Spacer()
                Button("Cancel") { onFinish(.cancelled) }
                    .font(SproutFont.body(17))
                    .foregroundStyle(SproutTheme.brandGreen)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            ScrollView {
                VStack(spacing: 0) {
                    // Body copy
                    Text("First pick the room these plants live in — its light and humidity set how often they're watered.")
                        .font(SproutFont.body(14))
                        .foregroundStyle(SproutTheme.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                    if !viewModel.availableRooms.isEmpty {
                        VStack(spacing: 9) {
                            SectionEyebrow(text: "Your Rooms")
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 9)

                            VStack(spacing: 9) {
                                ForEach(viewModel.availableRooms) { room in
                                    Button {
                                        viewModel.chooseRoom(room)
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Oat bubble with house icon
                                            Image(systemName: "house.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(SproutTheme.oatIcon)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Color(red: 180.0 / 255, green: 131.0 / 255, blue: 47.0 / 255, opacity: 0.14)
                                                )
                                                .cornerRadius(12)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(room.name)
                                                    .font(SproutFont.display(17))
                                                    .foregroundStyle(SproutTheme.ink)
                                                Text(room.environmentSummary)
                                                    .font(SproutFont.body(12.5))
                                                    .foregroundStyle(SproutTheme.textMuted)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(SproutTheme.taupe)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 13)
                                        .background(SproutTheme.cardSurface)
                                        .cornerRadius(18)
                                        .cardShadow()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                    }

                    VStack(spacing: 9) {
                        Button {
                            addingRoom = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                Text("Add a new room")
                            }
                        }
                        .buttonStyle(SproutGhostButtonStyle())
                        .padding(.horizontal, 20)

                        Button("Skip — no room for now") {
                            viewModel.chooseRoom(nil)
                        }
                        .font(SproutFont.body(15, weight: .medium))
                        .foregroundStyle(SproutTheme.textHint)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .background(SproutTheme.paper)
    }

    // MARK: - Step 2: plants (basket + species)

    /// Add plants into the chosen room: the basket the user assembles, plus the species
    /// picker. A header shows which room they'll land in, with a tap to change it.
    private var plantsStep: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Add Plants",
                confirmLabel: nil,
                onCancel: { onFinish(.cancelled) },
                onConfirm: {}
            )

            ScrollView {
                VStack(spacing: 20) {
                    roomSummaryRow

                    if !viewModel.basket.isEmpty {
                        basketSection
                    }

                    speciesSection
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            Divider()

            Button(addButtonTitle) {
                if let created = try? viewModel.commit() {
                    onFinish(.created(created))
                }
            }
            .buttonStyle(SproutPrimaryButtonStyle())
            .disabled(!viewModel.canCommit)
            .opacity(viewModel.canCommit ? 1 : 0.5)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .background(SproutTheme.paper)
    }

    /// Shows the room the batch will land in (chosen in step 1), with a "Change" action
    /// that steps back to room selection without losing the basket.
    private var roomSummaryRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 16))
                .foregroundStyle(SproutTheme.oatIcon)
                .frame(width: 40, height: 40)
                .background(Color(red: 180.0 / 255, green: 131.0 / 255, blue: 47.0 / 255, opacity: 0.14))
                .cornerRadius(12)

            Text(viewModel.selectedRoom?.name ?? "No room")
                .font(SproutFont.body(16, weight: .medium))
                .foregroundStyle(SproutTheme.ink)

            Spacer()

            Button("Change") { viewModel.backToRoomStep() }
                .font(SproutFont.body(15, weight: .semibold))
                .foregroundStyle(SproutTheme.brandGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(SproutTheme.cardSurface)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 20)
    }

    private var basketSection: some View {
        VStack(spacing: 9) {
            SectionEyebrow(text: "Basket · \(viewModel.basket.count)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            VStack(spacing: 9) {
                ForEach(viewModel.basket) { entry in
                    basketRow(for: entry)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func basketRow(for entry: BasketAddViewModel.Entry) -> some View {
        HStack(spacing: 12) {
            Button {
                editingIconEntry = entry
            } label: {
                FixedGlyphPlantToken(icon: entry.icon, duo: PlantTokenPalette.duo(for: entry.id), size: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change icon for \(entry.nickname)")

            VStack(alignment: .leading, spacing: 2) {
                TextField("Nickname", text: nameBinding(for: entry))
                    .textInputAutocapitalization(.words)
                    .font(SproutFont.body(15, weight: .semibold))
                    .foregroundStyle(SproutTheme.ink)
                Text(entry.species.capitalisedWords)
                    .font(SproutFont.bodyItalic(12))
                    .foregroundStyle(SproutTheme.textSecondary)
            }

            Spacer()

            Button {
                viewModel.reroll(entry)
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SproutTheme.brandGreen)
            }
            .accessibilityLabel("New random name")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SproutTheme.cardSurface)
        .cornerRadius(15)
        .cardShadow()
    }

    /// A read/write binding to a basket entry's nickname for inline editing.
    private func nameBinding(for entry: BasketAddViewModel.Entry) -> Binding<String> {
        Binding(
            get: { viewModel.basket.first { $0.id == entry.id }?.nickname ?? entry.nickname },
            set: { viewModel.rename(entry, to: $0) }
        )
    }

    private var speciesSection: some View {
        VStack(spacing: 9) {
            SectionEyebrow(text: "Add Species")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(SproutTheme.textHint)
                TextField("Search species", text: $viewModel.speciesQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(SproutFont.body(15))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(red: 120.0 / 255, green: 120.0 / 255, blue: 110.0 / 255, opacity: 0.1))
            .cornerRadius(13)
            .padding(.horizontal, 20)

            VStack(spacing: 9) {
                ForEach(viewModel.speciesResults) { profile in
                    Button {
                        viewModel.add(profile)
                    } label: {
                        HStack {
                            Text(profile.species.capitalisedWords)
                                .font(SproutFont.body(15, weight: .medium))
                                .foregroundStyle(SproutTheme.ink)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(SproutTheme.brandGreen)
                                .accessibilityLabel("Add \(profile.species.capitalisedWords)")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(SproutTheme.cardSurface)
                        .cornerRadius(14)
                        .cardShadow()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
