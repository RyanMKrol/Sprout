import XCTest
@testable import Sprout

final class RhythmBandTests: XCTestCase {

    func testPositionCalculation() {
        let position = RhythmBand.position(of: 7, min: 4, max: 14)
        XCTAssertEqual(position, 0.3, accuracy: 0.0001)
    }

    func testPositionClampedLow() {
        let position = RhythmBand.position(of: 2, min: 4, max: 14)
        XCTAssertEqual(position, 0.0)
    }

    func testPositionClampedHigh() {
        let position = RhythmBand.position(of: 20, min: 4, max: 14)
        XCTAssertEqual(position, 1.0)
    }

    func testPositionEqualBounds() {
        let position = RhythmBand.position(of: 5, min: 5, max: 5)
        XCTAssertEqual(position, 0.5)
    }

    func testPositionInvertedBounds() {
        let position = RhythmBand.position(of: 10, min: 15, max: 5)
        XCTAssertEqual(position, 0.5)
    }

    func testLabelCollisionThreshold() {
        let basePosition = RhythmBand.position(of: 7, min: 4, max: 14)
        let nowPosition1 = RhythmBand.position(of: 7, min: 4, max: 14)
        let nowPosition2 = RhythmBand.position(of: 8, min: 4, max: 14)

        let diff1 = abs(basePosition - nowPosition1)
        let diff2 = abs(basePosition - nowPosition2)

        XCTAssertLessThan(diff1, 0.08)
        XCTAssertGreaterThan(diff2, 0.08)
    }
}
