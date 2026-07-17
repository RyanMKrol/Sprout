import XCTest
@testable import Sprout

/// Covers the home grid's subtitle copy (T222). The watering tiles are split into
/// "Water your plants" (due now) and "Full check-in" (every plant); these helpers
/// drive their — and the My Plants tile's — subtitles.
final class HomeTileTextTests: XCTestCase {
    func testPlantsSubtitleEmptyPrompts() {
        XCTAssertEqual(HomeTileText.plantsSubtitle(count: 0), "None yet")
    }

    func testPlantsSubtitleSingularAndPlural() {
        XCTAssertEqual(HomeTileText.plantsSubtitle(count: 1), "1 growing")
        XCTAssertEqual(HomeTileText.plantsSubtitle(count: 4), "4 growing")
    }

    func testRoomsSubtitleEmptyPrompts() {
        XCTAssertEqual(HomeTileText.roomsSubtitle(count: 0), "Set one up")
    }

    func testRoomsSubtitleSingularAndPlural() {
        XCTAssertEqual(HomeTileText.roomsSubtitle(count: 1), "1 space")
        XCTAssertEqual(HomeTileText.roomsSubtitle(count: 3), "3 spaces")
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

    func testStatusLineGreeting() {
        // No plants → onboarding nudge.
        XCTAssertEqual(HomeTileText.statusLine(dueCount: 0, total: 0), "Let's add your first plant 🌱")
        // Plants, none due → reassurance.
        XCTAssertEqual(HomeTileText.statusLine(dueCount: 0, total: 5), "Everything's watered — nice work 🌿")
        // Due plants → singular / plural.
        XCTAssertEqual(HomeTileText.statusLine(dueCount: 1, total: 5), "1 plant needs water today 💧")
        XCTAssertEqual(HomeTileText.statusLine(dueCount: 3, total: 5), "3 plants need water today 💧")
    }
}
