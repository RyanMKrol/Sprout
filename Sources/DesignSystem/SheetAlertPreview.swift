import SwiftUI

struct SheetAlertPreviewContainer: View {
    @State private var showSheet = true
    @State private var showAlert = true

    var body: some View {
        ZStack {
            VStack {
                Text("Content behind sheet and alert")
                    .font(SproutFont.body(16))
                    .foregroundStyle(SproutTheme.ink)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SproutTheme.paper)
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 0) {
                    SproutSheetHeader(
                        title: "Add Plant",
                        confirmLabel: "Save",
                        confirmEnabled: true,
                        onCancel: { showSheet = false },
                        onConfirm: { showSheet = false }
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

            if showAlert {
                SproutAlert(
                    icon: .trash,
                    tint: SproutTheme.destructive,
                    title: "Delete Basil?",
                    message: "This removes the plant and its check-in history. This can't be undone.",
                    confirmLabel: "Delete",
                    confirmRole: .destructive,
                    onConfirm: { showAlert = false },
                    onCancel: { showAlert = false }
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity),
                                       removal: .opacity))
            }
        }
    }
}

#Preview("SheetScaffold + SproutAlert") {
    SheetAlertPreviewContainer()
}
