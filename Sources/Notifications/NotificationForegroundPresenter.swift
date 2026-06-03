import UserNotifications

/// Lets watering reminders show as a banner (with sound) **even while the app is in the
/// foreground** — without a delegate, iOS suppresses the alert when the app is active,
/// which makes the Developer "send a test reminder" button look broken. Set as the
/// notification-centre delegate once at launch via `activate()`.
final class NotificationForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationForegroundPresenter()

    /// Install this object as the `UNUserNotificationCenter` delegate.
    static func activate() {
        UNUserNotificationCenter.current().delegate = shared
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
