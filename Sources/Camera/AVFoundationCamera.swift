@preconcurrency import AVFoundation
import OSLog
import SwiftUI
import UIKit

/// Camera diagnostics. View on a device in Console.app (or `log stream`) filtering
/// subsystem `com.ryankrol.sprout`, category `camera`.
let cameraLog = Logger(subsystem: "com.ryankrol.sprout", category: "camera")

/// A camera that can supply a live SwiftUI preview. Kept free of AVFoundation types
/// in its signature (returns `AnyView`) so `PhotoCaptureView` can use it without
/// importing AVFoundation — only this file does.
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
/// Implements the `PhotoCapturing` seam with an `AVCaptureSession` + photo output.
/// Not unit-tested (it needs hardware and can't run on the simulator); its testable
/// substitute is `StubPhotoCapturing`. The real capture path is verified by hand on a
/// device (🔒).
@MainActor
final class AVFoundationCamera: NSObject, PhotoCapturing {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.ryankrol.sprout.camera")
    private var isConfigured = false
    private var continuation: CheckedContinuation<UIImage?, Never>?

    var isAvailable: Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            return false
        default:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
        }
    }

    /// One square frame, or `nil` on failure. Ensures the camera is authorised,
    /// configured, and **actually running with an active video connection** before
    /// snapping — calling `capturePhoto` on a stopped session throws an uncatchable
    /// Obj-C exception ("no active and enabled video connection"), which was the
    /// device crash. Returns `nil` (never crashes) on any failure.
    func capture() async -> UIImage? {
        cameraLog.info("capture() requested")
        guard await prepare() else {
            cameraLog.error("capture() aborted — camera not ready")
            return nil
        }
        // Let the sensor expose a frame before snapping (avoids a black first frame
        // when capturing without a warmed-up live preview, e.g. the edit flow).
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard let connection = output.connection(with: .video), connection.isActive, connection.isEnabled else {
            cameraLog.error("capture() aborted — no active video connection")
            return nil
        }
        guard continuation == nil else {
            cameraLog.error("capture() ignored — a capture is already in flight")
            return nil
        }
        cameraLog.info("capturing photo")
        return await withCheckedContinuation { cont in
            continuation = cont
            output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    /// Authorise → configure → start, resolving once the session is genuinely running.
    /// Idempotent and crash-free; returns `false` if the camera can't be used.
    private func prepare() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            cameraLog.info("requesting camera authorization")
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                cameraLog.error("camera authorization denied by user")
                return false
            }
        default:
            cameraLog.error("camera unavailable — authorization denied/restricted")
            return false
        }
        configureIfNeeded()
        guard isConfigured, !output.connections.isEmpty else {
            cameraLog.error("camera could not be configured (no back-camera input/output)")
            return false
        }
        let running = await startRunning()
        if !running { cameraLog.error("capture session failed to start") }
        return running
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        } else {
            cameraLog.error("no back-camera input available")
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        // Only "configured" if we actually have an input + output to capture from.
        isConfigured = !session.inputs.isEmpty && !session.outputs.isEmpty
    }

    /// Start the session on its dedicated queue and resolve once it's running.
    private func startRunning() async -> Bool {
        await withCheckedContinuation { cont in
            sessionQueue.async { [session] in
                if !session.isRunning { session.startRunning() }
                cont.resume(returning: session.isRunning)
            }
        }
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
        let session = session
        sessionQueue.async {
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
            cameraLog.error("photo capture failed: \(error.localizedDescription)")
        }
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        cameraLog.info("photo processed — image: \(image != nil)")
        Task { @MainActor in
            self.continuation?.resume(returning: image)
            self.continuation = nil
        }
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
