@preconcurrency import AVFoundation
import SwiftUI
import UIKit

/// A camera that can supply a live SwiftUI preview. Kept free of AVFoundation types
/// in its signature (returns `AnyView`) so `PhotoCaptureView` / `CapturePhotoView` can
/// use it without importing AVFoundation — only this file does.
@MainActor
protocol CameraPreviewProviding {
    /// A live preview view for the capture session.
    func makePreview() -> AnyView
    /// Begin the session (requesting authorization if needed).
    func start() async
    /// Stop the session.
    func stop()
}

/// The real camera capture (T207) — the **only** file that imports AVFoundation.
///
/// **All `AVCaptureSession` configuration + start/stop runs on a dedicated background
/// queue, never the main thread** (the Apple-recommended pattern). Doing session setup
/// on the main thread blocks it long enough that the device watchdog can kill the app —
/// which is what crashed the guided photo flow on device. Only the captured `UIImage`
/// hand-off touches the main actor.
///
/// Not unit-tested (needs hardware / can't run on the simulator); its testable
/// substitute is `StubPhotoCapturing`. Returns `nil` on any failure rather than crashing.
@MainActor
final class AVFoundationCamera: NSObject, PhotoCapturing {
    nonisolated let session = AVCaptureSession()
    private nonisolated let output = AVCapturePhotoOutput()
    private nonisolated let sessionQueue = DispatchQueue(label: "com.ryankrol.sprout.camera")
    /// Only read/written on `sessionQueue`.
    private nonisolated(unsafe) var isConfigured = false
    /// Main-actor only; resumed when the photo (or a failure) comes back.
    private var continuation: CheckedContinuation<UIImage?, Never>?

    var isAvailable: Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            return false
        default:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
        }
    }

    /// Capture one square frame, or `nil` on failure. Authorises, configures + starts the
    /// session **on the background queue**, confirms an active connection, then snaps.
    func capture() async -> UIImage? {
        dlog("capture() requested")
        guard await prepare() else {
            dlog("capture() aborted — camera not ready")
            return nil
        }
        // Let the sensor expose a frame before snapping (no warmed-up preview in the edit flow).
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard continuation == nil else {
            dlog("capture() ignored — a capture is already in flight")
            return nil
        }
        return await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
            continuation = cont
            sessionQueue.async { [output] in
                guard let connection = output.connection(with: .video),
                      connection.isActive, connection.isEnabled else {
                    dlog("capture() aborted — no active video connection")
                    Task { @MainActor in self.finish(nil) }
                    return
                }
                dlog("capturing photo")
                output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
        }
    }

    /// Authorise (main, fast) → configure + start the session on the background queue.
    /// Resolves once the session is genuinely running. Never blocks the main thread.
    private func prepare() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            dlog("requesting camera authorization")
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                dlog("camera authorization denied by user")
                return false
            }
        default:
            dlog("camera unavailable — authorization denied/restricted")
            return false
        }
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            sessionQueue.async { [self] in
                configureIfNeededOnQueue()
                if isConfigured, !session.isRunning { session.startRunning() }
                let running = isConfigured && session.isRunning
                if !running { dlog("capture session failed to start") }
                cont.resume(returning: running)
            }
        }
    }

    /// Builds the session graph. **Must only be called on `sessionQueue`.**
    private nonisolated func configureIfNeededOnQueue() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        } else {
            dlog("no back-camera input available")
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        isConfigured = !session.inputs.isEmpty && !session.outputs.isEmpty
    }

    /// Resume the pending capture on the main actor (image or nil).
    private func finish(_ image: UIImage?) {
        continuation?.resume(returning: image)
        continuation = nil
    }
}

extension AVFoundationCamera: CameraPreviewProviding {
    func makePreview() -> AnyView {
        AnyView(CameraPreviewView(session: session))
    }

    func start() async {
        _ = await prepare()
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }
}

extension AVFoundationCamera: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            dlog("photo capture failed: \(error.localizedDescription)")
        }
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        dlog("photo processed — image: \(image != nil)")
        Task { @MainActor in self.finish(image) }
    }
}

/// A `UIViewRepresentable` wrapping an `AVCaptureVideoPreviewLayer` for the live feed.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    /// A `UIView` whose backing layer is the capture preview layer.
    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // Safe: `layerClass` guarantees the backing layer's type.
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
