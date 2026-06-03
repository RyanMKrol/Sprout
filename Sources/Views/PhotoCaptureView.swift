import SwiftUI
import UIKit

/// The **sequential photo capture** screen (T207). Shows a square camera preview (or
/// a placeholder when the camera is unavailable — e.g. the simulator), an overlay
/// banner naming the current plant, a shutter that captures + auto-advances, and a
/// Skip button. Driven entirely by `PhotoCaptureCoordinator`; no back navigation.
///
/// Capturing a photo plays a clear sequence of feedback so it's obvious a shot landed
/// and the flow has moved on (T207 felt silent — only the text changed): a white
/// **shutter flash**, a **green "Saved — next plant" pulse** with a checkmark, a
/// success **haptic**, and an animated **slide** of the banner to the next plant.
struct PhotoCaptureView: View {
    @StateObject private var coordinator: PhotoCaptureCoordinator
    /// Called once every plant has been photographed or skipped (or immediately if
    /// there were none), so the presenter can dismiss and refresh.
    private let onFinish: () -> Void

    /// Opacity of the white shutter-flash overlay (0 = hidden, ~0.85 = full flash).
    @State private var flashOpacity: Double = 0
    /// Whether the green "saved" confirmation overlay is showing.
    @State private var showSuccess = false
    /// True while a capture's feedback sequence is running — disables the controls so
    /// a double-tap can't fire a second capture mid-animation.
    @State private var isBusy = false
    /// Whole-screen opacity, faded to 0 on the final plant so the flow fades out cleanly
    /// instead of sliding the banner away to an empty "N of N".
    @State private var screenOpacity: Double = 1
    /// The last non-nil plant shown — kept so the banner can stay on the final plant
    /// (rather than blank) once the coordinator finishes and `current` becomes nil.
    @State private var lastTarget: PhotoCaptureCoordinator.Target?

    init(coordinator: PhotoCaptureCoordinator, onFinish: @escaping () -> Void = {}) {
        dlog("PhotoCaptureView.init")
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
            // Animate the banner's identity swap whenever we advance to the next plant,
            // so the move is visible rather than instant.
            .animation(.easeInOut(duration: 0.4), value: displayedTarget?.id)
        }
        .opacity(screenOpacity)
        .task {
            dlog("PhotoCaptureView.task — starting preview (provider=\(previewProvider != nil))")
            await previewProvider?.start()
            dlog("PhotoCaptureView.task — start() returned")
        }
        .onAppear {
            dlog("PhotoCaptureView.onAppear (finished=\(coordinator.isFinished))")
            lastTarget = coordinator.current
            if coordinator.isFinished { onFinish() }
        }
        .onChange(of: coordinator.current?.id) { _, _ in
            if let current = coordinator.current { lastTarget = current }
        }
        .onDisappear { dlog("PhotoCaptureView.onDisappear — stopping session"); previewProvider?.stop() }
    }

    private var previewProvider: CameraPreviewProviding? {
        coordinator.camera as? CameraPreviewProviding
    }

    /// The plant the banner should show: the current one, or — once finished — the last
    /// one seen, so the final plant's banner stays put (and the screen fades) instead of
    /// sliding away to a blank "N of N".
    private var displayedTarget: PhotoCaptureCoordinator.Target? {
        coordinator.current ?? lastTarget
    }

    // MARK: - Sections

    private var banner: some View {
        VStack(spacing: 4) {
            Text(displayedTarget?.nickname ?? "")
                .font(.title2.bold())
            Text(displayedTarget?.species ?? "")
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
        // New identity per plant → the asymmetric transition slides the old banner out
        // to the left and the next plant's banner in from the right ("on to the next").
        // On finish the id is unchanged (held on the last plant), so it stays put while
        // the whole screen fades instead.
        .id(displayedTarget?.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            if let previewProvider, coordinator.cameraAvailable {
                LiveCameraPreview(provider: previewProvider)
            } else {
                placeholder
            }

            // White shutter flash — a quick burst the instant the shutter is tapped.
            Color.white
                .opacity(flashOpacity)
                .allowsHitTesting(false)

            // Green confirmation pulse — appears once the photo is saved. Pops in with a
            // slight scale, fades out gently (pure opacity — a scale-down on removal reads
            // as an abrupt snap).
            if showSuccess {
                successOverlay
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity
                    ))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(showSuccess ? Color.green : Color.white.opacity(0.3),
                        lineWidth: showSuccess ? 4 : 1)
        )
    }

    /// The green "saved" confirmation shown briefly over the preview after a capture.
    private var successOverlay: some View {
        ZStack {
            Color.green.opacity(0.45)
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                Text(coordinator.isFinished ? "All done!" : "Saved — next plant")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .accessibilityHidden(true)
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
            Button("Skip") { skipCurrent() }
                .foregroundStyle(.white)
                .frame(width: 80, alignment: .leading)

            Spacer()

            Button {
                Task { await capture() }
            } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 72, height: 72)
                    Circle().stroke(.white, lineWidth: 4).frame(width: 84, height: 84)
                }
            }
            .scaleEffect(isBusy ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: isBusy)
            .accessibilityLabel("Take photo")

            Spacer()

            // Balances the Skip button so the shutter stays centred.
            Color.clear.frame(width: 80, height: 1)
        }
        .disabled(isBusy)
        .opacity(isBusy ? 0.6 : 1)
        .padding(.horizontal)
    }

    // MARK: - Capture flow

    /// Take a photo with full feedback: shutter flash → capture → (on success) green
    /// confirmation pulse + haptic, the banner having slid to the next plant. A failed
    /// capture flashes but shows no confirmation and stays on the current plant.
    private func capture() async {
        guard !isBusy, coordinator.current != nil else { return }
        dlog("PhotoCaptureView — shutter tapped")
        isBusy = true
        defer { isBusy = false }

        // 1. Shutter flash — immediate, responsive feedback on tap.
        haptic(.shutter)
        withAnimation(.easeOut(duration: 0.07)) { flashOpacity = 0.85 }
        try? await Task.sleep(nanoseconds: 70_000_000)
        withAnimation(.easeIn(duration: 0.3)) { flashOpacity = 0 }

        // 2. Capture + save. captureCurrent advances on success, stays put on failure.
        let before = coordinator.index
        await coordinator.captureCurrent()
        let advanced = coordinator.index != before || coordinator.isFinished
        guard advanced else { return } // capture failed → no confirmation, retry

        // 3. Green confirmation pulse (for a non-final plant the banner has already slid
        //    to the next one; on the last plant the banner stays put — see displayedTarget).
        haptic(.success)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { showSuccess = true }
        try? await Task.sleep(nanoseconds: 650_000_000)

        if coordinator.isFinished {
            // Last plant: keep the "All done!" pulse and banner in place and fade the whole
            // screen out, rather than sliding to a blank next plant.
            withAnimation(.easeInOut(duration: 0.45)) { screenOpacity = 0 }
            try? await Task.sleep(nanoseconds: 480_000_000)
            onFinish()
        } else {
            // Fade the confirmation out gently before the next shot.
            withAnimation(.easeInOut(duration: 0.4)) { showSuccess = false }
        }
    }

    /// Skip the current plant: animate the banner to the next one (no capture feedback),
    /// and on the last plant fade the whole screen out before finishing.
    private func skipCurrent() {
        guard !isBusy else { return }
        haptic(.shutter)
        coordinator.skip()
        guard coordinator.isFinished else { return }
        isBusy = true
        Task {
            withAnimation(.easeInOut(duration: 0.4)) { screenOpacity = 0 }
            try? await Task.sleep(nanoseconds: 420_000_000)
            onFinish()
        }
    }

    // MARK: - Haptics

    private enum Haptic { case shutter, success }

    private func haptic(_ kind: Haptic) {
        switch kind {
        case .shutter:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

/// Wraps the camera's live preview so we can log the moment the preview layer is built
/// (the suspected crash window between the cover presenting and the session starting).
private struct LiveCameraPreview: View {
    let provider: CameraPreviewProviding

    var body: some View {
        dlog("PhotoCaptureView — building live preview (makePreview)")
        return provider.makePreview()
            .onAppear { dlog("PhotoCaptureView — live preview appeared") }
    }
}
