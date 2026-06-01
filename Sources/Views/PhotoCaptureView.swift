import SwiftUI

/// The **sequential photo capture** screen (T207). Shows a square camera preview (or
/// a placeholder when the camera is unavailable — e.g. the simulator), an overlay
/// banner naming the current plant, a shutter that captures + auto-advances, and a
/// Skip button. Driven entirely by `PhotoCaptureCoordinator`; no back navigation.
struct PhotoCaptureView: View {
    @StateObject private var coordinator: PhotoCaptureCoordinator
    /// Called once every plant has been photographed or skipped (or immediately if
    /// there were none), so the presenter can dismiss and refresh.
    private let onFinish: () -> Void

    init(coordinator: PhotoCaptureCoordinator, onFinish: @escaping () -> Void = {}) {
        _coordinator = StateObject(wrappedValue: coordinator)
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                banner
                preview
                controls
            }
            .padding()
        }
        .task { await previewProvider?.start() }
        .onAppear { if coordinator.isFinished { onFinish() } }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished {
                previewProvider?.stop()
                onFinish()
            }
        }
    }

    private var previewProvider: CameraPreviewProviding? {
        coordinator.camera as? CameraPreviewProviding
    }

    // MARK: - Sections

    private var banner: some View {
        VStack(spacing: 4) {
            Text(coordinator.current?.nickname ?? "")
                .font(.title2.bold())
            Text(coordinator.current?.species ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(coordinator.progressText)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(coordinator.bannerText)
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            if let previewProvider, coordinator.cameraAvailable {
                previewProvider.makePreview()
            } else {
                placeholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
    }

    /// Shown when no live camera is available (simulator / denied permission).
    private var placeholder: some View {
        ZStack {
            Color.white.opacity(0.06)
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.5))
                Text("Camera preview unavailable here")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var controls: some View {
        HStack {
            Button("Skip") { coordinator.skip() }
                .foregroundStyle(.white)
                .frame(width: 80, alignment: .leading)

            Spacer()

            Button {
                Task { await coordinator.captureCurrent() }
            } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 72, height: 72)
                    Circle().stroke(.white, lineWidth: 4).frame(width: 84, height: 84)
                }
            }
            .accessibilityLabel("Take photo")

            Spacer()

            // Balances the Skip button so the shutter stays centred.
            Color.clear.frame(width: 80, height: 1)
        }
        .padding(.horizontal)
    }
}
