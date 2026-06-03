import XCTest
import UserNotifications
@testable import Sprout

/// Unit tests for `NotificationGatekeeper`: the status mapping that drives the home
/// bell / banner, and that `enable()` prompts when undetermined but deep-links to
/// Settings when previously denied.
@MainActor
final class NotificationGatekeeperTests: XCTestCase {
    /// A stub scheduler that reports a settable status and records calls, so we can drive
    /// the gatekeeper without touching the real notification center.
    private final class StubScheduler: NotificationScheduling {
        var status: UNAuthorizationStatus
        var grantOnRequest: Bool
        private(set) var requestCount = 0
        private(set) var refreshCount = 0

        init(status: UNAuthorizationStatus, grantOnRequest: Bool = true) {
            self.status = status
            self.grantOnRequest = grantOnRequest
        }

        func requestAuthorization() async -> Bool {
            requestCount += 1
            // Mimic the system: a fresh grant flips the status to authorized.
            if grantOnRequest { status = .authorized }
            return grantOnRequest
        }

        func refreshDailyReminders(for plants: [Plant]) async { refreshCount += 1 }
        func sendTestReminder(after seconds: TimeInterval) async {}
        func authorizationStatus() async -> UNAuthorizationStatus { status }
    }

    // MARK: - status mapping

    func testStatusMapping() {
        XCTAssertEqual(NotificationGatekeeper.map(.authorized), .authorized)
        XCTAssertEqual(NotificationGatekeeper.map(.provisional), .authorized)
        XCTAssertEqual(NotificationGatekeeper.map(.denied), .denied)
        XCTAssertEqual(NotificationGatekeeper.map(.notDetermined), .notDetermined)
    }

    func testNeedsAttentionOnlyWhenNotEnabled() async {
        let gk = NotificationGatekeeper(scheduler: StubScheduler(status: .notDetermined), openSettings: {})
        await gk.refresh()
        XCTAssertTrue(gk.needsAttention)
        XCTAssertFalse(gk.isAuthorized)

        let authed = NotificationGatekeeper(scheduler: StubScheduler(status: .authorized), openSettings: {})
        await authed.refresh()
        XCTAssertFalse(authed.needsAttention)
        XCTAssertTrue(authed.isAuthorized)
    }

    // MARK: - enable()

    func testEnableFromNotDeterminedPromptsAndSchedules() async {
        let scheduler = StubScheduler(status: .notDetermined, grantOnRequest: true)
        var openedSettings = false
        var didAuthorizeCallback = false
        let gk = NotificationGatekeeper(
            scheduler: scheduler,
            onAuthorized: { didAuthorizeCallback = true },
            openSettings: { openedSettings = true }
        )
        await gk.refresh()

        await gk.enable()

        XCTAssertEqual(scheduler.requestCount, 1, "should prompt when undetermined")
        XCTAssertFalse(openedSettings, "should not open Settings when it can prompt")
        XCTAssertTrue(gk.isAuthorized)
        XCTAssertTrue(didAuthorizeCallback, "a fresh grant should schedule the digest")
    }

    func testEnableFromDeniedOpensSettings() async {
        let scheduler = StubScheduler(status: .denied)
        var openedSettings = false
        let gk = NotificationGatekeeper(
            scheduler: scheduler,
            openSettings: { openedSettings = true }
        )
        await gk.refresh()

        await gk.enable()

        XCTAssertTrue(openedSettings, "a previously-denied user must be sent to Settings")
        XCTAssertEqual(scheduler.requestCount, 0, "re-prompting does nothing once denied, so don't")
    }
}
