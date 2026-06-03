import XCTest
@testable import Sprout

/// Unit tests for the display helpers: species/room title-casing and the deterministic
/// plant-placeholder palette.
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

    // MARK: PlantPalette

    func testPaletteColourIsStableForSameID() {
        let id = UUID()
        XCTAssertEqual(PlantPalette.color(for: id), PlantPalette.color(for: id))
    }

    func testPaletteHasTenDistinctColours() {
        XCTAssertEqual(PlantPalette.colors.count, 10)
        XCTAssertEqual(Set(PlantPalette.colors.map { "\($0)" }).count, 10)
    }
}
