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
        VStack(spacing: 0) {
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(SproutTheme.logoGradient)
                        .frame(width: 112, height: 112)
                        .shadow(
                            color: Color(
                                red: 30.0 / 255, green: 70.0 / 255, blue: 50.0 / 255, opacity: 0.4
                            ),
                            radius: 34, y: 16
                        )

                    Image("fa-bell", bundle: nil)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 46, height: 46)
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                VStack(spacing: 16) {
                    Text("Never miss a watering")
                        .font(SproutFont.display(29))
                        .foregroundStyle(SproutTheme.ink)
                        .multilineTextAlignment(.center)

                    Text("Sprout sends one gentle reminder a day when your plants need water, at a time you choose. 🌱")
                        .font(SproutFont.body(16))
                        .foregroundStyle(SproutTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(1.5 * 16 - 16)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 44)

            VStack(spacing: 0) {
                Button(action: onEnable) {
                    Text("Enable reminders")
                }
                .buttonStyle(SproutPrimaryButtonStyle())
                .padding(.horizontal, 28)
                .padding(.bottom, 18)

                Button(action: onSkip) {
                    Text("Maybe later")
                }
                .font(SproutFont.body(17, weight: .semibold))
                .foregroundStyle(SproutTheme.brandGreen)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .sproutSheetBackground()
    }
}

#Preview {
    NotificationIntroView(onEnable: {}, onSkip: {})
        .sheet(isPresented: .constant(true)) {
            NotificationIntroView(onEnable: {}, onSkip: {})
                .sproutSheetBackground()
        }
}
