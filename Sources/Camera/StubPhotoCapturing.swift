import UIKit

/// A `PhotoCapturing` stand-in for the simulator, DEBUG screenshots, and unit tests
/// — the real AVFoundation camera (T207) can't run on the simulator. It reports the
/// camera unavailable (so the UI shows its placeholder state) but still returns a
/// generated square image from `capture()`, so the sequential flow completes and is
/// screenshottable / testable without hardware.
final class StubPhotoCapturing: PhotoCapturing {
    let isAvailable: Bool
    private let returnsImage: Bool

    /// - Parameters:
    ///   - isAvailable: what `isAvailable` reports (default `false`, like the sim).
    ///   - returnsImage: when `false`, `capture()` returns `nil` to exercise the
    ///     failure branch in tests.
    init(isAvailable: Bool = false, returnsImage: Bool = true) {
        self.isAvailable = isAvailable
        self.returnsImage = returnsImage
    }

    func capture() async -> UIImage? {
        returnsImage ? Self.placeholderImage() : nil
    }

    /// A simple square placeholder: a soft green field with a centred leaf glyph.
    static func placeholderImage(size: CGFloat = 600) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(bounds: rect, format: format).image { ctx in
            UIColor.systemGreen.withAlphaComponent(0.2).setFill()
            ctx.fill(rect)
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.35)
            if let leaf = UIImage(systemName: "leaf.fill", withConfiguration: config)?
                .withTintColor(.systemGreen, renderingMode: .alwaysOriginal) {
                let origin = CGPoint(
                    x: (size - leaf.size.width) / 2,
                    y: (size - leaf.size.height) / 2
                )
                leaf.draw(at: origin)
            }
        }
    }
}
