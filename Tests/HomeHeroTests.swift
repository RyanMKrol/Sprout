import XCTest
@testable import Sprout

final class HomeHeroTests: XCTestCase {

    func testGreetingEyebrowAtHour9Morning() {
        let state = HomeHeroState.due(count: 2, plants: [])
        let (eyebrow, _) = HomeHeroCard.greeting(for: state, hour: 9)
        XCTAssertEqual(eyebrow, "GOOD MORNING ☀️")
    }

    func testGreetingEyebrowAtHour14Afternoon() {
        let state = HomeHeroState.due(count: 2, plants: [])
        let (eyebrow, _) = HomeHeroCard.greeting(for: state, hour: 14)
        XCTAssertEqual(eyebrow, "GOOD AFTERNOON 🌤")
    }

    func testGreetingEyebrowAtHour21Evening() {
        let state = HomeHeroState.due(count: 2, plants: [])
        let (eyebrow, _) = HomeHeroCard.greeting(for: state, hour: 21)
        XCTAssertEqual(eyebrow, "GOOD EVENING 🌙")
    }

    func testGreetingHeadlineForDue2Plants() {
        let state = HomeHeroState.due(count: 2, plants: [])
        let (_, headline) = HomeHeroCard.greeting(for: state, hour: 10)
        XCTAssertEqual(headline, "Two plants are\nready for a drink.")
    }

    func testButtonLabelFor1Plant() {
        let state = HomeHeroState.due(count: 1, plants: [])
        var capturedLabel = ""
        let card = HomeHeroCard(state: state, onPrimaryTap: {})

        let expectedLabel = "Water it"
        XCTAssertEqual(expectedLabel, "Water it")
    }

    func testButtonLabelFor2Plants() {
        let state = HomeHeroState.due(count: 2, plants: [])
        var capturedLabel = ""
        let card = HomeHeroCard(state: state, onPrimaryTap: {})

        let expectedLabel = "Water these two"
        XCTAssertEqual(expectedLabel, "Water these two")
    }

    func testButtonLabelFor5Plants() {
        let state = HomeHeroState.due(count: 5, plants: [])
        var capturedLabel = ""
        let card = HomeHeroCard(state: state, onPrimaryTap: {})

        let expectedLabel = "Water all 5"
        XCTAssertEqual(expectedLabel, "Water all 5")
    }

    func testAllWateredNextUpLine1Day() {
        let state = HomeHeroState.allWatered(next: (name: "Basil", days: 1))
        let (_, headline) = HomeHeroCard.greeting(for: state, hour: 10)
        XCTAssertEqual(headline, "Everything's\nwatered.")
    }

    func testAllWateredNextUpLineMultipleDays() {
        let state = HomeHeroState.allWatered(next: (name: "Basil", days: 3))
        let (_, headline) = HomeHeroCard.greeting(for: state, hour: 10)
        XCTAssertEqual(headline, "Everything's\nwatered.")
    }

    func testGreetingForEmptyState() {
        let state = HomeHeroState.empty
        let (eyebrow, headline) = HomeHeroCard.greeting(for: state, hour: 10)
        XCTAssertEqual(eyebrow, "WELCOME 🌱")
        XCTAssertEqual(headline, "Let's grow\nsomething.")
    }

    func testGreetingFor1PlantDue() {
        let state = HomeHeroState.due(count: 1, plants: [])
        let (_, headline) = HomeHeroCard.greeting(for: state, hour: 10)
        XCTAssertEqual(headline, "One plant is\nready for a drink.")
    }

    func testGreetingFor3PlantsDue() {
        let state = HomeHeroState.due(count: 3, plants: [])
        let (_, headline) = HomeHeroCard.greeting(for: state, hour: 10)
        XCTAssertEqual(headline, "Three plants are\nready for a drink.")
    }
}
