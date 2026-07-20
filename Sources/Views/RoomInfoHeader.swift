import SwiftUI

/// A section header with a title and a small info (ⓘ) button that presents a popover
/// explaining a room field (the light-input tooltips, T220). Shared by the room editor
/// and the add-room flow's custom controls.
struct RoomInfoHeader: View {
    let title: String
    let help: String
    @State private var showing = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(SproutFont.body(15, weight: .semibold))
                .foregroundStyle(SproutTheme.ink)
            Button { showing = true } label: {
                ChromeIcon.circleInfo.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("\(title) — what's this?")
            .popover(isPresented: $showing) {
                Text(help)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
                    // Let the text wrap to as many lines as it needs; without this the
                    // popover sizes to one line and truncates the help (T220 bug).
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .frame(width: 280)
                    .presentationCompactAdaptation(.popover)
            }
            Spacer()
        }
    }
}
