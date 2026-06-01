import XCTest
import UIKit
@testable import Sprout

/// Unit tests for `StubPhotoCapturing` — the simulator/test stand-in for the camera.
@MainActor
final class StubPhotoCapturingTests: XCTestCase {

    func testReportsUnavailableByDefault() {
        XCTAssertFalse(StubPhotoCapturing().isAvailable)
        XCTAssertTrue(StubPhotoCapturing(isAvailable: true).isAvailable)
    }

    func testCaptureReturnsAnEncodableSquareImage() async throws {
        let captured = await StubPhotoCapturing().capture()
        let image = try XCTUnwrap(captured)
        // The placeholder must encode through the real photo pipeline.
        let data = try XCTUnwrap(PlantPhoto.encode(image))
        XCTAssertFalse(data.isEmpty)
    }

    func testCaptureCanSimulateFailure() async {
        let image = await StubPhotoCapturing(returnsImage: false).capture()
        XCTAssertNil(image)
    }
}
