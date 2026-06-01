import Foundation

/// Boundary for scheduling a plant's watering reminders (T013).
///
/// The app and view-models depend on **this protocol**, never on
/// `UNUserNotificationCenter` directly — so the notification engine can be
/// stubbed in tests (see `StubNotificationCenter` in the test target) without
/// touching callers, mirroring how the UI depends on `PlantRepository` rather
/// than SwiftData.
///
/// All methods are `async`: scheduling a reminder may need to request
/// authorization first, and the underlying `UNUserNotificationCenter` API is
/// itself `async`. Implementations must **degrade gracefully** — if the user
/// denies notification permission, scheduling becomes a silent no-op rather
/// than an error (see `docs/LIMITATIONS.md`).
protocol NotificationScheduling {
    /// Ask the system for permission to post notifications, returning whether it
    /// was granted. Safe to call repeatedly — the OS only prompts the user once
    /// and returns the cached decision thereafter.
    @discardableResult
    func requestAuthorization() async -> Bool

    /// Schedule (or **reschedule**) the single watering reminder for `plant`.
    ///
    /// Idempotent per plant: any existing pending reminder for the plant is
    /// removed first, so calling this again after a check-in moves the reminder
    /// to the plant's new `nextDue` rather than stacking duplicates. A plant with
    /// no `nextDue`, or when permission is denied, results in no pending
    /// reminder.
    func scheduleReminder(for plant: Plant) async

    /// Cancel any pending watering reminder for the plant with `plantID`
    /// (e.g. when the plant is deleted).
    func cancelReminder(for plantID: UUID) async
}
