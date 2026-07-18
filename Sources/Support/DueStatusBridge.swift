import Foundation

/// Bridges the domain-level `WateringDueStatus` (business logic, in `PlantListViewModel`)
/// to the design-system `DueStatus` the `DueChip` renders. Both describe the same four
/// states; this keeps the mapping in one place so screens (My Plants, Room detail) don't
/// each re-implement the switch.
extension DueStatus {
    init(_ watering: WateringDueStatus) {
        switch watering {
        case let .overdue(days):
            self = .overdue(days: days)
        case .dueToday:
            self = .dueToday
        case let .due(days):
            self = .due(inDays: days)
        case .unscheduled:
            self = .unscheduled
        }
    }
}
