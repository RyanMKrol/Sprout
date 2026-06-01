import XCTest
@testable import Sprout

/// Unit tests for the care-database loader, schema decode, and reusable validator
/// (T004). Covers: a valid file decodes + validates; a malformed record and a
/// duplicate species are each rejected; the picker's search/sort works; and the
/// **actual shipped** `care_database.json` decodes and validates clean.
final class CareDatabaseTests: XCTestCase {

    // MARK: - Fixtures

    /// A small valid dataset, deliberately out of display order to prove sorting.
    private let validJSON = """
    [
      { "species": "Snake Plant", "baseIntervalDays": 14, "minIntervalDays": 10, "maxIntervalDays": 28, "moisture": "driesOut" },
      { "species": "Boston Fern", "baseIntervalDays": 4, "minIntervalDays": 2, "maxIntervalDays": 7, "moisture": "staysMoist" },
      { "species": "Pothos", "baseIntervalDays": 7, "minIntervalDays": 5, "maxIntervalDays": 14, "moisture": "evenlyMoist" }
    ]
    """.data(using: .utf8)!

    /// URL of the real bundled dataset, located relative to this test file so the
    /// test does not depend on the resource being copied into the test bundle.
    private var shippedDatabaseURL: URL {
        URL(fileURLWithPath: #filePath)        // .../Tests/CareDatabaseTests.swift
            .deletingLastPathComponent()        // .../Tests
            .deletingLastPathComponent()        // repo root
            .appendingPathComponent("Sources/Resources/care_database.json")
    }

    // MARK: - Decode + load (happy path)

    func testValidFileDecodesAndValidates() throws {
        let db = try CareDatabase.load(from: validJSON)
        XCTAssertEqual(db.count, 3)
    }

    func testLoadSortsBySpeciesCaseInsensitively() throws {
        let db = try CareDatabase.load(from: validJSON)
        XCTAssertEqual(db.profiles.map(\.species), ["Boston Fern", "Pothos", "Snake Plant"])
    }

    func testDecodePreservesFieldsAndMoistureEnum() throws {
        let db = try CareDatabase.load(from: validJSON)
        let snake = try XCTUnwrap(db.profile(forSpecies: "snake plant"))
        XCTAssertEqual(snake.baseIntervalDays, 14)
        XCTAssertEqual(snake.minIntervalDays, 10)
        XCTAssertEqual(snake.maxIntervalDays, 28)
        XCTAssertEqual(snake.moisture, .driesOut)
    }

    // MARK: - Validator (rejects bad data)

    func testValidatorRejectsMalformedRecord() {
        // base (3) below min (5) — fails CareProfile.isValid.
        let badJSON = """
        [
          { "species": "Pothos", "baseIntervalDays": 7, "minIntervalDays": 5, "maxIntervalDays": 14, "moisture": "evenlyMoist" },
          { "species": "Wonky", "baseIntervalDays": 3, "minIntervalDays": 5, "maxIntervalDays": 14, "moisture": "evenlyMoist" }
        ]
        """.data(using: .utf8)!
        XCTAssertThrowsError(try CareDatabase.load(from: badJSON)) { error in
            XCTAssertEqual(error as? CareDatabaseError, .invalidRecord(species: "Wonky"))
        }
    }

    func testValidatorRejectsDuplicateSpecies() {
        // "Pothos" and " pothos " normalise to the same key.
        let dupeJSON = """
        [
          { "species": "Pothos", "baseIntervalDays": 7, "minIntervalDays": 5, "maxIntervalDays": 14, "moisture": "evenlyMoist" },
          { "species": " pothos ", "baseIntervalDays": 8, "minIntervalDays": 5, "maxIntervalDays": 14, "moisture": "evenlyMoist" }
        ]
        """.data(using: .utf8)!
        XCTAssertThrowsError(try CareDatabase.load(from: dupeJSON)) { error in
            XCTAssertEqual(error as? CareDatabaseError, .duplicateSpecies(" pothos "))
        }
    }

    func testValidatorAcceptsCleanDataset() {
        let profiles = [
            CareProfile(species: "A", baseIntervalDays: 7, minIntervalDays: 5, maxIntervalDays: 9, moisture: .evenlyMoist),
            CareProfile(species: "B", baseIntervalDays: 14, minIntervalDays: 14, maxIntervalDays: 14, moisture: .driesOut),
        ]
        XCTAssertNoThrow(try CareDatabaseValidator.validate(profiles))
    }

    func testLoadBundledThrowsResourceMissingForUnknownResource() {
        XCTAssertThrowsError(
            try CareDatabase.loadBundled(from: .main, resource: "does_not_exist")
        ) { error in
            XCTAssertEqual(error as? CareDatabaseError, .resourceMissing("does_not_exist.json"))
        }
    }

    // MARK: - Picker support

    func testSearchIsCaseAndDiacriticInsensitiveSubstring() throws {
        let db = try CareDatabase.load(from: validJSON)
        XCTAssertEqual(db.search("fern").map(\.species), ["Boston Fern"])
        XCTAssertEqual(db.search("POT").map(\.species), ["Pothos"])
    }

    func testEmptySearchReturnsFullSortedList() throws {
        let db = try CareDatabase.load(from: validJSON)
        XCTAssertEqual(db.search("   ").map(\.species), db.profiles.map(\.species))
    }

    func testSearchNoMatchReturnsEmpty() throws {
        let db = try CareDatabase.load(from: validJSON)
        XCTAssertTrue(db.search("cactus").isEmpty)
    }

    // MARK: - The real shipped dataset

    func testShippedDatabaseDecodesAndValidates() throws {
        let data = try Data(contentsOf: shippedDatabaseURL)
        let db = try CareDatabase.load(from: data)
        XCTAssertGreaterThanOrEqual(db.count, 5, "Seed dataset should hold at least ~5 plants")
        // Every shipped record passes the single-record invariant.
        XCTAssertTrue(db.profiles.allSatisfy(\.isValid))
    }
}
