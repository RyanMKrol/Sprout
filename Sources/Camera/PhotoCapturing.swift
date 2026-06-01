import UIKit

/// The seam between the sequential photo flow (T206/T207) and the camera hardware.
/// Everything downstream depends on this protocol, never on AVFoundation directly,
/// so the flow stays unit-testable and screenshottable on the simulator (where the
/// real camera can't run) via `StubPhotoCapturing`.
@MainActor
protocol PhotoCapturing: AnyObject {
    /// Whether a real capture device is available and authorised. `false` on the
    /// simulator and when camera permission is denied — the UI shows a placeholder.
    var isAvailable: Bool { get }

    /// Capture a single frame, or `nil` if capture failed / was unavailable. The
    /// caller squares + compresses it via `PlantPhoto.encode`.
    func capture() async -> UIImage?
}
