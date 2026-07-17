import XCTest
@testable import Sprout

final class PlantTokenTests: XCTestCase {

    func testDuoIsStable() {
        let id = UUID(uuidString: "12345678-1234-5678-1234-567812345678")!
        let duo1 = PlantTokenPalette.duo(for: id)
        let duo2 = PlantTokenPalette.duo(for: id)

        XCTAssertEqual(duo1.light, duo2.light)
        XCTAssertEqual(duo1.dark, duo2.dark)
    }

    func testDistinctUUIDsMapToPredictableDuos() {
        let uuid1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let uuid2 = UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!

        let duo1 = PlantTokenPalette.duo(for: uuid1)
        let duo2 = PlantTokenPalette.duo(for: uuid2)

        let sum1 = uuid1.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let sum2 = uuid2.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }

        let expectedDuo1 = PlantTokenPalette.duos[sum1 % PlantTokenPalette.duos.count]
        let expectedDuo2 = PlantTokenPalette.duos[sum2 % PlantTokenPalette.duos.count]

        XCTAssertEqual(duo1.light, expectedDuo1.light)
        XCTAssertEqual(duo1.dark, expectedDuo1.dark)
        XCTAssertEqual(duo2.light, expectedDuo2.light)
        XCTAssertEqual(duo2.dark, expectedDuo2.dark)
    }
}
