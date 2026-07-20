import SwiftUI
import UIKit

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

/// The **Plant Detail** screen (T018). Shows a plant's photo + name as a prominent
/// centered header, its current watering schedule with rhythm visualization,
/// and its chronological check-in history. An **Edit** button (top right) opens the
/// edit form to change the nickname, room, or photo. Reached by tapping a card in the
/// My Plants list, and verified by the `-seedDemoData YES` screenshot convention
/// (`SPROUT_SCREEN=detail`).
///
/// Pure presentation: all loading / ordering / derivation lives in
/// `PlantDetailViewModel`; this view only renders its published state.
struct PlantDetailView: View {
    @StateObject private var viewModel: PlantDetailViewModel
    /// Builds the edit form (T007/T218) for this plant. When `nil`, the Edit button is
    /// hidden — keeps the detail screen usable on its own.
    private let makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)?
    /// Builds the check-in view model (T011) for this plant. When `nil`, the
    /// "Check in" affordance is hidden — keeps the detail screen usable on its own.
    private let makeCheckIn: ((UUID) -> CheckInViewModel)?
    @Environment(\.dismiss) private var dismiss
    @State private var checkingIn = false
    @State private var editingPlant = false
    @State private var editingSchedule = false
    /// The value bound to the manual "due in N days" wheel while its sheet is open.
    @State private var scheduleDays = 7
    @State private var didDeepLink = false

    init(
        viewModel: PlantDetailViewModel,
        makeEditor: ((PlantEditViewModel.Mode) -> PlantEditViewModel)? = nil,
        makeCheckIn: ((UUID) -> CheckInViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeEditor = makeEditor
        self.makeCheckIn = makeCheckIn
    }

    var body: some View {
        Group {
            if viewModel.loadFailed {
                ContentUnavailableView(
                    "Plant unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This plant could not be loaded.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        scheduleCard
                        if makeCheckIn != nil { checkInButton }
                        historySection
                    }
                    .padding(18)
                }
                .background(SproutTheme.paper)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Label("Plants", systemImage: "chevron.left").labelStyle(.iconOnly)
                }
                .foregroundStyle(SproutTheme.brandGreen)
                .font(.system(size: 17, weight: .semibold))
                .accessibilityLabel("Plants")
            }
            if makeEditor != nil, !viewModel.loadFailed {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        editingPlant = true
                    }
                    .font(SproutFont.body(17, weight: .semibold))
                    .foregroundStyle(SproutTheme.brandGreen)
                }
            }
        }
        .sheet(isPresented: $checkingIn) {
            if let makeCheckIn {
                CheckInView(viewModel: makeCheckIn(viewModel.plantID)) {
                    viewModel.load()
                }
            }
        }
        .sheet(isPresented: $editingPlant) {
            if let makeEditor {
                PlantEditView(viewModel: makeEditor(.edit(plantID: viewModel.plantID))) {
                    editingPlant = false
                    viewModel.load()
                }
            }
        }
        .sheet(isPresented: $editingSchedule) {
            ScheduleEditorSheet(days: $scheduleDays) {
                viewModel.setDueInDays(scheduleDays)
                editingSchedule = false
            } onCancel: {
                editingSchedule = false
            }
        }
        .onAppear {
            viewModel.load()
            deepLinkIfRequested()
        }
    }

    // MARK: - Sections

    /// Centered header: 112 token, display name (32), italic species (16).
    private var header: some View {
        VStack(spacing: 12) {
            PlantToken(
                icon: .flower,
                duo: PlantTokenPalette.duo(for: viewModel.plantID),
                size: 112,
                photo: viewModel.photoData.flatMap { UIImage(data: $0) }
            )
            VStack(spacing: 4) {
                Text(viewModel.nickname)
                    .font(SproutFont.display(32, weight: .bold))
                    .foregroundStyle(SproutTheme.ink)
                    .multilineTextAlignment(.center)
                Text(viewModel.species.capitalisedWords)
                    .font(SproutFont.bodyItalic(16))
                    .foregroundStyle(Color(hex: 0x7C8173))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Three-zone schedule card: due status, rhythm band, and why sentence.
    private var scheduleCard: some View {
        VStack(spacing: 0) {
            // Zone 1: Due status
            Button {
                scheduleDays = viewModel.daysUntilDue
                editingSchedule = true
            } label: {
                HStack(spacing: 12) {
                    // Soft-green droplet bubble (34×34, r10) — sits beside the due
                    // status, per redesign-spec zone 1.
                    RoundedRectangle(cornerRadius: 10)
                        .fill(SproutTheme.softGreenFill)
                        .frame(width: 34, height: 34)
                        .overlay(
                            ChromeIcon.droplet.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .foregroundStyle(dueColor)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.due.label)
                            .font(SproutFont.display(17, weight: .bold))
                            .foregroundStyle(dueColor)
                        Text("Tap to adjust when it's next due")
                            .font(SproutFont.body(12))
                            .foregroundStyle(Color(hex: 0x9AA090))
                    }

                    Spacer()

                    ChromeIcon.pencil.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                        .foregroundStyle(SproutTheme.taupe)
                }
                .padding(16)
            }

            Divider()
                .padding(.horizontal, 16)

            // Zone 2: Rhythm Band
            RhythmBand(
                effectiveDays: viewModel.effectiveDays,
                daysUntilDue: viewModel.daysUntilDue,
                isOverdue: isOverdue
            )
            .padding(16)

            Divider()
                .padding(.horizontal, 16)

            // Zone 3: Why sentence
            VStack(alignment: .leading, spacing: 8) {
                if let explanation = viewModel.explanation {
                    Text(explanation.sentence)
                        .font(SproutFont.body(13))
                        .foregroundStyle(Color(hex: 0x6E7A63))
                        .lineLimit(4)
                } else {
                    Text(viewModel.scheduleSummary)
                        .font(SproutFont.body(13))
                        .foregroundStyle(Color(hex: 0x6E7A63))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .sproutCard(radius: 20)
    }

    /// Primary button for check-in action.
    private var checkInButton: some View {
        Button {
            checkingIn = true
        } label: {
            HStack {
                Text("✓ Check in on \(viewModel.nickname)")
                    .font(SproutFont.body(17, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.white)
            .padding(17)
            .background(SproutTheme.brandGreen)
            .cornerRadius(16)
            .shadow(
                color: SproutTheme.brandGreen.opacity(0.34),
                radius: 12, x: 0, y: 4
            )
        }
    }

    /// History section with eyebrow and white card rows.
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHECK-IN HISTORY")
                .font(SproutFont.body(11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(SproutTheme.taupe)
                .textCase(.uppercase)

            if viewModel.hasHistory {
                VStack(spacing: 0) {
                    ForEach(viewModel.history) { (item: PlantDetailViewModel.HistoryItem) in
                        CheckInRow(item: item)
                        if item.id != viewModel.history.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .sproutCard(radius: 18)
            } else {
                Text("No check-ins yet.")
                    .font(SproutFont.body(14))
                    .foregroundStyle(SproutTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Screenshot deep-link (T002 convention): when launched with
    /// `SPROUT_SCREEN=checkin`, auto-present the check-in sheet once so the seeded
    /// run captures it. No-op otherwise / in release builds.
    private func deepLinkIfRequested() {
        guard !didDeepLink else { return }
        didDeepLink = true
        if DemoSeed.requestedScreen == "checkin", makeCheckIn != nil {
            checkingIn = true
        }
    }

    /// Whether the plant is past due — pins the rhythm gauge marker at "Water now".
    private var isOverdue: Bool {
        if case .overdue = viewModel.due { return true }
        return false
    }

    /// Maps the (pure) due status to a presentation colour.
    private var dueColor: Color {
        switch viewModel.due {
        case .overdue:
            return Color(hex: 0xC4553B)
        case .dueToday:
            return Color(hex: 0xB4832F)
        case .due:
            return SproutTheme.brandGreen
        case .unscheduled:
            return SproutTheme.textTertiary
        }
    }
}

/// A small sheet with a day wheel for overriding when a plant is next due by hand.
private struct ScheduleEditorSheet: View {
    @Binding var days: Int
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Adjust schedule",
                confirmLabel: "Save",
                onCancel: onCancel,
                onConfirm: onSave
            )

            ScrollView {
                VStack(spacing: 16) {
                    Text("Water this plant in")
                        .font(SproutFont.body(15, weight: .semibold))
                        .foregroundStyle(SproutTheme.textMuted)
                        .frame(maxWidth: .infinity)

                    Picker("Days until due", selection: $days) {
                        ForEach(0...365, id: \.self) { day in
                            Text(day == 0 ? "Today" : "\(day) \(day == 1 ? "day" : "days")")
                                .foregroundStyle(SproutTheme.ink)
                                .tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .tint(SproutTheme.ink)
                    .frame(height: 200)

                    Text("Sets the next-watering date. Future check-ins keep adapting it.")
                        .font(SproutFont.body(13))
                        .foregroundStyle(SproutTheme.textHint)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }

            Spacer()
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
        .presentationDetents([.medium])
    }
}

#Preview {
    VStack {
        Text("Sheet Preview")
            .font(.title)
            .foregroundStyle(SproutTheme.ink)
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SproutTheme.paper)
    .sheet(isPresented: .constant(true)) {
        ScheduleEditorSheet(
            days: .constant(7),
            onSave: {},
            onCancel: {}
        )
    }
}

/// One row of check-in history: date, soil/leaves observation, and watered indicator.
private struct CheckInRow: View {
    let item: PlantDetailViewModel.HistoryItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.date, format: .dateTime.day().month().year())
                    .font(SproutFont.body(15, weight: .semibold))
                    .foregroundStyle(SproutTheme.ink)

                Text("Soil \(soilLabel) · Leaves \(leafLabel)")
                    .font(SproutFont.body(12.5))
                    .foregroundStyle(SproutTheme.textMuted)
            }

            Spacer()

            if item.watered {
                HStack(spacing: 4) {
                    Text("💧")
                    Text("Watered")
                        .font(SproutFont.body(12.5, weight: .bold))
                }
                .foregroundStyle(SproutTheme.brandGreen)
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }

    private var soilLabel: String {
        switch item.soil {
        case .dry: return "dry"
        case .moist: return "moist"
        case .wet: return "wet"
        }
    }

    private var leafLabel: String {
        switch item.leaves {
        case .crispy: return "crispy"
        case .fine: return "fine"
        case .droopy: return "droopy"
        }
    }
}
