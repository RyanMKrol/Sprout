import XCTest
@testable import Sprout

/// Unit tests for the My Plants list view model (T006): the empty → empty-state
/// transition, due-order sorting, and the pure `DueStatus` classification/labels.
/// Backed by a fresh in-memory `PlantRepository` (via `PlantStore.inMemory()`) so
/// the view model is exercised through its real persistence boundary.
@MainActor
final class PlantListViewModelTests: XCTestCase {
    private var repo: PlantRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
    }

    override func tearDownWithError() throws {
        repo = nil
        try super.tearDownWithError()
    }

    /// A fixed reference instant (2001-01-10 00:00 UTC) so relative due text is
    /// deterministic regardless of when the test runs.
    private let now = Date(timeIntervalSinceReferenceDate: 9 * 86_400)

    private func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: now)!
    }

    // MARK: empty state

    func testEmptyRepositoryYieldsEmptyState() {
        let vm = PlantListViewModel(repository: repo)
        vm.load(now: now)
        XCTAssertTrue(vm.isEmpty)
        XCTAssertTrue(vm.items.isEmpty)
    }

    // MARK: due-order

    func testSeededPlantsAreOrderedSoonestDueFirst() throws {
        // Inserted out of due-order; nicknames also non-alphabetical.
        try repo.add(Plant(nickname: "Spike", species: "Snake Plant", nextDue: day(6)))
        try repo.add(Plant(nickname: "Lily", species: "Peace Lily", nextDue: day(-1)))
        try repo.add(Plant(nickname: "Monty", species: "Monstera deliciosa", nextDue: day(0)))

        let vm = PlantListViewModel(repository: repo)
        vm.load(now: now)

        XCTAssertFalse(vm.isEmpty)
        XCTAssertEqual(vm.items.map(\.nickname), ["Lily", "Monty", "Spike"])
        XCTAssertEqual(vm.items.map(\.due), [.overdue(days: 1), .dueToday, .due(days: 6)])
    }

    func testUnscheduledPlantsSortLastThenAlphabetical() throws {
        try repo.add(Plant(nickname: "Zara", species: "Pothos", nextDue: nil))
        try repo.add(Plant(nickname: "Aida", species: "Boston Fern", nextDue: nil))
        try repo.add(Plant(nickname: "Monty", species: "Monstera deliciosa", nextDue: day(2)))

        let vm = PlantListViewModel(repository: repo)
        vm.load(now: now)

        XCTAssertEqual(vm.items.map(\.nickname), ["Monty", "Aida", "Zara"])
        XCTAssertEqual(vm.items.last?.due, .unscheduled)
    }

    func testEqualDueDatesBreakTiesByNickname() throws {
        try repo.add(Plant(nickname: "Bob", species: "Pothos", nextDue: day(1)))
        try repo.add(Plant(nickname: "Ana", species: "Pothos", nextDue: day(1)))

        let vm = PlantListViewModel(repository: repo)
        vm.load(now: now)

        XCTAssertEqual(vm.items.map(\.nickname), ["Ana", "Bob"])
    }

    // MARK: DueStatus classification

    func testDueStatusClassification() {
        XCTAssertEqual(DueStatus(nextDue: nil, now: now), .unscheduled)
        XCTAssertEqual(DueStatus(nextDue: day(0), now: now), .dueToday)
        XCTAssertEqual(DueStatus(nextDue: day(3), now: now), .due(days: 3))
        XCTAssertEqual(DueStatus(nextDue: day(-2), now: now), .overdue(days: 2))
    }

    func testDueStatusIgnoresTimeOfDay() {
        // A nextDue later *today* is still "due today", not "due in 1 day".
        let laterToday = now.addingTimeInterval(20 * 3_600)
        XCTAssertEqual(DueStatus(nextDue: laterToday, now: now), .dueToday)
    }

    func testDueStatusLabels() {
        XCTAssertEqual(DueStatus.unscheduled.label, "No schedule")
        XCTAssertEqual(DueStatus.dueToday.label, "Due today")
        XCTAssertEqual(DueStatus.due(days: 1).label, "Due in 1 day")
        XCTAssertEqual(DueStatus.due(days: 3).label, "Due in 3 days")
        XCTAssertEqual(DueStatus.overdue(days: 1).label, "Overdue by 1 day")
        XCTAssertEqual(DueStatus.overdue(days: 4).label, "Overdue by 4 days")
    }

    func testNeedsWaterFlag() {
        XCTAssertTrue(DueStatus.dueToday.needsWater)
        XCTAssertTrue(DueStatus.overdue(days: 1).needsWater)
        XCTAssertFalse(DueStatus.due(days: 2).needsWater)
        XCTAssertFalse(DueStatus.unscheduled.needsWater)
    }
}
