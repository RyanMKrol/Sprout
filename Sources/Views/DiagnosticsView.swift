import SwiftUI
import UIKit

/// **Developer → Camera diagnostics** (Settings). Shows the on-disk diagnostic log
/// (written by `DiagnosticLog`/`dlog`) so the user can reproduce a crash, reopen the
/// app, and **Copy/Share** an app-specific log — no Console.app needed. Newest lines
/// are at the bottom; pull the latest with the nav-bar refresh icon. Restyled to the
/// dark-terminal-on-paper language (redesign screen 25): a `#232821` monospaced
/// terminal card with substring-colorized lines, under a frosted bottom toolbar.
struct DiagnosticsView: View {
    @State private var text: String = ""

    /// `#7C8570` — leading `HH:mm:ss.SSS` timestamp on each log line.
    private static let timestampColor = Color(red: 0x7C / 255, green: 0x85 / 255, blue: 0x70 / 255)
    /// `#8FE0A8` — lines that read as a success ("✓" / "ok").
    private static let successColor = Color(red: 0x8F / 255, green: 0xE0 / 255, blue: 0xA8 / 255)
    /// `#E7B36A` — lines that read as a retry/warning.
    private static let warningColor = Color(red: 0xE7 / 255, green: 0xB3 / 255, blue: 0x6A / 255)
    /// `#C7D0BE` — default terminal text color.
    private static let baseColor = Color(red: 0xC7 / 255, green: 0xD0 / 255, blue: 0xBE / 255)
    private static let terminalFontSize: CGFloat = 11.5
    private static let terminalFont = Font.system(size: terminalFontSize, design: .monospaced)
    /// Extra inter-line spacing so `terminalFont` reads as line-height 1.75.
    private static let terminalLineSpacing = terminalFontSize * 0.75

    var body: some View {
        ZStack(alignment: .bottom) {
            SproutTheme.paper.ignoresSafeArea()

            if text.isEmpty {
                ContentUnavailableView {
                    Label("No diagnostics yet", systemImage: "doc.text.magnifyingglass")
                } description: {
                    Text("Reproduce the issue (e.g. take a photo), then come back here. The log survives even a crash.")
                }
            } else {
                ScrollView {
                    terminalCard
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 90)
                }

                bottomToolbar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Diagnostics")
                    .font(SproutFont.display(16))
                    .foregroundStyle(SproutTheme.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { reload() } label: {
                    ChromeIcon.arrowsRotate.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(SproutTheme.ink)
                }
                .accessibilityLabel("Refresh")
            }
        }
        .onAppear(perform: reload)
    }

    // MARK: - Terminal card

    private var terminalCard: some View {
        terminalText
            .lineSpacing(Self.terminalLineSpacing)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SproutTheme.ink)
            )
    }

    /// The whole log rendered as one `Text`, colorized line by line so `lineSpacing`
    /// (line-height 1.75) applies uniformly across the block.
    private var terminalText: Text {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.enumerated().reduce(Text("")) { partial, entry in
            let (index, line) = entry
            let colored = Self.colorize(String(line))
            return index == 0 ? colored : partial + Text("\n") + colored
        }
    }

    /// Colors one log line: the leading `HH:mm:ss.SSS` timestamp (if present) in
    /// `timestampColor`, and the rest by simple substring rules — success
    /// ("✓"/"ok"), warning ("retry"/"warn"), else the base terminal color.
    private static func colorize(_ line: String) -> Text {
        let lower = line.lowercased()
        let messageColor: Color
        if lower.contains("✓") || lower.contains("ok") {
            messageColor = successColor
        } else if lower.contains("retry") || lower.contains("warn") {
            messageColor = warningColor
        } else {
            messageColor = baseColor
        }

        guard let range = line.range(of: #"^\d{2}:\d{2}:\d{2}\.\d{3}"#, options: .regularExpression) else {
            return Text(line).font(terminalFont).foregroundColor(messageColor)
        }
        let timestamp = String(line[range])
        let rest = String(line[range.upperBound...])
        return Text(timestamp).font(terminalFont).foregroundColor(timestampColor)
            + Text(rest).font(terminalFont).foregroundColor(messageColor)
    }

    // MARK: - Bottom toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            ShareLink(item: text) {
                toolbarLabel(icon: .arrowUpFromBracket, text: "Share", tint: SproutTheme.ink)
            }
            .frame(maxWidth: .infinity)

            Button {
                UIPasteboard.general.string = text
            } label: {
                toolbarLabel(icon: .copy, text: "Copy", tint: SproutTheme.brandGreen)
            }
            .frame(maxWidth: .infinity)

            Button(role: .destructive) {
                DiagnosticLog.shared.clear()
                text = ""
            } label: {
                toolbarLabel(icon: .trash, text: "Clear", tint: SproutTheme.destructive)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(alignment: .top) {
            Rectangle()
                .fill(Color(red: 60.0 / 255, green: 66.0 / 255, blue: 58.0 / 255, opacity: 0.08))
                .frame(height: 1)
        }
        .background(Color(red: 244.0 / 255, green: 241.0 / 255, blue: 231.0 / 255, opacity: 0.92))
        .background(.ultraThinMaterial)
    }

    private func toolbarLabel(icon: ChromeIcon, text: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
            Text(text)
                .font(SproutFont.body(11))
        }
        .foregroundStyle(tint)
    }

    private func reload() {
        text = DiagnosticLog.shared.contents()
    }
}

#Preview {
    NavigationStack {
        DiagnosticsView()
    }
}
