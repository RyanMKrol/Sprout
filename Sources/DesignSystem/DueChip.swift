import SwiftUI

/// Design-system watering-urgency classification for the **DueChip** pill
/// (`Sources/DesignSystem/DueChip.swift`). Distinct from `WateringDueStatus`
/// (`Sources/ViewModels/PlantListViewModel.swift`), which drives the list's
/// relative-date business logic — this type only carries the label/color the
/// chip renders.
enum DueStatus {
    case overdue(days: Int)
    case dueToday
    case due(inDays: Int)
    case unscheduled

    var label: String {
        switch self {
        case let .overdue(days):
            return "Overdue \(days)d"
        case .dueToday:
            return "Due today"
        case let .due(inDays):
            return "Due in \(inDays)d"
        case .unscheduled:
            return "No schedule"
        }
    }

    var tint: Color {
        switch self {
        case .overdue:
            return Color(red: 196.0 / 255, green: 85.0 / 255, blue: 59.0 / 255)
        case .dueToday:
            return Color(red: 180.0 / 255, green: 131.0 / 255, blue: 47.0 / 255)
        case .due:
            return Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255)
        case .unscheduled:
            return SproutTheme.textTertiary
        }
    }

    var background: Color {
        switch self {
        case .overdue:
            return Color(red: 196.0 / 255, green: 85.0 / 255, blue: 59.0 / 255, opacity: 0.13)
        case .dueToday:
            return Color(red: 198.0 / 255, green: 138.0 / 255, blue: 46.0 / 255, opacity: 0.16)
        case .due:
            return Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.13)
        case .unscheduled:
            return Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.08)
        }
    }
}

/// Trailing pill on `PlantRow` (§2 item 12 of the redesign spec) showing a
/// plant's watering urgency at a glance.
struct DueChip: View {
    let status: DueStatus

    var body: some View {
        Text(status.label)
            .font(SproutFont.body(11, weight: .bold))
            .foregroundStyle(status.tint)
            .padding(.vertical, 5)
            .padding(.horizontal, 11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(status.background)
            )
    }
}

#Preview {
    VStack(spacing: 12) {
        DueChip(status: .overdue(days: 3))
        DueChip(status: .dueToday)
        DueChip(status: .due(inDays: 5))
        DueChip(status: .unscheduled)
    }
    .padding(20)
    .background(SproutTheme.paper)
}
