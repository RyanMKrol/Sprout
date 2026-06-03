import Foundation
import OSLog

/// A tiny **on-disk** diagnostic log that survives a crash, so a flow that crashes
/// (e.g. the camera) leaves a readable trail. Each line is appended to a file in
/// Caches and flushed immediately; the in-app **Developer → Camera diagnostics** screen
/// reads it back so the user can copy/share an app-specific log without trawling
/// Console.app. Also mirrors to `os.Logger` (subsystem `com.ryankrol.sprout`) and, in
/// DEBUG, to the Xcode console.
final class DiagnosticLog: @unchecked Sendable {
    static let shared = DiagnosticLog()

    private let queue = DispatchQueue(label: "com.ryankrol.sprout.diaglog")
    private let logger = Logger(subsystem: "com.ryankrol.sprout", category: "diag")
    private let fileURL: URL?
    private let maxBytes = 200_000

    private init() {
        fileURL = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("sprout-diagnostics.log")
    }

    /// Append one timestamped line. Safe to call from any thread/queue.
    func log(_ message: String) {
        logger.log("\(message, privacy: .public)")
        let line = Self.timestamp() + "  " + message
        #if DEBUG
        print("🌱 " + line)
        #endif
        queue.async { [fileURL, maxBytes] in
            guard let fileURL else { return }
            let data = Data((line + "\n").utf8)
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.synchronize() // flush so a crash keeps the last lines
            } else {
                try? data.write(to: fileURL)
            }
            // Keep the file bounded across sessions.
            if let size = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int,
               size > maxBytes,
               let text = try? String(contentsOf: fileURL, encoding: .utf8) {
                let trimmed = text.suffix(maxBytes / 2)
                try? Data(trimmed.utf8).write(to: fileURL)
            }
        }
    }

    /// The current log contents (empty if none yet).
    func contents() -> String {
        queue.sync {
            guard let fileURL, let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return "" }
            return text
        }
    }

    /// Erase the log.
    func clear() {
        queue.async { [fileURL] in
            guard let fileURL else { return }
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private static func timestamp() -> String {
        let now = Date()
        let c = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
        let ms = (c.nanosecond ?? 0) / 1_000_000
        return String(format: "%02d:%02d:%02d.%03d", c.hour ?? 0, c.minute ?? 0, c.second ?? 0, ms)
    }
}

/// Shorthand used across the camera flow to record a diagnostic step.
func dlog(_ message: String) {
    DiagnosticLog.shared.log(message)
}
