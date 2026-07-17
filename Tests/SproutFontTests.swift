import XCTest
import UIKit

final class SproutFontTests: XCTestCase {
    func testBricolageGrotesque600Registers() {
        let font = UIFont(name: "BricolageGrotesque96ptExtraBold-SemiBold", size: 12)
        XCTAssertNotNil(font)
    }

    func testBricolageGrotesque700Registers() {
        let font = UIFont(name: "BricolageGrotesque96ptExtraBold-Bold", size: 12)
        XCTAssertNotNil(font)
    }

    func testBricolageGrotesque800Registers() {
        let font = UIFont(name: "BricolageGrotesque96ptExtraBold-ExtraBold", size: 12)
        XCTAssertNotNil(font)
    }

    func testHankenGrotesk500Registers() {
        let font = UIFont(name: "HankenGrotesk-Medium", size: 12)
        XCTAssertNotNil(font)
    }

    func testHankenGrotesk500ItalicRegisters() {
        let font = UIFont(name: "HankenGrotesk-MediumItalic", size: 12)
        XCTAssertNotNil(font)
    }

    func testHankenGrotesk600Registers() {
        let font = UIFont(name: "HankenGrotesk-SemiBold", size: 12)
        XCTAssertNotNil(font)
    }

    func testHankenGrotesk700Registers() {
        let font = UIFont(name: "HankenGrotesk-Bold", size: 12)
        XCTAssertNotNil(font)
    }

    func testHankenGroteskItalicRegisters() {
        let font = UIFont(name: "HankenGrotesk-Italic", size: 12)
        XCTAssertNotNil(font)
    }

    func testHankenGroteskRegularRegisters() {
        let font = UIFont(name: "HankenGrotesk-Regular", size: 12)
        XCTAssertNotNil(font)
    }
}
