import UIKit

/// Turns a captured `UIImage` into the compact JPEG bytes stored on
/// `Plant.photoData`. The single place that crops + downscales + compresses a
/// plant photo, so the camera capture path (T206/T207) and any future import
/// path share the exact same encoding.
///
/// UIKit-aware on purpose: it lives here rather than on the pure-domain `Plant`
/// value type so `Plant` keeps no UIKit dependency.
enum PlantPhoto {
    /// Center-crop `image` to a square, downscale its edge to at most
    /// `maxDimension` points, and JPEG-compress at `jpegQuality`. A 1024 px square
    /// at 0.7 quality lands around 150–300 KB — small enough for SwiftData's
    /// external storage, sharp enough for a card thumbnail and the detail view.
    ///
    /// - Returns: the JPEG bytes, or `nil` if the image has no drawable area.
    static func encode(
        _ image: UIImage,
        maxDimension: CGFloat = 1024,
        jpegQuality: CGFloat = 0.7
    ) -> Data? {
        guard let square = centerCroppedSquare(image) else { return nil }
        let target = min(square.size.width, maxDimension)
        guard target > 0 else { return nil }

        let size = CGSize(width: target, height: target)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1 // points == pixels, so the JPEG is exactly target×target
        format.opaque = true
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            square.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: jpegQuality)
    }

    /// Crop `image` to a centered square of its shorter edge. `nil` if the image
    /// has no backing `CGImage` or zero area.
    private static func centerCroppedSquare(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let width = CGFloat(cg.width)
        let height = CGFloat(cg.height)
        guard width > 0, height > 0 else { return nil }

        let edge = min(width, height)
        let cropRect = CGRect(
            x: ((width - edge) / 2).rounded(.down),
            y: ((height - edge) / 2).rounded(.down),
            width: edge,
            height: edge
        )
        guard let cropped = cg.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropped, scale: 1, orientation: image.imageOrientation)
    }
}
