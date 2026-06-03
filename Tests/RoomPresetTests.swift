import XCTest
@testable import Sprout

/// Unit tests for the `RoomPreset` catalogue that backs the add-room wheel.
final class RoomPresetTests: XCTestCase {
    func testCatalogueIsNonEmptyWithUniqueNames() {
        let names = RoomPreset.common.map(\.name)
        XCTAssertFalse(names.isEmpty)
        XCTAssertEqual(Set(names).count, names.count, "preset names must be unique (they're the wheel tags)")
    }

    func testCommonRoomsArePresent() {
        let names = Set(RoomPreset.common.map(\.name))
        XCTAssertTrue(names.contains("Living Room"))
        XCTAssertTrue(names.contains("Kitchen"))
        XCTAssertTrue(names.contains("Bedroom"))
        XCTAssertTrue(names.contains("Bathroom"))
    }

    func testEnvironmentSummaryReflectsDefaults() {
        // Bathroom defaults to moist — the summary should say so.
        let bathroom = try! XCTUnwrap(RoomPreset.common.first { $0.name == "Bathroom" })
        XCTAssertEqual(bathroom.humidity, .moist)
        XCTAssertTrue(bathroom.environmentSummary.contains(RoomHumidity.moist.label))
    }
}
