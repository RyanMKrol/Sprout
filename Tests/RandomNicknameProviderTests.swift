import XCTest
@testable import Sprout

/// Unit tests for `RandomNicknameProvider` — deterministic, unique-where-possible
/// auto-naming for the basket add flow.
final class RandomNicknameProviderTests: XCTestCase {

    /// Draw `count` names, accumulating each into the `taken` set (mirrors how the
    /// basket assigns one unique name per entry).
    private func draw<R: RandomNumberGenerator>(
        _ count: Int,
        from provider: inout RandomNicknameProvider<R>
    ) -> [String] {
        var taken = Set<String>()
        var out: [String] = []
        for _ in 0..<count {
            let name = provider.next(avoiding: taken)
            out.append(name)
            taken.insert(name)
        }
        return out
    }

    func testSeededRNGIsDeterministic() {
        var a = RandomNicknameProvider(rng: SeededRandomNumberGenerator(seed: 42))
        var b = RandomNicknameProvider(rng: SeededRandomNumberGenerator(seed: 42))
        XCTAssertEqual(draw(10, from: &a), draw(10, from: &b))
    }

    func testDifferentSeedsDiffer() {
        var a = RandomNicknameProvider(rng: SeededRandomNumberGenerator(seed: 1))
        var b = RandomNicknameProvider(rng: SeededRandomNumberGenerator(seed: 999))
        // Overwhelmingly likely to differ across 12 draws from a 100+ name pool.
        XCTAssertNotEqual(draw(12, from: &a), draw(12, from: &b))
    }

    func testNamesAreUniqueWhilePoolLasts() {
        var provider = RandomNicknameProvider(rng: SeededRandomNumberGenerator(seed: 7))
        let drawn = draw(40, from: &provider)
        XCTAssertEqual(Set(drawn).count, drawn.count, "no repeats while the pool has room")
    }

    func testNeverReturnsANameInAvoidingSet() {
        var provider = RandomNicknameProvider(
            names: ["Alice", "Ben"],
            rng: SeededRandomNumberGenerator(seed: 3)
        )
        XCTAssertEqual(provider.next(avoiding: ["Alice"]), "Ben")
        // Case-insensitive: "alice" should also block "Alice".
        XCTAssertEqual(provider.next(avoiding: ["alice"]), "Ben")
    }

    func testPoolExhaustionFallsBackToSuffixes() {
        var provider = RandomNicknameProvider(
            names: ["Alice", "Ben"],
            rng: SeededRandomNumberGenerator(seed: 5)
        )
        let drawn = draw(6, from: &provider)
        XCTAssertEqual(Set(drawn).count, 6, "fallback names stay unique")
        // First two exhaust the pool (some order); the rest are suffixed variants.
        XCTAssertEqual(Set(drawn.prefix(2)), ["Alice", "Ben"])
        XCTAssertTrue(drawn.dropFirst(2).allSatisfy { $0.contains("Alice ") || $0.contains("Ben ") })
    }

    func testEmptyPoolDoesNotCrash() {
        var provider = RandomNicknameProvider(names: [], rng: SeededRandomNumberGenerator(seed: 1))
        let drawn = draw(3, from: &provider)
        XCTAssertEqual(drawn.count, 3)
        XCTAssertEqual(Set(drawn).count, 3)
    }

    func testDefaultPoolIsLargeAndUnique() {
        XCTAssertGreaterThanOrEqual(EnglishNames.all.count, 300)
        XCTAssertEqual(Set(EnglishNames.all).count, EnglishNames.all.count, "no duplicate names")
        XCTAssertEqual(EnglishNames.all.count,
                       EnglishNames.girls.count + EnglishNames.boys.count + EnglishNames.unisex.count,
                       "all is the union of the sub-lists")
    }

    func testNamePoolIsGenderBalanced() {
        let g = EnglishNames.girls.count
        let b = EnglishNames.boys.count
        // Within 10% of the larger list — neither gender dominates.
        XCTAssertLessThanOrEqual(Double(abs(g - b)) / Double(max(g, b)), 0.10,
                                 "girls (\(g)) and boys (\(b)) should be roughly balanced")
    }
}
