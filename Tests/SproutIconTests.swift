import XCTest
import UIKit

@testable import Sprout

final class SproutIconTests: XCTestCase {
    func testPlantIconImagesResolve() {
        for icon in PlantIcon.allCases {
            let uiImage = UIImage(named: icon.rawValue)
            XCTAssertNotNil(uiImage, "PlantIcon \(icon.rawValue) should resolve to an image")
        }
    }

    func testChromeIconImagesResolve() {
        for icon in ChromeIcon.allCases {
            let uiImage = UIImage(named: icon.rawValue)
            XCTAssertNotNil(uiImage, "ChromeIcon \(icon.rawValue) should resolve to an image")
        }
    }

    func testPlantIconDefaultForFern() {
        let icon = PlantIcon.default(forSpecies: "Boston Fern")
        XCTAssertEqual(icon, .leaf)
    }

    func testPlantIconDefaultForMonstera() {
        let icon = PlantIcon.default(forSpecies: "Monstera deliciosa")
        XCTAssertEqual(icon, .plant)
    }

    func testPlantIconDefaultForCactus() {
        let icon = PlantIcon.default(forSpecies: "Prickly Pear Cactus")
        XCTAssertEqual(icon, .cactus)
    }

    func testPlantIconDefaultForOrchid() {
        let icon = PlantIcon.default(forSpecies: "Phalaenopsis Orchid")
        XCTAssertEqual(icon, .flowerLotus)
    }

    func testPlantIconDefaultForSucculent() {
        let icon = PlantIcon.default(forSpecies: "Echeveria pulido")
        XCTAssertEqual(icon, .pottedPlant)
    }

    func testPlantIconDefaultForAloe() {
        let icon = PlantIcon.default(forSpecies: "Aloe vera")
        XCTAssertEqual(icon, .pottedPlant)
    }

    func testPlantIconDefaultForTulip() {
        let icon = PlantIcon.default(forSpecies: "Tulip")
        XCTAssertEqual(icon, .flowerTulip)
    }

    func testPlantIconDefaultForTreePalm() {
        let icon = PlantIcon.default(forSpecies: "Areca Palm")
        XCTAssertEqual(icon, .treePalm)
    }

    func testPlantIconDefaultForTree() {
        let icon = PlantIcon.default(forSpecies: "Ficus lyrata")
        XCTAssertEqual(icon, .tree)
    }

    func testPlantIconDefaultForEvergreen() {
        let icon = PlantIcon.default(forSpecies: "Pine tree")
        XCTAssertEqual(icon, .treeEvergreen)
    }

    func testPlantIconDefaultForHerb() {
        let icon = PlantIcon.default(forSpecies: "Basil")
        XCTAssertEqual(icon, .grains)
    }

    func testPlantIconDefaultForCitrus() {
        let icon = PlantIcon.default(forSpecies: "Lemon tree")
        XCTAssertEqual(icon, .cherries)
    }

    func testPlantIconDefaultForCarrot() {
        let icon = PlantIcon.default(forSpecies: "Carrot")
        XCTAssertEqual(icon, .carrot)
    }

    func testPlantIconDefaultForPepper() {
        let icon = PlantIcon.default(forSpecies: "Bell Pepper")
        XCTAssertEqual(icon, .pepper)
    }

    func testPlantIconDefaultForClover() {
        let icon = PlantIcon.default(forSpecies: "Clover")
        XCTAssertEqual(icon, .clover)
    }

    func testPlantIconDefaultForFlower() {
        let icon = PlantIcon.default(forSpecies: "African Violet")
        XCTAssertEqual(icon, .flower)
    }

    func testPlantIconCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for icon in PlantIcon.allCases {
            let encoded = try encoder.encode(icon)
            let decoded = try decoder.decode(PlantIcon.self, from: encoded)
            XCTAssertEqual(decoded, icon)
        }
    }
}
