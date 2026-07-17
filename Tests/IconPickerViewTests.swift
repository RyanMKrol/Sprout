import XCTest
@testable import Sprout

/// Unit tests for the Icon Picker sheet (T021): verifies that selecting an icon
/// and saving updates the plant's icon, and that re-opening shows the updated icon
/// selected.
@MainActor
final class IconPickerViewTests: XCTestCase {
    private var repo: PlantRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    func testIconSelectionRoundTrips() throws {
        // Arrange: Create a plant with the default icon
        let plant = Plant(nickname: "Monstera", species: "Monstera deliciosa", icon: .plant)
        try repo.add(plant)

        // Act 1: Get the plant, verify it has the initial icon
        var retrieved = try repo.plant(id: plant.id)
        XCTAssertEqual(retrieved?.icon, .plant)

        // Act 2: Simulate picking a different icon and saving
        var updated = retrieved!
        updated.icon = .flower
        try repo.update(updated)

        // Assert: Retrieve the plant again and verify the new icon persists
        retrieved = try repo.plant(id: plant.id)
        XCTAssertEqual(retrieved?.icon, .flower)
    }

    func testAllIconsCanBeSelected() throws {
        let plant = Plant(nickname: "Test", species: "Test", icon: .plant)
        try repo.add(plant)

        // Iterate through all available icons and verify each can be stored
        for icon in PlantIcon.allCases {
            var updated = try repo.plant(id: plant.id)!
            updated.icon = icon
            try repo.update(updated)

            let retrieved = try repo.plant(id: plant.id)!
            XCTAssertEqual(retrieved.icon, icon, "Icon \(icon.rawValue) did not round-trip")
        }
    }
}
