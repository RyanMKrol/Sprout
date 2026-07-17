import SwiftUI

struct SproutSheetHeader: View {
    let cancelLabel: String?
    let title: String
    let confirmLabel: String?
    let confirmEnabled: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    init(
        cancelLabel: String? = "Cancel",
        title: String,
        confirmLabel: String?,
        confirmEnabled: Bool = true,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        self.cancelLabel = cancelLabel
        self.title = title
        self.confirmLabel = confirmLabel
        self.confirmEnabled = confirmEnabled
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Capsule()
                    .fill(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
            }

            HStack(spacing: 16) {
                if let cancelLabel {
                    Button(action: onCancel) {
                        Text(cancelLabel)
                            .font(SproutFont.body(17))
                            .foregroundStyle(SproutTheme.brandGreen)
                    }
                }

                Spacer()

                Text(title)
                    .font(SproutFont.display(18))
                    .foregroundStyle(SproutTheme.ink)

                Spacer()

                if let confirmLabel {
                    Button(action: onConfirm) {
                        Text(confirmLabel)
                            .font(SproutFont.body(17, weight: .semibold))
                            .foregroundStyle(SproutTheme.brandGreen)
                    }
                    .opacity(confirmEnabled ? 1.0 : 0.4)
                    .disabled(!confirmEnabled)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(SproutTheme.paper)
    }
}

extension View {
    func sproutSheetBackground() -> some View {
        self
            .presentationCornerRadius(SproutTheme.Radius.sheet)
            .presentationDragIndicator(.hidden)
            .background(SproutTheme.paper)
    }
}

#Preview {
    VStack {
        Text("Sheet Preview")
            .font(SproutFont.display(20))
            .foregroundStyle(SproutTheme.ink)
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SproutTheme.paper)
    .sheet(isPresented: .constant(true)) {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Add Plant",
                confirmLabel: "Save",
                confirmEnabled: true,
                onCancel: {},
                onConfirm: {}
            )

            ScrollView {
                VStack(spacing: 16) {
                    Text("Sheet content would go here")
                        .font(SproutFont.body(14))
                        .foregroundStyle(SproutTheme.textMuted)
                }
                .padding(20)
            }

            Spacer()
        }
        .background(SproutTheme.paper)
        .presentationCornerRadius(SproutTheme.Radius.sheet)
        .presentationDragIndicator(.hidden)
    }
}
