import SwiftUI
import UIKit

/// **Developer → Camera diagnostics** (Settings). Shows the on-disk diagnostic log
/// (written by `DiagnosticLog`/`dlog`) so the user can reproduce a crash, reopen the
/// app, and **Copy/Share** an app-specific log — no Console.app needed. Newest lines
/// are at the bottom; pull the latest with Refresh.
struct DiagnosticsView: View {
    @State private var text: String = ""

    var body: some View {
        Group {
            if text.isEmpty {
                ContentUnavailableView {
                    Label("No diagnostics yet", systemImage: "doc.text.magnifyingglass")
                } description: {
                    Text("Reproduce the issue (e.g. take a photo), then come back here. The log is captured even if the app crashes.")
                }
            } else {
                ScrollView {
                    Text(text)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .navigationTitle("Camera diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { reload() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if !text.isEmpty {
                    ShareLink(item: text) { Label("Share", systemImage: "square.and.arrow.up") }
                    Button { UIPasteboard.general.string = text } label: { Label("Copy", systemImage: "doc.on.doc") }
                    Spacer()
                    Button("Clear", role: .destructive) {
                        DiagnosticLog.shared.clear()
                        text = ""
                    }
                }
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        text = DiagnosticLog.shared.contents()
    }
}
