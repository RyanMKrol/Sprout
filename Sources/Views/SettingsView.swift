import SwiftUI

/// The **Settings** screen (T014). Three preferences — the preferred watering
/// reminder time-of-day, the temperature unit, and the weather toggle — each
/// bound to `SettingsViewModel`, which persists every change immediately and
/// reschedules pending reminders when the time moves. Reached for screenshots via
/// the `SPROUT_SCREEN=settings` deep-link.
///
/// Pure presentation: all persistence + rescheduling wiring lives in the view
/// model; this view only binds the controls.
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Reminder time",
                        selection: Binding(
                            get: { viewModel.reminderTime },
                            set: { newDate in Task { await viewModel.updateReminderTime(newDate) } }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Watering reminders arrive at this time on the day a plant is due — pick a window you're usually home.")
                }

                Section("Units") {
                    Picker(
                        "Temperature",
                        selection: Binding(
                            get: { viewModel.temperatureUnit },
                            set: { viewModel.setTemperatureUnit($0) }
                        )
                    ) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                }

                Section {
                    Toggle(
                        "Adjust for weather",
                        isOn: Binding(
                            get: { viewModel.weatherEnabled },
                            set: { viewModel.setWeatherEnabled($0) }
                        )
                    )
                } footer: {
                    Text("When on, Sprout shortens schedules in hot spells and lengthens them in cold ones.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
