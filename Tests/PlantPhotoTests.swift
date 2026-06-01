import XCTest
import UIKit
@testable import Sprout

/// Unit tests for `PlantPhoto.encode` — the crop + downscale + JPEG step that
/// produces the bytes stored on `Plant.photoData`.
final class PlantPhotoTests: XCTestCase {

    /// A solid-colour image of an arbitrary (possibly non-square) pixel size.
    private func image(width: Int, height: Int, color: UIColor = .green) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func testEncodeReturnsJPEGForValidImage() throws {
        let data = try XCTUnwrap(PlantPhoto.encode(image(width: 400, height: 400)))
        XCTAssertFalse(data.isEmpty)
        // JPEG magic bytes (FF D8) — confirm it really is a JPEG.
        XCTAssertEqual(Array(data.prefix(2)), [0xFF, 0xD8])
    }

    func testEncodeProducesSquareWithinMaxDimension() throws {
        // Non-square input is centre-cropped to a square, then downscaled.
        let data = try XCTUnwrap(PlantPhoto.encode(image(width: 800, height: 300), maxDimension: 64))
        let decoded = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(decoded.size.width, decoded.size.height, "output must be square")
        XCTAssertLessThanOrEqual(decoded.size.width, 64, "output must respect maxDimension")
        XCTAssertEqual(decoded.size.width, 64, accuracy: 1)
    }

    func testEncodeDoesNotUpscaleSmallImage() throws {
        // A 40 px source must not be blown up to maxDimension.
        let data = try XCTUnwrap(PlantPhoto.encode(image(width: 40, height: 40), maxDimension: 1024))
        let decoded = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(decoded.size.width, 40, accuracy: 1)
    }

    func testEncodeStaysUnderSizeCeiling() throws {
        // A full-size photo at default settings should compress to a modest blob.
        let data = try XCTUnwrap(PlantPhoto.encode(image(width: 3000, height: 2000)))
        XCTAssertLessThan(data.count, 600_000, "≈1024² JPEG should be well under 600 KB")
    }

    func testEncodeReturnsNilForImageWithoutCGImage() {
        // A bare UIImage has no backing CGImage to crop.
        XCTAssertNil(PlantPhoto.encode(UIImage()))
    }
}
