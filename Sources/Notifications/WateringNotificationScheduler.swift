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
    func authorizationStatus() async -> UNAuthorizationStatus
}

extension UNUserNotificationCenter: UserNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}

/// Schedules **daily** watering reminders via `UNUserNotificationCenter` (T013).
///
/// Rather than one reminder per plant, the user gets **at most one reminder per day**,
/// fired at a fixed hour, telling them how many plants need watering that day. Each
/// `refreshDailyReminders` clears the reminders this scheduler owns and rebuilds the set
/// from the current plants, so the schedule always reflects the latest data and never
/// stacks duplicates. Overdue plants fold into today's reminder. Authorization is
/// requested lazily and the scheduler degrades gracefully to a no-op if denied.
struct WateringNotificationScheduler: NotificationScheduling {
    /// Default reminder hour-of-day (24h); user-configurable via Settings (T014).
    static let defaultReminderHour = 9

    /// Identifier prefix for the daily-digest requests this scheduler owns (so a refresh
    /// can find and clear them). Distinct from the test reminder's identifier.
    private static let identifierPrefix = "sprout.watering."
    /// The identifier for the one-off Developer test reminder.
    private static let testIdentifier = "sprout.test.reminder"

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

    // MARK: - Digest (pure)

    /// The per-day watering digest: for each calendar day (start-of-day) on which at
    /// least one plant is due, how many plants are due that day. **Overdue plants fold
    /// into today** so they aren't silently dropped. One entry per day → one reminder.
    /// Pure and `now`-injectable so it's deterministic in tests.
    static func dailyDigest(plants: [Plant], now: Date, calendar: Calendar) -> [(day: Date, count: Int)] {
        let today = calendar.startOfDay(for: now)
        var counts: [Date: Int] = [:]
        for plant in plants {
            guard let due = plant.nextDue else { continue }
            let day = max(calendar.startOfDay(for: due), today)
            counts[day, default: 0] += 1
        }
        return counts
            .map { (day: $0.key, count: $0.value) }
            .sorted { $0.day < $1.day }
    }

    // MARK: - NotificationScheduling

    @discardableResult
    func requestAuthorization() async -> Bool {
        // A denied/failed request must never throw out to callers — scheduling simply
        // becomes a no-op (graceful degradation, see LIMITATIONS).
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func refreshDailyReminders(for plants: [Plant]) async {
        await refreshDailyReminders(for: plants, now: Date())
    }

    /// `now`-injectable variant used by tests for determinism.
    func refreshDailyReminders(for plants: [Plant], now: Date) async {
        // Always clear what we own first, so a refresh replaces rather than stacks (and
        // a now-empty schedule clears stale reminders).
        await clearOwnedReminders()
        guard await requestAuthorization() else { return }

        for entry in Self.dailyDigest(plants: plants, now: now, calendar: calendar) {
            let content = UNMutableNotificationContent()
            content.title = "Time to water your plants 🌱"
            content.body = entry.count == 1
                ? "1 plant needs watering today."
                : "\(entry.count) plants need watering today."
            content.sound = .default

            var comps = calendar.dateComponents([.year, .month, .day], from: entry.day)
            comps.hour = reminderHour
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.dailyIdentifier(for: comps),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.authorizationStatus()
    }

    func sendTestReminder(after seconds: TimeInterval) async {
        guard await requestAuthorization() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Test reminder 🌱"
        content.body = "If you can see this, watering reminders are working."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: Self.testIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Helpers

    /// Remove every pending reminder this scheduler owns (matched by identifier prefix),
    /// leaving anything else (e.g. a pending test reminder) untouched.
    private func clearOwnedReminders() async {
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Stable per-day identifier, e.g. `sprout.watering.2026-06-15`.
    static func dailyIdentifier(for comps: DateComponents) -> String {
        identifierPrefix + String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}
