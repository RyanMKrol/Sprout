import Foundation

/// Boundary for scheduling the app's watering reminders (T013).
///
/// The app and view-models depend on **this protocol**, never on
/// `UNUserNotificationCenter` directly — so the notification engine can be stubbed in
/// tests (see `StubNotificationCenter` in the test target) without touching callers,
/// mirroring how the UI depends on `PlantRepository` rather than SwiftData.
///
/// **Reminder model — a daily digest, not one-per-plant.** The user gets **at most one**
/// notification per day, fired at the settings-configured hour, telling them how many
/// plants need watering that day (overdue plants fold into today). `refreshDailyReminders`
/// recomputes the whole schedule from the current plant set, so callers just hand over all
/// plants whenever anything changes rather than tracking per-plant requests.
///
/// All methods are `async`: scheduling may need to request authorization first, and the
/// underlying `UNUserNotificationCenter` API is itself `async`. Implementations must
/// **degrade gracefully** — if the user denies permission, scheduling becomes a silent
/// no-op rather than an error (see `docs/LIMITATIONS.md`).
protocol NotificationScheduling {
    /// Ask the system for permission to post notifications, returning whether it was
    /// granted. Safe to call repeatedly — the OS only prompts once and returns the
    /// cached decision thereafter.
    @discardableResult
    func requestAuthorization() async -> Bool

    /// Recompute the **daily watering digest** from scratch for `plants`: clear every
    /// reminder this scheduler owns, then schedule **one** reminder per calendar day on
    /// which at least one plant is due (overdue plants fold into today), each firing at
    /// the configured hour with a body naming how many plants need water that day.
    /// Idempotent — calling it again after a change replaces rather than stacks.
    /// A no-op (beyond clearing) when permission is denied.
    func refreshDailyReminders(for plants: [Plant]) async

    /// Fire a one-off **test** reminder a few seconds out, so the user can confirm
    /// notifications are authorised and delivering (Developer tooling).
    func sendTestReminder(after seconds: TimeInterval) async
}
