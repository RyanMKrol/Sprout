import XCTest
@testable import Sprout

/// Unit tests for `RoomEnvironment.factor` and the T220 brightness inference — the
/// (direct + indirect light → brightness) × humidity → schedule multiplier that
/// replaces the coarse sunlight factor.
final class RoomEnvironmentTests: XCTestCase {

    // MARK: brightness inference

    func testBrightnessIsDarkWhenBothLow() {
        XCTAssertEqual(Brightness.inferred(directSun: .low, indirectSun: .low), .dark)
    }

    func testBrightnessIsBrightWhenBothHigh() {
        XCTAssertEqual(Brightness.inferred(directSun: .high, indirectSun: .high), .bright)
    }

    func testDirectSunDominatesBrightness() {
        // High direct sun alone is already bright; high indirect alone is only medium.
        XCTAssertEqual(Brightness.inferred(directSun: .high, indirectSun: .low), .bright)
        XCTAssertEqual(Brightness.inferred(directSun: .low, indirectSun: .high), .medium)
    }

    func testBrightnessIsMonotonicInEachInput() {
        // Raising either input never lowers the inferred brightness (use score order).
        func score(_ b: Brightness) -> Int { Brightness.allCases.firstIndex(of: b)! }
        for indirect in LightLevel.allCases {
            let dark = score(Brightness.inferred(directSun: .low, indirectSun: indirect))
            let mid = score(Brightness.inferred(directSun: .medium, indirectSun: indirect))
            let bright = score(Brightness.inferred(directSun: .high, indirectSun: indirect))
            XCTAssertLessThanOrEqual(dark, mid)
            XCTAssertLessThanOrEqual(mid, bright)
        }
        for direct in LightLevel.allCases {
            let dark = score(Brightness.inferred(directSun: direct, indirectSun: .low))
            let mid = score(Brightness.inferred(directSun: direct, indirectSun: .medium))
            let bright = score(Brightness.inferred(directSun: direct, indirectSun: .high))
            XCTAssertLessThanOrEqual(dark, mid)
            XCTAssertLessThanOrEqual(mid, bright)
        }
    }

    // MARK: factor

    func testNeutralRoomIsOne() {
        XCTAssertEqual(RoomEnvironment.factor(brightness: .medium, humidity: .normal), 1.0, accuracy: 0.0001)
    }

    func testNoRoomIsNeutral() {
        XCTAssertEqual(RoomEnvironment.factor(for: nil), 1.0, accuracy: 0.0001)
    }

    func testRoomConvenienceMatchesBrightness() {
        let room = Room(name: "Office", directSun: .high, indirectSun: .high, humidity: .dry)
        XCTAssertEqual(RoomEnvironment.factor(for: room),
                       RoomEnvironment.factor(brightness: .bright, humidity: .dry),
                       accuracy: 0.0001)
    }

    func testLightLevelFactorMatchesInferredBrightness() {
        XCTAssertEqual(
            RoomEnvironment.factor(directSun: .low, indirectSun: .high, humidity: .normal),
            RoomEnvironment.factor(brightness: .medium, humidity: .normal),
            accuracy: 0.0001
        )
    }

    func testBrighterAndDrierShortensInterval() {
        // Brighter → smaller factor; drier air → smaller factor.
        XCTAssertLessThan(
            RoomEnvironment.factor(brightness: .bright, humidity: .normal),
            RoomEnvironment.factor(brightness: .medium, humidity: .normal)
        )
        XCTAssertLessThan(
            RoomEnvironment.factor(brightness: .medium, humidity: .normal),
            RoomEnvironment.factor(brightness: .dark, humidity: .normal)
        )
        XCTAssertLessThan(
            RoomEnvironment.factor(brightness: .medium, humidity: .dry),
            RoomEnvironment.factor(brightness: .medium, humidity: .moist)
        )
    }

    func testAllCombosStayWithinClampBand() {
        for brightness in Brightness.allCases {
            for hum in RoomHumidity.allCases {
                let f = RoomEnvironment.factor(brightness: brightness, humidity: hum)
                XCTAssertGreaterThanOrEqual(f, RoomEnvironment.factorRange.lowerBound)
                XCTAssertLessThanOrEqual(f, RoomEnvironment.factorRange.upperBound)
            }
        }
    }

    func testExtremeCombosComputeAsExpected() {
        XCTAssertEqual(RoomEnvironment.factor(brightness: .dark, humidity: .moist), 1.265, accuracy: 0.0001)
        XCTAssertEqual(RoomEnvironment.factor(brightness: .bright, humidity: .dry), 0.765, accuracy: 0.0001)
    }
}
