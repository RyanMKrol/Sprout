import SwiftUI

/// The **Settings** screen (T014). The preferred watering reminder time-of-day,
/// bound to `SettingsViewModel`, which persists the change immediately and
/// reschedules pending reminders when the time moves. (The temperature unit and the
/// weather toggle were removed in T212 with the phone-weather retirement.) Reached
/// for screenshots via the `SPROUT_SCREEN=settings` deep-link.
///
/// Pure presentation: all persistence + rescheduling wiring lives in the view
/// model; this view only binds the controls. Restyled per redesign-spec.md §3
/// screen 24 using existing DesignSystem primitives.
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var testReminderSent = false
    @State private var showTimePickerSheet = false
    @State private var selectedTime = Date()
    @State private var replayingIntro = false

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            SproutTheme.paper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top spacer
                Spacer()
                    .frame(height: 20)

                // Header: Settings title + Done button
                HStack {
                    Text("Settings")
                        .font(SproutFont.display(18))
                        .foregroundStyle(SproutTheme.ink)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(SproutFont.body(17, weight: .semibold))
                        .foregroundStyle(SproutTheme.brandGreen)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 22)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // REMINDERS section
                        Text("REMINDERS")
                            .font(SproutFont.body(11, weight: .semibold))
                            .tracking(0.56)
                            .textCase(.uppercase)
                            .foregroundStyle(SproutTheme.taupe)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            Button(
                                action: {
                                    selectedTime = viewModel.reminderTime
                                    showTimePickerSheet = true
                                },
                                label: {
                                    HStack(spacing: 12) {
                                        Text("Reminder time")
                                            .font(SproutFont.body(17))
                                            .foregroundStyle(SproutTheme.ink)
                                        Spacer()
                                        Text(formatReminderTime())
                                            .font(SproutFont.body(17, weight: .semibold))
                                            .foregroundStyle(SproutTheme.brandGreen)
                                            .padding(.horizontal, 11)
                                            .padding(.vertical, 5)
                                            .background(SproutTheme.softGreenFill)
                                            .cornerRadius(SproutTheme.Radius.chip)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SproutTheme.cardSurface)
                        }
                        .cornerRadius(SproutTheme.Radius.row)
                        .cardShadow()
                        .padding(.horizontal, 20)

                        Text(
                            "Watering reminders arrive at this time on the day a plant is due — " +
                            "pick a window you're usually home."
                        )
                            .font(SproutFont.body(13))
                            .foregroundStyle(SproutTheme.textHint)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        // DEVELOPER section
                        Text("DEVELOPER")
                            .font(SproutFont.body(11, weight: .semibold))
                            .tracking(0.56)
                            .textCase(.uppercase)
                            .foregroundStyle(SproutTheme.taupe)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        VStack(spacing: 0) {
                            // Camera diagnostics row
                            NavigationLink(destination: DiagnosticsView()) {
                                HStack(spacing: 12) {
                                    ChromeIcon.fileLines.image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(SproutTheme.ink)
                                    Text("Camera diagnostics")
                                        .font(SproutFont.body(17))
                                        .foregroundStyle(SproutTheme.ink)
                                    Spacer()
                                    ChromeIcon.chevronRight.image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(SproutTheme.taupe)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }

                            Divider()
                                .background(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.08))
                                .padding(.horizontal, 16)

                            // Test reminder row
                            Button(
                                action: {
                                    Task {
                                        await viewModel.sendTestReminder()
                                        testReminderSent = true
                                    }
                                },
                                label: {
                                    HStack(spacing: 12) {
                                        ChromeIcon.bell.image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(SproutTheme.ink)
                                        Text("Send a test reminder (5s)")
                                            .font(SproutFont.body(17))
                                            .foregroundStyle(SproutTheme.ink)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            )

                            Divider()
                                .background(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.08))
                                .padding(.horizontal, 16)

                            // Replay welcome intro row — re-shows the first-run intro and
                            // clears the "seen" flag so it also fires again on next launch.
                            Button(
                                action: {
                                    ContentView.resetIntroSeen()
                                    replayingIntro = true
                                },
                                label: {
                                    HStack(spacing: 12) {
                                        ChromeIcon.seedling.image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(SproutTheme.ink)
                                        Text("Replay welcome intro")
                                            .font(SproutFont.body(17))
                                            .foregroundStyle(SproutTheme.ink)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            )

                            Divider()
                                .background(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.08))
                                .padding(.horizontal, 16)

                            // Delete row
                            Button(
                                action: { showDeleteAlert = true },
                                label: {
                                    HStack(spacing: 12) {
                                        ChromeIcon.trash.image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(SproutTheme.destructive)
                                        Text("Delete all plants & rooms")
                                            .font(SproutFont.body(17))
                                            .foregroundStyle(SproutTheme.destructive)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            )
                        }
                        .background(SproutTheme.cardSurface)
                        .cornerRadius(SproutTheme.Radius.row)
                        .cardShadow()
                        .padding(.horizontal, 20)

                        Text(
                            "Diagnostics capture camera issues. The test reminder fires in 5 seconds. Deleting is permanent."
                        )
                            .font(SproutFont.body(13))
                            .foregroundStyle(SproutTheme.textHint)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .accessibilityIdentifier("settings")
        .sproutAlert(isPresented: $showDeleteAlert) {
            SproutAlert(
                icon: .trash,
                tint: SproutTheme.destructive,
                title: "Delete everything?",
                message: "Every plant, room and check-in will be removed. This can't be undone.",
                confirmLabel: "Delete",
                confirmRole: .destructive,
                onConfirm: {
                    viewModel.deleteAllData()
                    dismiss()
                }, onCancel: {
                    showDeleteAlert = false
                }
            )
        }
        .sheet(isPresented: $replayingIntro) {
            NotificationIntroView(
                onEnable: { replayingIntro = false },
                onSkip: { replayingIntro = false }
            )
        }
        .sheet(isPresented: $showTimePickerSheet) {
            TimePickerSheet(
                reminderTime: $selectedTime,
                onUpdate: { newDate in
                    Task { await viewModel.updateReminderTime(newDate) }
                }, onDismiss: { showTimePickerSheet = false }
            )
        }
        .alert("Test reminder scheduled", isPresented: $testReminderSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "A test notification will arrive in about 5 seconds. If nothing appears, " +
                "check Settings ▸ Notifications ▸ Sprout is allowed. Lock or background " +
                "the app to see it on the lock screen."
            )
        }
    }

    private func formatReminderTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: viewModel.reminderTime)
    }
}

// Time picker sheet
private struct TimePickerSheet: View {
    @Binding var reminderTime: Date
    let onUpdate: (Date) -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "Select time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .padding()

                Spacer()
            }
            .navigationTitle("Reminder time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onUpdate(reminderTime)
                        dismiss()
                    }
                    .foregroundStyle(SproutTheme.brandGreen)
                }
            }
        }
    }
}
