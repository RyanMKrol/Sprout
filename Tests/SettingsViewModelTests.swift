import XCTest
import UserNotifications
@testable import Sprout

/// Unit + integration tests for the Settings feature (T014).
///
/// Two things the Done-when calls out are covered here: **values persist across
/// launches** (a fresh view model over the same store reads back what a prior one
/// saved) and **changing the preferred time reschedules reminders to the new hour**
/// (a real `WateringNotificationScheduler` driven against a recording stub center
/// lands its trigger at the chosen hour).
@MainActor
final class SettingsViewModelTests: XCTestCase {
    /// A recording stand-in for `UNUserNotificationCenter` (mirrors the one in the
    /// notification tests) so we can assert the rescheduled trigger's hour.
    private final class StubNotificationCenter: UserNotificationCenter {
        private(set) var pending: [UNNotificationRequest] = []

        func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }

        func add(_ request: UNNotificationRequest) async throws {
            pending.removeAll { $0.identifier == request.identifier }
            pending.append(request)
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            pending.removeAll { identifiers.contains($0.identifier) }
        }

        func pendingNotificationRequests() async -> [UNNotificationRequest] { pending }
    }

    // A UTC calendar so asserted trigger components are deterministic.
    private let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// A fresh, isolated UserDefaults so tests don't see each other's writes or the
    /// app's. Cleared on creation.
    private func ephemeralStore(suite: String = "sprout.settings.tests") -> (UserDefaultsSettingsStore, UserDefaults) {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (UserDefaultsSettingsStore(defaults: defaults), defaults)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: comps)!
    }

    private func plant(nextDue: Date?) -> Plant {
        Plant(nickname: "Monty", species: "Monstera deliciosa", nextDue: nextDue)
    }

    // MARK: - defaults

    func testFreshStoreYieldsDefaultSettings() {
        let (store, _) = ephemeralStore(suite: "sprout.settings.tests.defaults")
        let vm = SettingsViewModel(store: store)
        XCTAssertEqual(vm.reminderHour, WateringNotificationScheduler.defaultReminderHour)
    }

    // MARK: - persistence across launches

    func testSettingsPersistAcrossLaunches() async {
        let suite = "sprout.settings.tests.persist"
        let (store, defaults) = ephemeralStore(suite: suite)

        let first = SettingsViewModel(store: store)
        await first.updateReminderHour(7)

        // A new view model over the same defaults simulates a relaunch.
        let relaunched = SettingsViewModel(store: UserDefaultsSettingsStore(defaults: defaults))
        XCTAssertEqual(relaunched.reminderHour, 7)
    }

    // MARK: - reminder time → reschedule

    func testChangingReminderTimeReschedulesAtTheNewHour() async {
        let (store, _) = ephemeralStore(suite: "sprout.settings.tests.reschedule")
        let center = StubNotificationCenter()
        let repository = try! PlantStore.inMemory()
        try! repository.add(plant(nextDue: date(year: 2026, month: 6, day: 15, hour: 12)))

        let vm = SettingsViewModel(
            store: store,
            repository: repository,
            makeScheduler: { hour in
                WateringNotificationScheduler(center: center, calendar: self.utcCalendar, reminderHour: hour)
            },
            calendar: utcCalendar
        )

        await vm.updateReminderTime(date(year: 2000, month: 1, day: 1, hour: 20))

        XCTAssertEqual(vm.reminderHour, 20)
        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 1)
        let comps = (requests[0].trigger as? UNCalendarNotificationTrigger)?.dateComponents
        XCTAssertEqual(comps?.day, 15)
        XCTAssertEqual(comps?.hour, 20, "the reminder should fire at the newly-chosen hour")
        XCTAssertEqual(comps?.minute, 0)
    }

    func testReminderHourIsClampedToValidRange() async {
        let (store, _) = ephemeralStore(suite: "sprout.settings.tests.clamp")
        let vm = SettingsViewModel(store: store)
        await vm.updateReminderHour(99)
        XCTAssertEqual(vm.reminderHour, AppSettings.reminderHourRange.upperBound)
        await vm.updateReminderHour(-5)
        XCTAssertEqual(vm.reminderHour, AppSettings.reminderHourRange.lowerBound)
    }

    func testReschedulesEveryPlant() async {
        let (store, _) = ephemeralStore(suite: "sprout.settings.tests.allplants")
        let center = StubNotificationCenter()
        let repository = try! PlantStore.inMemory()
        try! repository.add(plant(nextDue: date(year: 2026, month: 6, day: 15, hour: 12)))
        try! repository.add(Plant(nickname: "Fern", species: "Boston Fern", nextDue: date(year: 2026, month: 6, day: 18, hour: 12)))

        let vm = SettingsViewModel(
            store: store,
            repository: repository,
            makeScheduler: { hour in
                WateringNotificationScheduler(center: center, calendar: self.utcCalendar, reminderHour: hour)
            },
            calendar: utcCalendar
        )
        await vm.updateReminderHour(18)

        let requests = await center.pendingNotificationRequests()
        XCTAssertEqual(requests.count, 2, "every plant's reminder should be rescheduled")
        XCTAssertTrue(requests.allSatisfy { ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents.hour == 18 })
    }

    // MARK: - developer data reset (T216)

    func testDeleteAllDataWipesPlantsAndRoomsAndNotifies() async {
        let (store, _) = ephemeralStore(suite: "sprout.settings.tests.reset")
        let repository = try! PlantStore.inMemory()
        try! repository.add(plant(nextDue: nil))
        try! repository.addRoom(Room(name: "Studio"))

        var didReset = false
        let vm = SettingsViewModel(
            store: store,
            repository: repository,
            onDataReset: { didReset = true }
        )

        vm.deleteAllData()

        XCTAssertTrue(try! repository.allPlants().isEmpty)
        XCTAssertTrue(try! repository.allRooms().isEmpty)
        XCTAssertTrue(didReset, "host should be notified to refresh after a reset")
    }

    func testDeleteAllDataWithoutRepositoryStillNotifies() {
        let (store, _) = ephemeralStore(suite: "sprout.settings.tests.reset.norepo")
        var didReset = false
        let vm = SettingsViewModel(store: store, onDataReset: { didReset = true })
        vm.deleteAllData()
        XCTAssertTrue(didReset)
    }

    // MARK: - reminderTime projection

    func testReminderTimeReflectsTheStoredHour() {
        let (store, _) = ephemeralStore(suite: "sprout.settings.tests.projection")
        let vm = SettingsViewModel(store: store, calendar: utcCalendar)
        XCTAssertEqual(utcCalendar.component(.hour, from: vm.reminderTime), WateringNotificationScheduler.defaultReminderHour)
    }

}
