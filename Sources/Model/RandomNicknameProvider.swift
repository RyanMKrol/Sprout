import Foundation

/// A small, deterministic `RandomNumberGenerator` (SplitMix64). Seeded with a
/// fixed value it always produces the same sequence — used by tests to assert
/// deterministic naming, and by `DemoSeed` so screenshot names are stable.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Hands out random English first names for auto-naming plants in the basket
/// add flow (T203). Pure and value-type; the randomness source is injected so
/// production uses `SystemRandomNumberGenerator` and tests use a seeded one.
///
/// `next(avoiding:)` returns a name not already taken **where possible**; once
/// the curated pool is exhausted it falls back to suffixing ("Alice 2") so it
/// never blocks the basket or loops forever.
struct RandomNicknameProvider<RNG: RandomNumberGenerator> {
    private let names: [String]
    private var rng: RNG

    init(names: [String] = EnglishNames.all, rng: RNG) {
        // Never allow an empty pool — fall back to a single generic stem.
        self.names = names.isEmpty ? ["Plant"] : names
        self.rng = rng
    }

    /// A random name not in `taken` (compared case-insensitively). When every
    /// pool name is taken, returns a suffixed variant ("<Name> 2", "<Name> 3", …)
    /// that isn't in `taken`.
    mutating func next(avoiding taken: Set<String>) -> String {
        let takenLower = Set(taken.map { $0.lowercased() })
        let available = names.filter { !takenLower.contains($0.lowercased()) }
        if let pick = available.randomElement(using: &rng) {
            return pick
        }
        let base = names.randomElement(using: &rng) ?? "Plant"
        var suffix = 2
        while takenLower.contains("\(base) \(suffix)".lowercased()) { suffix += 1 }
        return "\(base) \(suffix)"
    }
}

/// A curated list of common, family-friendly English first names (mixed) used as
/// the default pool for auto-assigning plant nicknames.
enum EnglishNames {
    static let all: [String] = [
        // girls'
        "Alice", "Amelia", "Ava", "Beatrice", "Bella", "Charlotte", "Chloe", "Daisy",
        "Eleanor", "Eliza", "Ella", "Emily", "Emma", "Evelyn", "Florence", "Freya",
        "Grace", "Hannah", "Harriet", "Hazel", "Holly", "Imogen", "Isabella", "Isla",
        "Ivy", "Jessica", "Jasmine", "Lara", "Lily", "Lottie", "Lucy", "Maisie",
        "Martha", "Matilda", "Maya", "Mia", "Millie", "Molly", "Nancy", "Nora",
        "Olivia", "Penny", "Phoebe", "Poppy", "Rose", "Ruby", "Sophie", "Tilly",
        "Violet", "Willow", "Winnie", "Zara",
        // boys'
        "Albert", "Alexander", "Alfie", "Archie", "Arthur", "Benjamin", "Charlie",
        "Daniel", "Dexter", "Edward", "Elliot", "Ethan", "Felix", "Finley", "Freddie",
        "George", "Harrison", "Harry", "Henry", "Hugo", "Isaac", "Jack", "Jacob",
        "James", "Jasper", "Joseph", "Leo", "Louie", "Lucas", "Max", "Monty",
        "Noah", "Oliver", "Oscar", "Otto", "Reuben", "Rory", "Rufus", "Samuel",
        "Sebastian", "Stanley", "Teddy", "Theo", "Thomas", "Toby", "William",
        // unisex / nature-leaning, fitting for plants
        "Ash", "Basil", "Briar", "Clover", "Fern", "Heather", "Juniper",
        "Laurel", "Olive", "River", "Robin", "Sage", "Sorrel", "Sunny",
    ]
}
