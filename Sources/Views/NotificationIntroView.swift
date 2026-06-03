import SwiftUI

/// A friendly first-run explainer shown once before the system notification prompt, so
/// the user understands *why* Sprout wants to notify them (watering reminders) rather
/// than meeting a bare iOS permission dialog cold. "Enable reminders" triggers the
/// system prompt; "Maybe later" defers (the home bell + banner keep nudging).
struct NotificationIntroView: View {
    /// Called when the user opts in — the caller requests authorization.
    let onEnable: () -> Void
    /// Called when the user defers.
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.27, green: 0.67, blue: 0.96),
                                                  Color(red: 0.16, green: 0.46, blue: 0.87)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 110)
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Never miss a watering")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Sprout sends a once-a-day reminder when your plants need water, at a time you choose. Turn on notifications so it can reach you.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onEnable) {
                    Text("Enable reminders")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)

                Button("Maybe later", action: onSkip)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }
}
