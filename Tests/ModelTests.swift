import XCTest
@testable import Sprout

/// Unit tests for the pure domain model (T003). These assert construction,
/// `Codable` round-trips, `Equatable`, and the `CareProfile` interval invariant.
final class ModelTests: XCTestCase {

    // MARK: - Enums

    func testEnumRawValuesMatchJSONContract() {
        // These raw values are the contract with care_database.json (T004).
        XCTAssertEqual(MoisturePreference.driesOut.rawValue, "driesOut")
        XCTAssertEqual(MoisturePreference.evenlyMoist.rawValue, "evenlyMoist")
        XCTAssertEqual(MoisturePreference.staysMoist.rawValue, "staysMoist")
        XCTAssertEqual(SoilMoisture.allCases, [.dry, .moist, .wet])
        XCTAssertEqual(LeafState.allCases, [.fine, .droopy])
    }

    // MARK: - CareProfile

    func testCareProfileConstruction() {
        let p = CareProfile(
            species: "Snake Plant",
            baseIntervalDays: 14,
            minIntervalDays: 10,
            maxIntervalDays: 21,
            moisture: .driesOut
        )
        XCTAssertEqual(p.species, "Snake Plant")
        XCTAssertEqual(p.id, "Snake Plant") // species is the identity key
        XCTAssertEqual(p.baseIntervalDays, 14)
        XCTAssertEqual(p.moisture, .driesOut)
    }

    func testCareProfileValidWhenIntervalsOrdered() {
        let p = CareProfile(species: "Pothos", baseIntervalDays: 7,
                            minIntervalDays: 5, maxIntervalDays: 12, moisture: .evenlyMoist)
        XCTAssertTrue(p.isValid)
    }

    func testCareProfileValidWhenIntervalsEqual() {
        // min == base == max is a degenerate-but-valid band.
        let p = CareProfile(species: "Cactus", baseIntervalDays: 21,
                            minIntervalDays: 21, maxIntervalDays: 21, moisture: .driesOut)
        XCTAssertTrue(p.isValid)
    }

    func testCareProfileInvalidWhenBaseBelowMin() {
        let p = CareProfile(species: "Fern", baseIntervalDays: 3,
                            minIntervalDays: 5, maxIntervalDays: 10, moisture: .staysMoist)
        XCTAssertFalse(p.isValid)
    }

    func testCareProfileInvalidWhenBaseAboveMax() {
        let p = CareProfile(species: "Fern", baseIntervalDays: 12,
                            minIntervalDays: 5, maxIntervalDays: 10, moisture: .staysMoist)
        XCTAssertFalse(p.isValid)
    }

    func testCareProfileInvalidWhenMinNotPositive() {
        let p = CareProfile(species: "Fern", baseIntervalDays: 0,
                            minIntervalDays: 0, maxIntervalDays: 10, moisture: .staysMoist)
        XCTAssertFalse(p.isValid)
    }

    func testCareProfileInvalidWhenSpeciesBlank() {
        let p = CareProfile(species: "   ", baseIntervalDays: 7,
                            minIntervalDays: 5, maxIntervalDays: 10, moisture: .evenlyMoist)
        XCTAssertFalse(p.isValid)
    }

    func testCareProfileCodableRoundTrip() throws {
        let p = CareProfile(species: "Monstera deliciosa", baseIntervalDays: 9,
                            minIntervalDays: 6, maxIntervalDays: 14, moisture: .evenlyMoist)
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(CareProfile.self, from: data)
        XCTAssertEqual(p, decoded)
    }

    func testCareProfileDecodesFromDatabaseShapedJSON() throws {
        let json = """
        {
            "species": "Snake Plant",
            "baseIntervalDays": 14,
            "minIntervalDays": 10,
            "maxIntervalDays": 28,
            "moisture": "driesOut"
        }
        """.data(using: .utf8)!
        let p = try JSONDecoder().decode(CareProfile.self, from: json)
        XCTAssertEqual(p.species, "Snake Plant")
        XCTAssertEqual(p.moisture, .driesOut)
        XCTAssertTrue(p.isValid)
    }

    // MARK: - CheckIn

    func testCheckInConstructionAndCodable() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let c = CheckIn(date: date, soil: .moist, leaves: .fine, watered: true)
        XCTAssertEqual(c.soil, .moist)
        XCTAssertEqual(c.leaves, .fine)
        XCTAssertTrue(c.watered)

        let decoded = try JSONDecoder().decode(CheckIn.self,
                                               from: JSONEncoder().encode(c))
        XCTAssertEqual(c, decoded)
    }

    func testCheckInIdentityIsStable() {
        let id = UUID()
        let c = CheckIn(id: id, date: Date(), soil: .dry, leaves: .droopy, watered: false)
        XCTAssertEqual(c.id, id)
    }

    // MARK: - Plant

    func testPlantDefaults() {
        let plant = Plant(nickname: "Monty", species: "Monstera deliciosa")
        XCTAssertEqual(plant.adj, 1.0)
        XCTAssertEqual(plant.adj, Plant.defaultAdj)
        XCTAssertNil(plant.lastWatered)
        XCTAssertNil(plant.nextDue)
        XCTAssertTrue(plant.checkIns.isEmpty)
    }

    func testPlantAdjRangeConstant() {
        XCTAssertEqual(Plant.adjRange, 0.5...2.0)
    }

    func testPlantEquatableAndCodableRoundTrip() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let plant = Plant(
            nickname: "Spike",
            species: "Sansevieria trifasciata",
            adj: 1.3,
            lastWatered: date,
            nextDue: date.addingTimeInterval(14 * 86_400),
            checkIns: [CheckIn(date: date, soil: .dry, leaves: .fine, watered: true)]
        )
        let decoded = try JSONDecoder().decode(Plant.self,
                                               from: JSONEncoder().encode(plant))
        XCTAssertEqual(plant, decoded)
    }

    func testPlantAccumulatesCheckIns() {
        var plant = Plant(nickname: "Lily", species: "Spathiphyllum wallisii")
        plant.checkIns.append(CheckIn(date: Date(), soil: .wet, leaves: .droopy, watered: false))
        plant.checkIns.append(CheckIn(date: Date(), soil: .dry, leaves: .fine, watered: true))
        XCTAssertEqual(plant.checkIns.count, 2)
    }
}
