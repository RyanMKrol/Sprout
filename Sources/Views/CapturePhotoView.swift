import SwiftUI
import UIKit

/// A single-shot camera screen with a **live preview** and a shutter the user taps —
/// so capturing a photo is intentional and framed (unlike the old blind snap). Starts
/// the session on appear and **stops it on disappear**, so the camera never stays
/// active after the screen closes (no lingering privacy indicator).
///
/// It does not persist anything — it hands the captured `UIImage` back to the caller
/// (e.g. the edit form stages it). On the simulator (no camera) it shows a placeholder
/// and the shutter returns the stub image.
struct CapturePhotoView: View {
    let camera: PhotoCapturing
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var isCapturing = false

    private var previewProvider: CameraPreviewProviding? { camera as? CameraPreviewProviding }

    var body: some View {
        ZStack {
            Color(hex: 0x10160E).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Take a photo")
                    .font(SproutFont.display(22))
                    .foregroundStyle(.white)
                preview
                controls
            }
            .padding()
        }
        .task { await previewProvider?.start() }
        .onDisappear { previewProvider?.stop() }
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            if let previewProvider, camera.isAvailable {
                previewProvider.makePreview()
            } else {
                placeholder
            }
            if isCapturing {
                Color.black.opacity(0.35)
                ProgressView().tint(.white)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.3), lineWidth: 1))
    }

    /// Shown when no live camera is available (simulator / denied permission).
    private var placeholder: some View {
        ZStack {
            Color.white.opacity(0.06)
            VStack(spacing: 12) {
                ChromeIcon.camera.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.white.opacity(0.5))
                Text("Camera preview unavailable here")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 0) {
            Button("Cancel") { onCancel() }
                .font(SproutFont.body(17))
                .foregroundStyle(.white)
                .frame(width: 80, alignment: .leading)

            Spacer()

            Button(action: capture) {
                ZStack {
                    Circle().fill(.white).frame(width: 70, height: 70)
                    Circle().stroke(.white, lineWidth: 4).frame(width: 84, height: 84)
                }
            }
            .disabled(isCapturing)
            .accessibilityLabel("Take photo")

            Spacer()

            // Balances Cancel so the shutter stays centred.
            Color.clear.frame(width: 80, height: 1)
        }
        .padding(.horizontal)
    }

    private func capture() {
        guard !isCapturing else { return }
        isCapturing = true
        Task {
            let image = await camera.capture()
            isCapturing = false
            if let image { onCapture(image) }
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
