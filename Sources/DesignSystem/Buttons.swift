import SwiftUI

// MARK: - SproutPrimaryButtonStyle

struct SproutPrimaryButtonStyle: ButtonStyle {
    @State private var isPressed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SproutFont.body(17, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(SproutTheme.brandGreen)
            .cornerRadius(SproutTheme.Radius.button)
            .primaryButtonShadow()
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - SproutGhostButtonStyle

struct SproutGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SproutFont.body(15, weight: .semibold))
            .foregroundStyle(SproutTheme.brandGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.clear)
            .border(
                Color(red: 47.0 / 255, green: 107.0 / 255, blue: 76.0 / 255, opacity: 0.32),
                width: 1.5
            )
            .cornerRadius(18)
    }
}

// MARK: - SproutCreamButtonStyle

struct SproutCreamButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SproutFont.body(16, weight: .semibold))
            .foregroundStyle(SproutTheme.deepGreenOnCream)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(SproutTheme.paper)
            .cornerRadius(15)
    }
}

// MARK: - SectionEyebrow

struct SectionEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(SproutFont.body(11, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(SproutTheme.taupe)
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionEyebrow(text: "Example Section")

        Button(action: {}) {
            Label("Primary Button", systemImage: "plus")
        }
        .buttonStyle(SproutPrimaryButtonStyle())

        Button(action: {}) {
            Label("Ghost Button", systemImage: "pencil")
        }
        .buttonStyle(SproutGhostButtonStyle())

        Button(action: {}) {
            Label("Cream Button", systemImage: "checkmark")
        }
        .buttonStyle(SproutCreamButtonStyle())

        Spacer()
    }
    .padding(20)
    .background(SproutTheme.paper)
}
