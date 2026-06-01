import UIKit

/// Drives the **sequential photo flow** (T206) — walks an ordered list of just-added
/// plants one at a time, photographing each. The view (T207) shows the camera with an
/// overlay naming the current plant; the user taps the shutter (`captureCurrent`),
/// which saves the photo to that plant and auto-advances, or taps Skip. No back
/// navigation — you shoot and move on.
///
/// All logic lives here behind the `PhotoCapturing` seam, so it's fully unit-tested
/// with `StubPhotoCapturing` + an in-memory repository — no camera hardware needed.
@MainActor
final class PhotoCaptureCoordinator: ObservableObject {
    /// One plant to photograph, with the labels the overlay banner shows.
    struct Target: Identifiable, Equatable {
        let id: UUID
        let nickname: String
        let species: String

        init(id: UUID, nickname: String, species: String) {
            self.id = id
            self.nickname = nickname
            self.species = species
        }

        /// Build a target from a created plant (the basket commit's output order).
        init(plant: Plant) {
            self.init(id: plant.id, nickname: plant.nickname, species: plant.species)
        }
    }

    let targets: [Target]
    /// Index of the plant currently being photographed; equals `targets.count` once done.
    @Published private(set) var index: Int = 0
    /// `true` once every target has been captured or skipped.
    @Published private(set) var isFinished: Bool = false

    private let repository: PlantRepository
    /// The capture source. Exposed so the view can ask it for a live preview when it
    /// provides one (`CameraPreviewProviding`); the stub doesn't, so the view falls
    /// back to a placeholder.
    let camera: PhotoCapturing

    init(targets: [Target], repository: PlantRepository, camera: PhotoCapturing) {
        self.targets = targets
        self.repository = repository
        self.camera = camera
        if targets.isEmpty { isFinished = true }
    }

    // MARK: - Presentation

    /// The plant currently being photographed, or `nil` when finished.
    var current: Target? { index < targets.count ? targets[index] : nil }

    /// Whether a real camera is available (false on the simulator → placeholder UI).
    var cameraAvailable: Bool { camera.isAvailable }

    /// Overlay banner naming the current plant.
    var bannerText: String {
        guard let current else { return "" }
        return "Now photographing \(current.nickname) — \(current.species)"
    }

    /// Progress label, e.g. "2 of 5".
    var progressText: String {
        guard !targets.isEmpty else { return "" }
        return "\(min(index + 1, targets.count)) of \(targets.count)"
    }

    // MARK: - Actions

    /// Capture the current plant: take a frame, square + compress it, save it to the
    /// plant, then advance. A failed/empty capture leaves the photo unset and **stays**
    /// on the current plant so the user can retry (distinct from `skip`).
    func captureCurrent() async {
        guard let target = current else { return }
        guard let image = await camera.capture(), let data = PlantPhoto.encode(image) else {
            return // capture failed — stay put for a retry
        }
        if var plant = (try? repository.plant(id: target.id)) ?? nil {
            plant.photoData = data
            try? repository.update(plant)
        }
        advance()
    }

    /// Move on without photographing the current plant.
    func skip() { advance() }

    private func advance() {
        guard !targets.isEmpty else { isFinished = true; return }
        if index + 1 >= targets.count {
            index = targets.count
            isFinished = true
        } else {
            index += 1
        }
    }
}
