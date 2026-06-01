import XCTest
@testable import Sprout

/// Unit tests for `RoomEnvironment.factor` — the sunlight × humidity → schedule
/// multiplier that replaces the weather factor.
final class RoomEnvironmentTests: XCTestCase {

    func testNeutralRoomIsOne() {
        XCTAssertEqual(RoomEnvironment.factor(sunlight: .indirect, humidity: .normal), 1.0, accuracy: 0.0001)
    }

    func testNoRoomIsNeutral() {
        XCTAssertEqual(RoomEnvironment.factor(for: nil), 1.0, accuracy: 0.0001)
    }

    func testRoomConvenienceMatchesProperties() {
        let room = Room(name: "Office", sunlight: .direct, humidity: .dry)
        XCTAssertEqual(RoomEnvironment.factor(for: room),
                       RoomEnvironment.factor(sunlight: .direct, humidity: .dry),
                       accuracy: 0.0001)
    }

    func testBrighterAndDrierShortensInterval() {
        // More light → smaller factor; drier air → smaller factor.
        XCTAssertLessThan(
            RoomEnvironment.factor(sunlight: .direct, humidity: .normal),
            RoomEnvironment.factor(sunlight: .indirect, humidity: .normal)
        )
        XCTAssertLessThan(
            RoomEnvironment.factor(sunlight: .indirect, humidity: .normal),
            RoomEnvironment.factor(sunlight: .low, humidity: .normal)
        )
        XCTAssertLessThan(
            RoomEnvironment.factor(sunlight: .indirect, humidity: .dry),
            RoomEnvironment.factor(sunlight: .indirect, humidity: .moist)
        )
    }

    func testAllCombosStayWithinClampBand() {
        for sun in SunlightLevel.allCases {
            for hum in RoomHumidity.allCases {
                let f = RoomEnvironment.factor(sunlight: sun, humidity: hum)
                XCTAssertGreaterThanOrEqual(f, RoomEnvironment.factorRange.lowerBound)
                XCTAssertLessThanOrEqual(f, RoomEnvironment.factorRange.upperBound)
            }
        }
    }

    func testExtremeCombosComputeAsExpected() {
        XCTAssertEqual(RoomEnvironment.factor(sunlight: .low, humidity: .moist), 1.265, accuracy: 0.0001)
        XCTAssertEqual(RoomEnvironment.factor(sunlight: .direct, humidity: .dry), 0.765, accuracy: 0.0001)
    }
}
