import XCTest
@testable import Sprout

/// Covers the home grid's subtitle copy (T222). The watering tiles are split into
/// "Water your plants" (due now) and "Full check-in" (every plant); these helpers
/// drive their — and the My Plants tile's — subtitles.
final class HomeTileTextTests: XCTestCase {
    func testPlantsSubtitleEmptyPrompts() {
        XCTAssertEqual(HomeTileText.plantsSubtitle(count: 0), "Add your first plant")
    }

    func testPlantsSubtitleSingularAndPlural() {
        XCTAssertEqual(HomeTileText.plantsSubtitle(count: 1), "1 plant")
        XCTAssertEqual(HomeTileText.plantsSubtitle(count: 4), "4 plants")
    }

    func testWaterSubtitleReflectsDueCount() {
        XCTAssertEqual(HomeTileText.waterSubtitle(dueCount: 0), "Nothing due right now")
        XCTAssertEqual(HomeTileText.waterSubtitle(dueCount: 3), "3 due now")
    }

    func testCheckInSubtitleAlwaysCoversEveryPlant() {
        XCTAssertEqual(HomeTileText.checkInSubtitle(total: 0), "No plants yet")
        XCTAssertEqual(HomeTileText.checkInSubtitle(total: 1), "Check every plant")
        XCTAssertEqual(HomeTileText.checkInSubtitle(total: 9), "Check every plant")
    }
}
