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
        dlog("StubPhotoCapturing.capture() — returning \(self.returnsImage ? "demo image" : "nil")")
        return returnsImage ? Self.placeholderImage() : nil
    }

    /// A square **demo** photo, intentionally distinct from the empty-state leaf
    /// placeholder (a teal→indigo gradient + camera glyph + "Demo photo") so that on
    /// the simulator a captured stub photo is visibly different from "no photo yet".
    static func placeholderImage(size: CGFloat = 600) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(bounds: rect, format: format).image { ctx in
            let cg = ctx.cgContext
            let colors = [UIColor.systemTeal.cgColor, UIColor.systemIndigo.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size, y: size), options: [])
            } else {
                UIColor.systemTeal.setFill(); cg.fill(rect)
            }
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.3)
            if let cam = UIImage(systemName: "camera.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                cam.draw(at: CGPoint(x: (size - cam.size.width) / 2, y: size * 0.3))
            }
            let text = "Demo photo"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: size * 0.08),
                .foregroundColor: UIColor.white,
            ]
            let textSize = (text as NSString).size(withAttributes: attrs)
            (text as NSString).draw(at: CGPoint(x: (size - textSize.width) / 2, y: size * 0.58), withAttributes: attrs)
        }
    }
}
