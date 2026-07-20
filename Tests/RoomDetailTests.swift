import XCTest
@testable import Sprout

/// Pins the Room detail screen's watering-impact copy (screen 15). The direction matches
/// the engine (`RoomEnvironment`): factor < 1 shortens the interval (water *more* often),
/// factor > 1 lengthens it (water *less* often), factor == 1 is balanced.
final class RoomDetailTests: XCTestCase {
    func testImpactLineWaterMoreOftenForLowFactor() {
        // 0.9 → |1 − 0.9| = 0.10 → 10%; below 1 → more often (bright, dry room).
        XCTAssertEqual(
            RoomImpactCopy.impactLine(factor: 0.9),
            "Bright light dries soil faster, plants here are watered about 10% more often."
        )
    }

    func testImpactLineWaterLessOftenForHighFactor() {
        // 1.15 → |1 − 1.15| = 0.15 → 15%; above 1 → less often (dark, humid room).
        XCTAssertEqual(
            RoomImpactCopy.impactLine(factor: 1.15),
            "Low light holds moisture longer, plants here are watered about 15% less often."
        )
    }

    func testImpactLineBalancedForNeutralFactor() {
        XCTAssertEqual(
            RoomImpactCopy.impactLine(factor: 1.0),
            "Balanced light and humidity, no adjustment to watering here."
        )
    }

    func testImpactLineAtClampEdges() {
        // The engine clamps the factor to [0.7, 1.3] — 30% either way.
        XCTAssertEqual(
            RoomImpactCopy.impactLine(factor: 0.7),
            "Bright light dries soil faster, plants here are watered about 30% more often."
        )
        XCTAssertEqual(
            RoomImpactCopy.impactLine(factor: 1.3),
            "Low light holds moisture longer, plants here are watered about 30% less often."
        )
    }
}
