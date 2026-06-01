import XCTest
@testable import Sprout

/// Covers the post-add photo prompt's copy (T223). The prompt is now a connected sheet
/// (not a floating dialog) with a clear take-vs-skip choice; these helpers drive its
/// singular/plural wording, so it stays correct without instantiating the SwiftUI view.
final class PhotoPromptTextTests: XCTestCase {
    func testTitleSingularAndPlural() {
        XCTAssertEqual(PhotoPromptText.title(count: 1), "Add a photo of your new plant?")
        XCTAssertEqual(PhotoPromptText.title(count: 3), "Add photos of your new plants?")
    }

    func testSubtitleOffersSkipInBothForms() {
        XCTAssertTrue(PhotoPromptText.subtitle(count: 1).lowercased().contains("skip"))
        XCTAssertTrue(PhotoPromptText.subtitle(count: 5).lowercased().contains("skip"))
    }

    func testListHeaderCountsPlants() {
        XCTAssertEqual(PhotoPromptText.listHeader(count: 1), "New plant")
        XCTAssertEqual(PhotoPromptText.listHeader(count: 4), "New plants (4)")
    }
}
