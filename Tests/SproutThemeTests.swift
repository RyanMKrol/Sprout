import XCTest
import UIKit
import SwiftUI
@testable import Sprout

final class SproutThemeTests: XCTestCase {
    // MARK: Radius

    func testRadiusValuesMatchSpec() {
        XCTAssertEqual(SproutTheme.Radius.sheet, 40)
        XCTAssertEqual(SproutTheme.Radius.hero, 28)
        XCTAssertEqual(SproutTheme.Radius.bento, 24)
        XCTAssertEqual(SproutTheme.Radius.dialog, 22)
        XCTAssertEqual(SproutTheme.Radius.row, 20)
        XCTAssertEqual(SproutTheme.Radius.field, 18)
        XCTAssertEqual(SproutTheme.Radius.button, 16)
        XCTAssertEqual(SproutTheme.Radius.segmented, 15)
        XCTAssertEqual(SproutTheme.Radius.pill, 11)
        XCTAssertEqual(SproutTheme.Radius.chip, 10)
    }

    // MARK: Colors

    func testPaperResolvesToExpectedSRGB() {
        assertColor(SproutTheme.paper, red: 0.957, green: 0.945, blue: 0.906)
    }

    func testInkResolvesToExpectedSRGB() {
        assertColor(SproutTheme.ink, red: 0.137, green: 0.157, blue: 0.129)
    }

    func testBrandGreenResolvesToExpectedSRGB() {
        assertColor(SproutTheme.brandGreen, red: 0.184, green: 0.420, blue: 0.298)
    }

    private func assertColor(_ color: Color, red: CGFloat, green: CGFloat, blue: CGFloat, tolerance: CGFloat = 0.01) {
        let uiColor = UIColor(color)
        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        uiColor.getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha)

        XCTAssertEqual(actualRed, red, accuracy: tolerance)
        XCTAssertEqual(actualGreen, green, accuracy: tolerance)
        XCTAssertEqual(actualBlue, blue, accuracy: tolerance)
    }
}
