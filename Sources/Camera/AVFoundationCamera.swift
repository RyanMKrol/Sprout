@preconcurrency import AVFoundation
import SwiftUI
import UIKit

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

    /// One square frame, or `nil` on failure. Bridges the photo-output delegate
    /// callback to async via a continuation.
    func capture() async -> UIImage? {
        configureIfNeeded()
        guard !output.connections.isEmpty else { return nil }
        return await withCheckedContinuation { cont in
            continuation = cont
            output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        isConfigured = true
    }
}

extension AVFoundationCamera: CameraPreviewProviding {
    func makePreview() -> AnyView {
        AnyView(CameraPreviewView(session: session))
    }

    func start() async {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        configureIfNeeded()
        let session = session
        sessionQueue.async {
            if !session.isRunning { session.startRunning() }
        }
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
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
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
