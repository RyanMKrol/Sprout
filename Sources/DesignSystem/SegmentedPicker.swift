import SwiftUI

struct SproutSegmentedPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button(
                action: { withAnimation(.spring(duration: 0.25)) { selection = option.value } },
                label: {
                    Text(option.label)
                        .font(SproutFont.body(14.5, weight: .semibold))
                        .foregroundStyle(
                            selection == option.value ? Color.white : SproutTheme.textMuted
                        )
                }
            )
                .frame(maxWidth: .infinity)
                .padding(4)
                .background(
                    selection == option.value
                        ? AnyView(
                            RoundedRectangle(cornerRadius: SproutTheme.Radius.pill)
                                .fill(SproutTheme.brandGreen)
                                .shadow(
                                    color: Color(
                                        red: 47.0 / 255,
                                        green: 107.0 / 255,
                                        blue: 76.0 / 255,
                                        opacity: 0.3
                                    ),
                                    radius: 8,
                                    x: 0,
                                    y: 3
                                )
                        )
                        : AnyView(Color.clear)
                )
                .accessibilityIdentifier("segment.\(option.label)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(SproutTheme.segmentedTrack)
        .cornerRadius(SproutTheme.Radius.segmented)
    }
}

struct SegmentedPickerPreview: View {
    @State private var selection = "Dry"
    let options: [(value: String, label: String)] = [
        (value: "Dry", label: "Dry"),
        (value: "Moist", label: "Moist"),
        (value: "Wet", label: "Wet")
    ]

    var body: some View {
        VStack(spacing: 40) {
            SproutSegmentedPicker(selection: $selection, options: options)
                .padding(20)
                .background(SproutTheme.paper)

            Text("Selected: \(selection)")
                .font(SproutFont.body(14))
                .foregroundStyle(SproutTheme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SproutTheme.paper)
    }
}

#Preview {
    SegmentedPickerPreview()
}
