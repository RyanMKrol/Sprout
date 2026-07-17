import SwiftUI

/// The **Icon picker** sheet (T021). Allows the user to choose a Phosphor glyph
/// to represent the plant. Displays all 16 icons in a 4-column grid with a live
/// preview token showing the currently-selected icon.
///
/// Works over a *preview identity* (name/species/token-id) rather than a `Plant`
/// directly, so it can be opened both on an already-persisted plant (the
/// `plant:repository:` init, which saves straight through the repository) and on
/// a still-pending basket entry (T023's `icon:name:species:tokenID:onSave:` init,
/// which hands the choice back to the caller to fold into its own pending state).
struct IconPickerView: View {
    @State private var selectedIcon: PlantIcon
    private let previewName: String
    private let previewSpecies: String
    private let previewTokenID: UUID
    private let onSave: (PlantIcon) -> Void
    private let onFinish: () -> Void

    /// For a plant already persisted via the repository (Edit Plant's "Change icon").
    init(plant: Plant, repository: PlantRepository, onFinish: @escaping () -> Void = {}) {
        self.init(
            icon: plant.icon,
            name: plant.nickname,
            species: plant.species,
            tokenID: plant.id,
            onSave: { icon in
                var updated = plant
                updated.icon = icon
                try? repository.update(updated)
            },
            onFinish: onFinish
        )
    }

    /// For a still-pending entry (e.g. a basket row, T023) that isn't persisted
    /// yet — `onSave` hands the chosen icon back to the caller to fold into its
    /// own pending state instead of writing through a repository.
    init(
        icon: PlantIcon,
        name: String,
        species: String,
        tokenID: UUID,
        onSave: @escaping (PlantIcon) -> Void,
        onFinish: @escaping () -> Void = {}
    ) {
        self.previewName = name
        self.previewSpecies = species
        self.previewTokenID = tokenID
        self.onSave = onSave
        self.onFinish = onFinish
        _selectedIcon = State(initialValue: icon)
    }

    var body: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Choose an icon",
                confirmLabel: "Done",
                onCancel: onFinish,
                onConfirm: saveAndFinish
            )

            ScrollView {
                VStack(spacing: 24) {
                    // Preview section
                    VStack(spacing: 12) {
                        FixedGlyphPlantToken(
                            icon: selectedIcon,
                            duo: PlantTokenPalette.duo(for: previewTokenID),
                            size: 88
                        )

                        VStack(spacing: 4) {
                            Text(previewName)
                                .font(SproutFont.display(20))
                                .foregroundStyle(SproutTheme.ink)

                            Text(previewSpecies)
                                .font(SproutFont.bodyItalic(14))
                                .foregroundStyle(SproutTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 24)

                    // Icon picker section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PICK AN ICON")
                            .font(SproutFont.body(11, weight: .semibold))
                            .tracking(0.56)
                            .foregroundStyle(SproutTheme.taupe)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                            spacing: 12
                        ) {
                            ForEach(PlantIcon.allCases, id: \.self) { icon in
                                IconCell(
                                    icon: icon,
                                    isSelected: icon == selectedIcon,
                                    onTap: { selectedIcon = icon }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }

            // Footer hint
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom, 16)

                Text("Set the look now — you can change it anytime from the plant's page.")
                    .font(SproutFont.body(12.5))
                    .foregroundStyle(SproutTheme.textHint)
                    .lineLimit(3)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
    }

    private func saveAndFinish() {
        onSave(selectedIcon)
        onFinish()
    }
}

private struct IconCell: View {
    let icon: PlantIcon
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(SproutTheme.brandGreen)
                        .shadow(
                            color: Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.34),
                            radius: 18,
                            x: 0,
                            y: 8
                        )
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(SproutTheme.cardSurface)
                        .strokeBorder(
                            Color(red: 34.0 / 255, green: 39.0 / 255, blue: 31.0 / 255, opacity: 0.06),
                            lineWidth: 0.5
                        )
                }

                icon.image
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .white : Color(hex: 0x3A4136))
            }
            .frame(height: 88)
            .accessibilityIdentifier("icon.\(icon.rawValue)")
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    let demoPlant = Plant(
        nickname: "Monstera Deliciosa",
        species: "Monstera deliciosa",
        icon: .plant
    )

    return NavigationStack {
        ZStack {
            SproutTheme.paper
                .ignoresSafeArea()

            VStack {
                Text("Tap to open icon picker")
                    .font(SproutFont.body(16))
                    .foregroundStyle(SproutTheme.ink)
            }
        }
        .sheet(isPresented: .constant(true)) {
            IconPickerView(
                plant: demoPlant,
                repository: MockPlantRepository(),
                onFinish: {}
            )
        }
    }
}

// MARK: - Mock repository for preview

private class MockPlantRepository: PlantRepository {
    func allPlants() throws -> [Plant] { [] }
    func plant(id: UUID) throws -> Plant? { nil }
    func add(_ plant: Plant) throws {}
    func update(_ plant: Plant) throws {}
    func delete(id: UUID) throws {}
    func deleteAllPlants() throws {}
    func addCheckIn(_ checkIn: CheckIn, toPlant plantID: UUID) throws {}
    func allRooms() throws -> [Room] { [] }
    func room(id: UUID) throws -> Room? { nil }
    func addRoom(_ room: Room) throws {}
    func updateRoom(_ room: Room) throws {}
    func deleteRoom(id: UUID) throws {}
    func deleteAllRooms() throws {}
}
