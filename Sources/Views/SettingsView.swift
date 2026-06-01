import SwiftUI

/// The **Settings** screen (T014). The preferred watering reminder time-of-day,
/// bound to `SettingsViewModel`, which persists the change immediately and
/// reschedules pending reminders when the time moves. (The temperature unit and the
/// weather toggle were removed in T212 with the phone-weather retirement.) Reached
/// for screenshots via the `SPROUT_SCREEN=settings` deep-link.
///
/// Pure presentation: all persistence + rescheduling wiring lives in the view
/// model; this view only binds the controls.
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var resetConfirmationPresented = false

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

                Section {
                    Button("Delete all plants & rooms", role: .destructive) {
                        resetConfirmationPresented = true
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Removes every plant and room from this device. This can't be undone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete all plants & rooms?",
                isPresented: $resetConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) {
                    viewModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every plant and room on this device. This can't be undone.")
            }
        }
    }
}
