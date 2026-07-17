import SwiftUI

/// The **post-add photo prompt** — shown right after a multi-add commit to offer
/// photographing the just-created plants. This is a bottom sheet anchored to the add
/// flow with a gradient camera circle, title, body copy, and clear Take Photos / Skip
/// actions per the redesign spec (screen 12).
///
/// Pure presentation: the host owns the targets and the two outcome closures; the copy
/// lives in `PhotoPromptText` so it's unit-testable without the view.
struct PhotoPromptView: View {
    /// The plants just created, in basket order.
    let plants: [PhotoCaptureCoordinator.Target]
    let onTakePhotos: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Sheet header area
            VStack(spacing: 22) {
                // 104Ø gradient circle with cream camera
                ZStack {
                    Circle()
                        .fill(SproutTheme.logoGradient)
                        .frame(width: 104, height: 104)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(SproutTheme.cream)
                }

                // Title: display(27) "Three plants added 🌱" etc.
                Text(PhotoPromptText.title(count: plants.count))
                    .font(SproutFont.display(27))
                    .foregroundStyle(SproutTheme.ink)
                    .multilineTextAlignment(.center)

                // Body: "Add a photo of each..."
                Text(PhotoPromptText.subtitle(count: plants.count))
                    .font(SproutFont.body(16))
                    .foregroundStyle(SproutTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 24)

            Spacer()

            // Buttons area
            VStack(spacing: 12) {
                Button(action: onTakePhotos) {
                    Text("Take Photos")
                }
                .buttonStyle(SproutPrimaryButtonStyle())

                Button("Skip photos", action: onSkip)
                    .font(SproutFont.body(17, weight: .semibold))
                    .foregroundStyle(SproutTheme.brandGreen)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(SproutTheme.paper)
        }
        .background(SproutTheme.paper)
    }
}

/// Pure copy for the post-add photo prompt, factored out so the wording is
/// unit-testable without instantiating the SwiftUI view.
enum PhotoPromptText {
    private static let numberWords = ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]

    static func title(count: Int) -> String {
        let countWord = count >= 0 && count <= 9 ? numberWords[count] : String(count)
        let plantWord = count == 1 ? "plant" : "plants"
        return "\(countWord) \(plantWord) added 🌱"
    }

    static func subtitle(count: Int) -> String {
        "Add a photo of each so they're easy to spot. You can always do this later."
    }

    static func listHeader(count: Int) -> String {
        count <= 1 ? "New plant" : "New plants (\(count))"
    }
}
