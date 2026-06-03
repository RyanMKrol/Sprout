import Foundation

/// The user's app-wide preferences: the hour-of-day watering reminders fire on a
/// plant's due date. (Temperature unit + the weather toggle were removed in T212 when
/// the phone-weather schedule input was retired in favour of Rooms.)
///
/// A plain `Codable` value type so it round-trips through `SettingsStore`
/// (UserDefaults) and unit tests assert the persisted decision, not UI state. Decoding
/// ignores any legacy keys (e.g. an old `weatherEnabled`) from a previous install.
struct AppSettings: Equatable, Codable, Sendable {
    /// Hour-of-day (0–23) the daily watering reminder fires at. Drives
    /// `WateringNotificationScheduler`'s `reminderHour` — changing it rebuilds the
    /// daily digest at the new time.
    var reminderHour: Int

    /// Valid hour-of-day band for `reminderHour`.
    static let reminderHourRange: ClosedRange<Int> = 0...23

    /// First-run default: the same reminder hour T013 shipped.
    static let `default` = AppSettings(
        reminderHour: WateringNotificationScheduler.defaultReminderHour
    )
}

/// Persistence boundary for `AppSettings` (T014). The view model depends on this
/// protocol, not `UserDefaults` directly, so tests inject an ephemeral store and
/// assert that values survive a simulated relaunch.
protocol SettingsStore {
    /// The persisted settings, or `AppSettings.default` when nothing is stored yet.
    func load() -> AppSettings
    /// Persist `settings`, overwriting any previous value.
    func save(_ settings: AppSettings)
}

/// `UserDefaults`-backed `SettingsStore`: encodes `AppSettings` as JSON under a
/// single key so adding a field later doesn't strand orphan keys.
struct UserDefaultsSettingsStore: SettingsStore {
    private static let key = "sprout.settings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard
            let data = defaults.data(forKey: Self.key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return .default }
        return settings
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

/// Drives the **Settings** screen (T014): the preferred reminder time-of-day, the
/// temperature unit, and the weather toggle. Every change is **persisted
/// immediately** via `SettingsStore`, and changing the reminder time
/// **reschedules** every plant's pending watering reminder to the new hour — so
/// reminders fire in the user's chosen window.
///
/// All decision/wiring logic lives here behind a plain, testable surface: the
/// store is injected (an ephemeral one in tests asserts persistence-across-launch),
/// and rescheduling goes through an injected `makeScheduler` factory + repository so
/// a test can drive a real `WateringNotificationScheduler` against a stub center and
/// confirm the trigger hour moved.
@MainActor
final class SettingsViewModel: ObservableObject {
    /// Current reminder hour-of-day (0–23). Read by the view; mutated only through
    /// `updateReminderHour`/`updateReminderTime` so persistence + reschedule stay
    /// coupled to the change.
    @Published private(set) var reminderHour: Int

    private let store: SettingsStore
    /// The plant source whose reminders are rescheduled when the time changes.
    /// `nil` (e.g. in pure-persistence tests) makes rescheduling a no-op.
    private let repository: PlantRepository?
    /// Builds a scheduler bound to a given reminder hour. Injected so tests drive a
    /// real scheduler against a stub center; defaults to the production scheduler.
    private let makeScheduler: (Int) -> NotificationScheduling
    private let calendar: Calendar
    /// Called after the developer data reset (T216) wipes plants + rooms, so the
    /// host can refresh the list/home. A no-op by default (and in tests).
    private let onDataReset: () -> Void

    init(
        store: SettingsStore = UserDefaultsSettingsStore(),
        repository: PlantRepository? = nil,
        makeScheduler: @escaping (Int) -> NotificationScheduling = { hour in
            WateringNotificationScheduler(reminderHour: hour)
        },
        calendar: Calendar = .current,
        onDataReset: @escaping () -> Void = {}
    ) {
        let settings = store.load()
        self.reminderHour = settings.reminderHour
        self.store = store
        self.repository = repository
        self.makeScheduler = makeScheduler
        self.calendar = calendar
        self.onDataReset = onDataReset
    }

    /// The reminder time as a `Date` for the view's `DatePicker` (hour-and-minute):
    /// today at `reminderHour:00`. Only the hour is meaningful — minutes are pinned
    /// to zero, matching the scheduler's calendar trigger.
    var reminderTime: Date {
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = reminderHour
        comps.minute = 0
        return calendar.date(from: comps) ?? Date()
    }

    /// Apply a reminder time picked as a `Date` — extracts its hour, persists, and
    /// reschedules. The view binds its `DatePicker` to this.
    func updateReminderTime(_ date: Date) async {
        await updateReminderHour(calendar.component(.hour, from: date))
    }

    /// Set the reminder hour (clamped to a valid hour-of-day), persist it, and
    /// reschedule every plant's reminder to the new time. A no-op reschedule when
    /// the hour is unchanged.
    func updateReminderHour(_ hour: Int) async {
        let clamped = min(max(hour, AppSettings.reminderHourRange.lowerBound), AppSettings.reminderHourRange.upperBound)
        guard clamped != reminderHour else { return }
        reminderHour = clamped
        persist()
        await rescheduleReminders()
    }

    /// Rebuild the daily watering digest at the current `reminderHour`, so the
    /// reminders move to the newly-chosen window. Repository errors degrade to a
    /// no-op rather than crashing settings.
    func rescheduleReminders() async {
        guard let repository else { return }
        let plants = (try? repository.allPlants()) ?? []
        await makeScheduler(reminderHour).refreshDailyReminders(for: plants)
    }

    /// Developer tooling: fire a one-off test reminder a few seconds out, so the user
    /// can confirm notifications are authorised and delivering on their device.
    func sendTestReminder() async {
        await makeScheduler(reminderHour).sendTestReminder(after: 5)
    }

    /// Developer reset (T216): delete **every** plant and room from the store, then
    /// notify the host (`onDataReset`) so the list/home refresh to their empty state.
    /// Repository errors degrade to a no-op rather than crashing settings.
    func deleteAllData() {
        guard let repository else { onDataReset(); return }
        try? repository.deleteAllPlants()
        try? repository.deleteAllRooms()
        onDataReset()
    }

    /// The current preferences as a value, for persistence.
    private var settings: AppSettings {
        AppSettings(reminderHour: reminderHour)
    }

    private func persist() {
        store.save(settings)
    }
}
