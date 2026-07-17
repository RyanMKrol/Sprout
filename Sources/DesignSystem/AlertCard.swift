import SwiftUI

struct SproutAlert: View {
    let icon: ChromeIcon
    let tint: Color
    let title: String
    let message: String
    let confirmLabel: String
    let confirmRole: ButtonRole?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    init(
        icon: ChromeIcon,
        tint: Color,
        title: String,
        message: String,
        confirmLabel: String,
        confirmRole: ButtonRole? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.message = message
        self.confirmLabel = confirmLabel
        self.confirmRole = confirmRole
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.13))
                            .frame(width: 52, height: 52)

                        icon.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(tint)
                    }

                    Text(title)
                        .font(SproutFont.display(19))
                        .foregroundStyle(SproutTheme.ink)

                    Text(message)
                        .font(SproutFont.body(13.5))
                        .foregroundStyle(SproutTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(24)

                Divider()
                    .background(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.08))

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(SproutFont.body(15, weight: .semibold))
                            .foregroundStyle(SproutTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .background(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.08))
                    .cornerRadius(13)

                    Button(action: onConfirm) {
                        Text(confirmLabel)
                            .font(SproutFont.body(15, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .background(tint)
                    .cornerRadius(13)
                }
                .padding(16)
            }
            .frame(maxWidth: 286)
            .background(Color(red: 244.0 / 255, green: 241.0 / 255, blue: 231.0 / 255, opacity: 0.92))
            .background(.ultraThinMaterial)
            .cornerRadius(SproutTheme.Radius.dialog)
            .dialogShadow()
        }
    }
}

extension View {
    func sproutAlert(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> SproutAlert
    ) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                content()
                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity),
                                          removal: .opacity))
            }
        }
    }
}

#Preview {
    ZStack {
        VStack {
            Text("Background Content")
                .font(SproutFont.body(16))
                .foregroundStyle(SproutTheme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SproutTheme.paper)

        SproutAlert(
            icon: .trash,
            tint: SproutTheme.destructive,
            title: "Delete Basil?",
            message: "This removes the plant and its check-in history. This can't be undone.",
            confirmLabel: "Delete",
            confirmRole: .destructive,
            onConfirm: {},
            onCancel: {}
        )
    }
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
