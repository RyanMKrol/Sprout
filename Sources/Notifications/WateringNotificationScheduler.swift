import Foundation
import UserNotifications

/// The slice of `UNUserNotificationCenter` the scheduler actually uses, expressed
/// as a protocol so tests can inject a `StubNotificationCenter` and assert exactly
/// which requests were scheduled / removed without touching the real system center.
///
/// Every signature matches `UNUserNotificationCenter`'s own `async` API, so the
/// production conformance below is empty — `UNUserNotificationCenter.current()`
/// satisfies it as-is.
protocol UserNotificationCenter {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: UserNotificationCenter {}

/// Schedules per-plant watering reminders via `UNUserNotificationCenter` (T013).
///
/// Each plant owns **at most one** pending reminder, keyed by a stable identifier
/// derived from its `id`, fired at the plant's `nextDue` date at a fixed
/// time-of-day. Rescheduling (after a check-in moves `nextDue`) removes the old
/// request and adds the new one, so reminders never stack. Authorization is
/// requested lazily on the first `scheduleReminder` and the scheduler degrades
/// gracefully to a no-op if the user denies it.
struct WateringNotificationScheduler: NotificationScheduling {
    /// Default reminder hour-of-day (24h). The watering reminder fires at this
    /// hour on the due date. **Tunable** and made user-configurable by T014
    /// (preferred reminder-time window); kept a named constant until then.
    static let defaultReminderHour = 9

    /// Identifier prefix for the watering-reminder requests this scheduler owns.
    private static let identifierPrefix = "sprout.watering."

    /// The stable notification identifier for a plant — used to add, find, and
    /// remove that plant's single pending reminder.
    static func identifier(for plantID: UUID) -> String {
        identifierPrefix + plantID.uuidString
    }

    private let center: UserNotificationCenter
    private let calendar: Calendar
    private let reminderHour: Int

    init(
        center: UserNotificationCenter = UNUserNotificationCenter.current(),
        calendar: Calendar = .current,
        reminderHour: Int = WateringNotificationScheduler.defaultReminderHour
    ) {
        self.center = center
        self.calendar = calendar
        self.reminderHour = reminderHour
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        // A denied/failed request must never throw out to callers — scheduling
        // simply becomes a no-op (graceful degradation, see LIMITATIONS).
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleReminder(for plant: Plant) async {
        let id = Self.identifier(for: plant.id)
        // Reschedule semantics: clear any existing reminder for this plant first,
        // so a moved `nextDue` replaces rather than duplicates the reminder.
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard let due = plant.nextDue else { return }
        guard await requestAuthorization() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to water \(plant.nickname)"
        content.body = "\(plant.nickname) (\(plant.species)) is due for watering."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents(for: due),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelReminder(for plantID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(for: plantID)])
    }

    /// Date components that fire on the due **day** at the configured reminder
    /// hour (minute zero) — calendar-based so it lands at the local wall-clock
    /// time regardless of DST shifts between scheduling and firing.
    private func triggerComponents(for due: Date) -> DateComponents {
        var comps = calendar.dateComponents([.year, .month, .day], from: due)
        comps.hour = reminderHour
        comps.minute = 0
        return comps
    }
}
