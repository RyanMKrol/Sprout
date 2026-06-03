import XCTest
import UserNotifications
@testable import Sprout

/// Integration tests for `WateringNotificationScheduler` (T013), exercised through a
/// `StubNotificationCenter` that records every add/remove. The reminder model is a
/// **daily digest**: at most one reminder per day (at the configured hour) naming how
/// many plants are due that day, with overdue plants folded into today. No real
/// `UNUserNotificationCenter` is touched.
final class NotificationSchedulingTests: XCTestCase {
    /// A recording stand-in for `UNUserNotificationCenter`, keyed by identifier to
    /// mirror the real center's "one request per id".
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

        func pendingNotificationRequests() async -> [UNNotificationRequest] { pending }

        func authorizationStatus() async -> UNAuthorizationStatus {
            authorizationGranted ? .authorized : .denied
        }
    }

    // A UTC calendar so the asserted trigger components are deterministic.
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// Fixed "now" so digest bucketing (today / future / overdue) is deterministic.
    private lazy var now = date(year: 2026, month: 6, day: 10)

    private func date(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = 8; comps.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: comps)!
    }

    private func plant(nextDue: Date?, id: UUID = UUID()) -> Plant {
        Plant(id: id, nickname: "Monty", species: "Monstera deliciosa", nextDue: nextDue)
    }

    private func calendarTrigger(_ request: UNNotificationRequest) -> UNCalendarNotificationTrigger? {
        request.trigger as? UNCalendarNotificationTrigger
    }

    // MARK: - the pure digest

    func testDailyDigestGroupsByDayAndFoldsOverdueIntoToday() {
        let plants = [
            plant(nextDue: date(year: 2026, month: 6, day: 15)), // future day A
            plant(nextDue: date(year: 2026, month: 6, day: 15)), // same future day A
            plant(nextDue: date(year: 2026, month: 6, day: 18)), // future day B
            plant(nextDue: date(year: 2026, month: 6, day: 5)),  // overdue → folds to today (the 10th)
            plant(nextDue: nil),                                  // unscheduled → ignored
        ]

        let digest = WateringNotificationScheduler.dailyDigest(plants: plants, now: now, calendar: calendar)

        // Three distinct days: today (folded overdue), the 15th (×2), the 18th.
        XCTAssertEqual(digest.map { calendar.component(.day, from: $0.day) }, [10, 15, 18])
        XCTAssertEqual(digest.map(\.count), [1, 2, 1])
    }

    // MARK: - scheduling

    func testSchedulesOneReminderPerDueDayAtReminderHour() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar, reminderHour: 9)

        await scheduler.refreshDailyReminders(
            for: [
                plant(nextDue: date(year: 2026, month: 6, day: 15)),
                plant(nextDue: date(year: 2026, month: 6, day: 15)),
                plant(nextDue: date(year: 2026, month: 6, day: 18)),
            ],
            now: now
        )

        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 2, "two due-days → two reminders, not one per plant")
        XCTAssertTrue(requests.allSatisfy { calendarTrigger($0)?.dateComponents.hour == 9 })
        XCTAssertTrue(requests.allSatisfy { calendarTrigger($0)?.dateComponents.minute == 0 })
    }

    func testReminderBodyCountsPlantsDueThatDay() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.refreshDailyReminders(
            for: [
                plant(nextDue: date(year: 2026, month: 6, day: 15)),
                plant(nextDue: date(year: 2026, month: 6, day: 15)),
            ],
            now: now
        )

        let request = (await center.pendingNotificationRequests())[0]
        XCTAssertTrue(request.content.body.contains("2 plants"), "body should aggregate the count")
    }

    func testSinglePlantBodyUsesSingular() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.refreshDailyReminders(for: [plant(nextDue: date(year: 2026, month: 6, day: 15))], now: now)

        let request = (await center.pendingNotificationRequests())[0]
        XCTAssertTrue(request.content.body.contains("1 plant needs"))
    }

    // MARK: - refresh replaces (the change path)

    func testRefreshReplacesRatherThanStacks() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar, reminderHour: 9)

        await scheduler.refreshDailyReminders(for: [plant(nextDue: date(year: 2026, month: 6, day: 15))], now: now)
        // The schedule moved (e.g. a check-in) — refresh with the new state.
        await scheduler.refreshDailyReminders(for: [plant(nextDue: date(year: 2026, month: 6, day: 22))], now: now)

        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 1, "the old day's reminder should be cleared, not stacked")
        XCTAssertEqual(calendarTrigger(requests[0])?.dateComponents.day, 22)
    }

    func testRefreshWithNoDuePlantsClearsReminders() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.refreshDailyReminders(for: [plant(nextDue: date(year: 2026, month: 6, day: 15))], now: now)
        await scheduler.refreshDailyReminders(for: [plant(nextDue: nil)], now: now)

        let requests = await center.pendingNotificationRequests()
        XCTAssertTrue(requests.isEmpty, "no scheduled plants → no reminders")
    }

    // MARK: - test reminder

    func testSendTestReminderSchedulesATimeIntervalRequest() async {
        let center = StubNotificationCenter()
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.sendTestReminder(after: 5)

        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertTrue(requests[0].trigger is UNTimeIntervalNotificationTrigger)
    }

    // MARK: - graceful degradation

    func testDeniedAuthorizationSchedulesNothing() async {
        let center = StubNotificationCenter()
        center.authorizationGranted = false
        let scheduler = WateringNotificationScheduler(center: center, calendar: calendar)

        await scheduler.refreshDailyReminders(for: [plant(nextDue: date(year: 2026, month: 6, day: 15))], now: now)

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
