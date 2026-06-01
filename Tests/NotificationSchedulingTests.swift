import XCTest
import UserNotifications
@testable import Sprout

/// Integration tests for `WateringNotificationScheduler` (T013), exercised through
/// a `StubNotificationCenter` that records every add/remove so we can assert which
/// reminder was scheduled, that it lands on the right date, that a check-in
/// reschedules rather than duplicates, and that a denied permission degrades to a
/// no-op. No real `UNUserNotificationCenter` is touched.
final class NotificationSchedulingTests: XCTestCase {
    /// A recording stand-in for `UNUserNotificationCenter`. Keeps the pending set
    /// keyed by identifier, mirroring the real center's "one request per id".
    private final class StubNotificationCenter: UserNotificationCenter {
        var authorizationGranted = true
        private(set) var authorizationRequestCount = 0
        private(set) var pending: [UNNotificationRequest] = []

        func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
            authorizationRequestCount += 1
            return authorizationGranted
        }

        func add(_ request: UNNotificationRequest) async throws {
            pending.removeAll { $0.identifier == request.identifier }
            pending.append(request)
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            pending.removeAll { identifiers.contains($0.identifier) }
        }

        func pendingNotificationRequests() async -> [UNNotificationRequest] {
            pending
        }
    }

    // A UTC calendar so the asserted trigger components are deterministic.
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func date(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12
        comps.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: comps)!
    }

    private func plant(nextDue: Date?, id: UUID = UUID()) -> Plant {
        Plant(
            id: id,
            nickname: "Monty",
            species: "Monstera deliciosa",
            adj: 1.0,
            lastWatered: nil,
            nextDue: nextDue,
            checkIns: []
        )
    }

    private func trigger(_ request: UNNotificationRequest) -> UNCalendarNotificationTrigger? {
        request.trigger as? UNCalendarNotificationTrigger
    }

    // MARK: - scheduling

    func testSchedulesReminderForNextDueDateAtReminderHour() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar, reminderHour: 9)
        let due = date(year: 2026, month: 6, day: 15)
        let p = plant(nextDue: due)

        await scheduler.scheduleReminder(for: p)

        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 1)
        let request = requests[0]
        XCTAssertEqual(request.identifier, WateringNotificationScheduler.identifier(for: p.id))

        let comps = trigger(request)?.dateComponents
        XCTAssertEqual(comps?.year, 2026)
        XCTAssertEqual(comps?.month, 6)
        XCTAssertEqual(comps?.day, 15)
        XCTAssertEqual(comps?.hour, 9)
        XCTAssertEqual(comps?.minute, 0)
    }

    func testScheduledReminderMentionsThePlant() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)
        let p = plant(nextDue: date(year: 2026, month: 6, day: 15))

        await scheduler.scheduleReminder(for: p)

        let request = (await center.pendingNotificationRequests())[0]
        XCTAssertTrue(request.content.title.contains("Monty"))
    }

    func testNoReminderWhenPlantHasNoNextDue() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.scheduleReminder(for: plant(nextDue: nil))

        let requests = await center.pendingNotificationRequests()
        XCTAssertTrue(requests.isEmpty)
    }

    // MARK: - rescheduling (the check-in path)

    func testReschedulingReplacesRatherThanDuplicates() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar, reminderHour: 9)
        let id = UUID()

        await scheduler.scheduleReminder(for: plant(nextDue: date(year: 2026, month: 6, day: 15), id: id))
        // A check-in moves next-due — reschedule with the same plant id.
        await scheduler.scheduleReminder(for: plant(nextDue: date(year: 2026, month: 6, day: 22), id: id))

        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 1, "the plant should still own exactly one reminder")
        XCTAssertEqual(trigger(requests[0])?.dateComponents.day, 22)
    }

    func testDistinctPlantsGetDistinctReminders() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.scheduleReminder(for: plant(nextDue: date(year: 2026, month: 6, day: 15)))
        await scheduler.scheduleReminder(for: plant(nextDue: date(year: 2026, month: 6, day: 16)))

        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 2)
    }

    // MARK: - cancellation

    func testCancelRemovesTheReminder() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)
        let id = UUID()

        await scheduler.scheduleReminder(for: plant(nextDue: date(year: 2026, month: 6, day: 15), id: id))
        await scheduler.cancelReminder(for: id)

        let requests = await center.pendingNotificationRequests()
        XCTAssertTrue(requests.isEmpty)
    }

    // MARK: - graceful degradation

    func testDeniedAuthorizationSchedulesNothing() async {
        let center = StubNotificationCenter()
        center.authorizationGranted = false
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.scheduleReminder(for: plant(nextDue: date(year: 2026, month: 6, day: 15)))

        let requests = await center.pendingNotificationRequests()
        XCTAssertTrue(requests.isEmpty, "denied permission must degrade to a no-op, not crash")
    }

    func testRequestAuthorizationReturnsGrantedDecision() async {
        let center = StubNotificationCenter()
        center.authorizationGranted = true
        let granted = await WateringNotificationScheduler(center: center, calendar: calendar).requestAuthorization()
        XCTAssertTrue(granted)

        center.authorizationGranted = false
        let denied = await WateringNotificationScheduler(center: center, calendar: calendar).requestAuthorization()
        XCTAssertFalse(denied)
    }
}
