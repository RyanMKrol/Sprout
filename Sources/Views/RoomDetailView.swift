import SwiftUI

/// Navigation value for pushing a room's detail screen onto the home `NavigationStack`.
/// A dedicated type (not a bare `UUID`) so it never collides with the plant-detail
/// `UUID` destination registered elsewhere in the stack.
struct RoomDetailRoute: Hashable {
    let roomID: UUID
}

/// The **Room detail** screen (redesign screen 15, NEW): a room's brightness/humidity
/// stat duo, a plain-language watering-impact banner, and the plants that live in it —
/// each row a link into that plant's detail. "Edit" opens the existing room editor.
/// Closes the old "rooms feel like a dead end" gap.
struct RoomDetailView: View {
    @StateObject private var viewModel: RoomDetailViewModel
    private let makeDetail: ((UUID) -> PlantDetailViewModel)?
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?

    @Environment(\.dismiss) private var dismiss
    @State private var editing = false

    init(
        viewModel: RoomDetailViewModel,
        makeDetail: ((UUID) -> PlantDetailViewModel)? = nil,
        makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)? = nil,
        makeCheckIn: ((UUID) -> CheckInViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeDetail = makeDetail
        self.makeEditor = makeEditor
        self.makeCheckIn = makeCheckIn
    }

    var body: some View {
        Group {
            if viewModel.loadFailed {
                ContentUnavailableView("Room not found", systemImage: "house")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(viewModel.room?.name ?? "Room")
                            .font(SproutFont.display(32, weight: .bold))
                            .foregroundStyle(SproutTheme.ink)

                        statDuo

                        InfoBanner(icon: .arrowTrendUp, text: viewModel.impactLine)

                        plantsSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                }
                .background(SproutTheme.paper)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        // The room's plant rows push the plant detail. Registered here (not shared with
        // PlantListView's UUID destination) because the two live in separate stack branches.
        .navigationDestination(for: UUID.self) { plantID in
            if let makeDetail {
                PlantDetailView(
                    viewModel: makeDetail(plantID),
                    makeEditor: makeEditor,
                    makeCheckIn: makeCheckIn
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Label("Rooms", systemImage: "chevron.left").labelStyle(.iconOnly)
                }
                .foregroundStyle(SproutTheme.brandGreen)
                .font(.system(size: 17, weight: .semibold))
                .accessibilityLabel("Rooms")
            }
            if !viewModel.loadFailed {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { editing = true }
                        .font(SproutFont.body(17, weight: .semibold))
                        .foregroundStyle(SproutTheme.brandGreen)
                }
            }
        }
        .sheet(isPresented: $editing) {
            if let room = viewModel.room {
                RoomEditorView(title: "Edit Room", room: room) { name, direct, indirect, hum in
                    viewModel.update(name: name, directSun: direct, indirectSun: indirect, humidity: hum)
                    editing = false
                } onCancel: { editing = false }
            }
        }
        .onAppear { viewModel.load() }
    }

    /// Oat "Brightness" card + sage "Humidity" card.
    private var statDuo: some View {
        HStack(spacing: 12) {
            RoomStatCard(
                icon: .sun, accent: SproutTheme.sun, title: "Brightness",
                value: viewModel.room?.brightness.label ?? "—",
                surface: SproutTheme.oatSurface, border: SproutTheme.oatBorder
            )
            RoomStatCard(
                icon: .droplet, accent: SproutTheme.brandGreen, title: "Humidity",
                value: viewModel.room?.humidity.label ?? "—",
                surface: SproutTheme.sageSurface, border: SproutTheme.sageBorder
            )
        }
    }

    private var plantsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PLANTS IN THIS ROOM")
                .font(SproutFont.body(12, weight: .semibold))
                .foregroundStyle(SproutTheme.textTertiary)
                .tracking(0.8)

            if viewModel.plants.isEmpty {
                Text("No plants in this room yet.")
                    .font(SproutFont.body(15))
                    .foregroundStyle(SproutTheme.textMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.plants) { plant in
                    if makeDetail != nil {
                        NavigationLink(value: plant.id) {
                            RoomPlantRow(plant: plant)
                        }
                        .buttonStyle(.plain)
                    } else {
                        RoomPlantRow(plant: plant)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A single brightness/humidity stat card in the room-detail stat duo.
private struct RoomStatCard: View {
    let icon: ChromeIcon
    let accent: Color
    let title: String
    let value: String
    let surface: Color
    let border: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(accent)
            Text(title.uppercased())
                .font(SproutFont.body(12, weight: .semibold))
                .foregroundStyle(SproutTheme.oatSubtitle)
            Text(value)
                .font(SproutFont.display(19, weight: .bold))
                .foregroundStyle(SproutTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(surface)
        .overlay(
            RoundedRectangle(cornerRadius: SproutTheme.Radius.row)
                .strokeBorder(border, lineWidth: 1)
        )
        .cornerRadius(SproutTheme.Radius.row)
    }
}

/// A compact plant row on the room-detail screen: token, name, italic species, due chip.
private struct RoomPlantRow: View {
    let plant: RoomDetailViewModel.PlantRow

    var body: some View {
        HStack(spacing: 12) {
            PlantToken(
                icon: plant.icon,
                duo: PlantTokenPalette.duo(for: plant.id),
                size: 40,
                photo: plant.photoData.flatMap { UIImage(data: $0) }
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.nickname)
                    .font(SproutFont.body(16, weight: .medium))
                    .foregroundStyle(SproutTheme.ink)
                Text(plant.species)
                    .font(SproutFont.bodyItalic(13))
                    .foregroundStyle(SproutTheme.textMuted)
            }
            Spacer()
            DueChip(status: DueStatus(plant.due))
        }
        .padding(12)
        .background(SproutTheme.cardSurface)
        .cornerRadius(SproutTheme.Radius.row)
        .accessibilityElement(children: .combine)
    }
}
