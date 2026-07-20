import SwiftUI

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
            Color(hex: 0x10160E).ignoresSafeArea()
            VStack(spacing: 0) {
                banner
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                Spacer()
                preview
                    .padding(.horizontal, 22)
                Spacer()
                controls
                    .padding(.bottom, 32)
            }
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
                .font(SproutFont.display(22))
                .foregroundStyle(.white)
            HStack(spacing: 4) {
                Text(displayedTarget?.species.capitalisedWords ?? "")
                    .font(SproutFont.bodyItalic(14))
                Text("·")
                    .font(SproutFont.body(14))
                Text(coordinator.progressText)
                    .font(SproutFont.body(14))
            }
            .foregroundStyle(.white.opacity(0.6))
        }
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
                        insertion: .opacity.combined(with: .scale(scale: 0.5)),
                        removal: .opacity
                    ))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(showSuccess ? Color(hex: 0x4FC07E) : Color.clear,
                        lineWidth: showSuccess ? 3 : 0)
        )
    }

    /// The green "saved" confirmation shown briefly over the preview after a capture.
    private var successOverlay: some View {
        ZStack {
            Color(red: 63.0 / 255, green: 126.0 / 255, blue: 88.0 / 255, opacity: 0.5)
            VStack(spacing: 10) {
                ChromeIcon.circleCheck.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .foregroundStyle(.white)
                    .scaleEffect(1.1)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .delay(0),
                        value: showSuccess
                    )
                Text("Saved, next plant")
                    .font(SproutFont.display(18))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityHidden(true)
    }

    /// Shown when no live camera is available (simulator / denied permission).
    private var placeholder: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1)
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
            Button("Skip") { skipCurrent() }
                .font(SproutFont.body(17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button {
                Task { await capture() }
            } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 70, height: 70)
                    Circle().stroke(.white, lineWidth: 4).frame(width: 84, height: 84)
                }
            }
            .scaleEffect(isBusy ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: isBusy)
            .accessibilityLabel("Take photo")

            Spacer()

            Color.clear.frame(width: 1, height: 1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .disabled(isBusy)
        .opacity(isBusy ? 0.6 : 1)
        .padding(.horizontal, 22)
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
        withAnimation(.easeInOut(duration: 0.5)) { showSuccess = true }
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

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
