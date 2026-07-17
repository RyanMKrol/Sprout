import XCTest
@testable import Sprout

/// Covers the post-add photo prompt's copy. The prompt displays count-aware titles
/// ("One plant added 🌱", "Three plants added 🌱", etc.) with spelled-out numbers
/// one through nine, capitalized.
final class PhotoPromptTextTests: XCTestCase {
    func testTitleSingularAndPlural() {
        XCTAssertEqual(PhotoPromptText.title(count: 1), "One plant added 🌱")
        XCTAssertEqual(PhotoPromptText.title(count: 3), "Three plants added 🌱")
    }

    func testTitleSpellsNumbersOneToNine() {
        XCTAssertEqual(PhotoPromptText.title(count: 2), "Two plants added 🌱")
        XCTAssertEqual(PhotoPromptText.title(count: 5), "Five plants added 🌱")
        XCTAssertEqual(PhotoPromptText.title(count: 9), "Nine plants added 🌱")
    }

    func testTitleUsesNumberStringForTenPlus() {
        XCTAssertTrue(PhotoPromptText.title(count: 10).contains("10"))
        XCTAssertTrue(PhotoPromptText.title(count: 15).contains("15"))
    }

    func testSubtitleIsFixed() {
        let subtitle = PhotoPromptText.subtitle(count: 1)
        XCTAssertEqual(subtitle, "Add a photo of each so they're easy to spot. You can always do this later.")
        XCTAssertEqual(PhotoPromptText.subtitle(count: 5), subtitle)
    }

    func testListHeaderCountsPlants() {
        XCTAssertEqual(PhotoPromptText.listHeader(count: 1), "New plant")
        XCTAssertEqual(PhotoPromptText.listHeader(count: 4), "New plants (4)")
    }
}
