import XCTest
@testable import Sprout

final class DueChipTests: XCTestCase {
    func testLabels() {
        XCTAssertEqual(DueStatus.overdue(days: 1).label, "Overdue 1d")
        XCTAssertEqual(DueStatus.overdue(days: 3).label, "Overdue 3d")
        XCTAssertEqual(DueStatus.dueToday.label, "Due today")
        XCTAssertEqual(DueStatus.due(inDays: 5).label, "Due in 5d")
        XCTAssertEqual(DueStatus.unscheduled.label, "No schedule")
    }
}
