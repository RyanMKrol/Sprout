import XCTest
@testable import Sprout

/// Unit tests for the display helpers: species/room title-casing.
final class DisplayFormattingTests: XCTestCase {
    // MARK: capitalisedWords

    func testCapitalisesEachWordsFirstLetter() {
        XCTAssertEqual("monstera deliciosa".capitalisedWords, "Monstera Deliciosa")
        XCTAssertEqual("peace lily".capitalisedWords, "Peace Lily")
        XCTAssertEqual("living room".capitalisedWords, "Living Room")
    }

    func testPreservesExistingCapitalsAndPunctuation() {
        // Acronyms and apostrophes must survive — unlike Foundation's `.capitalized`,
        // which would yield "Zz Plant" / "Bird'S Nest Fern".
        XCTAssertEqual("ZZ Plant".capitalisedWords, "ZZ Plant")
        XCTAssertEqual("bird's nest fern".capitalisedWords, "Bird's Nest Fern")
        XCTAssertEqual("Monstera Deliciosa".capitalisedWords, "Monstera Deliciosa")
    }

    func testHandlesEmptyAndSingleWord() {
        XCTAssertEqual("".capitalisedWords, "")
        XCTAssertEqual("pothos".capitalisedWords, "Pothos")
    }
}
