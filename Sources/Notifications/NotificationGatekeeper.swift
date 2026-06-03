import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// Observable notification-permission state for the UI (the home bell + warning banner +
/// first-run intro). Wraps the `NotificationScheduling` boundary so it queries the live
/// system status without prompting, re-prompts only when that can do anything, and falls
/// back to deep-linking the system Settings app when permission was previously denied.
@MainActor
final class NotificationGatekeeper: ObservableObject {
    /// App-level view of the system authorization status.
    enum Status { case unknown, notDetermined, authorized, denied }

    @Published private(set) var status: Status = .unknown

    private let scheduler: NotificationScheduling
    /// Opens the system Settings app (so a previously-denied user can re-enable). Injected
    /// so tests don't touch `UIApplication`.
    private let openSettings: () -> Void
    /// Called after permission is newly granted, so the daily digest gets scheduled.
    private let onAuthorized: () async -> Void

    init(
        scheduler: NotificationScheduling = WateringNotificationScheduler(),
        onAuthorized: @escaping () async -> Void = {},
        openSettings: @escaping () -> Void = NotificationGatekeeper.openSystemSettings
    ) {
        self.scheduler = scheduler
        self.onAuthorized = onAuthorized
        self.openSettings = openSettings
    }

    /// `true` once we know reminders are allowed.
    var isAuthorized: Bool { status == .authorized }

    /// `true` when the UI should nudge the user (not yet asked, or actively denied).
    /// `.unknown` (status not yet loaded) deliberately shows nothing to avoid a flash.
    var needsAttention: Bool { status == .notDetermined || status == .denied }

    /// Map the system status onto the app's coarse `Status`. Pure → unit-testable.
    static func map(_ status: UNAuthorizationStatus) -> Status {
        switch status {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .unknown
        }
    }

    /// Re-read the live system status (e.g. on launch and whenever the app re-activates,
    /// so returning from system Settings updates the indicator).
    func refresh() async {
        status = Self.map(await scheduler.authorizationStatus())
    }

    /// Drive the user toward enabled reminders: prompt if they haven't been asked, or
    /// open system Settings if they previously denied. Refreshes status and, on a fresh
    /// grant, schedules the digest.
    func enable() async {
        if status == .denied {
            openSettings()
            return
        }
        await scheduler.requestAuthorization()
        await refresh()
        if status == .authorized { await onAuthorized() }
    }

    #if DEBUG
    /// Force a status for demo screenshots (e.g. capturing the "reminders off" UI).
    func applyDemoStatus(_ status: Status) { self.status = status }
    #endif

    /// Default `openSettings`: deep-link to this app's page in the system Settings app.
    /// `nonisolated` so it's usable as a plain default closure; hops to the main actor
    /// to touch `UIApplication`.
    nonisolated static func openSystemSettings() {
        #if canImport(UIKit)
        Task { @MainActor in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        #endif
    }
}
