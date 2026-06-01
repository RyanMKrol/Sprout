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

/// A curated, balanced pool of common, family-friendly English first names used as
/// the default for auto-assigning plant nicknames. Split by gender so the balance is
/// testable; `all` is the union the provider draws from (≈140 / ≈140 / 20 = 300).
enum EnglishNames {
    static let girls: [String] = [
        "Abigail", "Ada", "Adeline", "Agnes", "Alice", "Amber", "Amelia", "Anna", "Annabel", "Annie",
        "Arabella", "Aria", "Ava", "Beatrice", "Bella", "Bonnie", "Bridget", "Camilla", "Caroline", "Catherine",
        "Cecilia", "Charlotte", "Chloe", "Clara", "Claudia", "Connie", "Cora", "Daisy", "Daphne", "Darcey",
        "Delilah", "Diana", "Dorothy", "Edith", "Eleanor", "Eliza", "Elizabeth", "Ella", "Ellie", "Eloise",
        "Elsie", "Emily", "Emma", "Erin", "Esme", "Estella", "Eva", "Evelyn", "Faith", "Felicity",
        "Fleur", "Florence", "Frances", "Freya", "Georgia", "Georgina", "Grace", "Gracie", "Greta", "Hannah",
        "Harriet", "Hattie", "Heidi", "Helena", "Henrietta", "Hermione", "Hester", "Holly", "Imogen", "Iris",
        "Isabel", "Isabella", "Isla", "Ivy", "Jane", "Jemima", "Jennifer", "Jessica", "Josephine", "Julia",
        "Juliet", "Katherine", "Lara", "Laura", "Lauren", "Leah", "Lilian", "Lily", "Lola", "Lottie",
        "Louisa", "Lucy", "Lydia", "Mabel", "Madeleine", "Maeve", "Maisie", "Margaret", "Margot", "Martha",
        "Mary", "Matilda", "Maya", "Mia", "Millie", "Minnie", "Miriam", "Molly", "Nancy", "Naomi",
        "Nell", "Nina", "Nora", "Octavia", "Olivia", "Ophelia", "Pearl", "Penelope", "Penny", "Phoebe",
        "Polly", "Poppy", "Primrose", "Rachel", "Rebecca", "Rosa", "Rose", "Rosemary", "Ruby", "Sadie",
        "Sarah", "Scarlett", "Sophia", "Sophie", "Stella", "Tabitha", "Tessa", "Thea", "Tilly", "Verity",
        "Victoria", "Violet", "Vivienne", "Willa", "Winifred", "Winnie", "Zara", "Zoe",
    ]

    static let boys: [String] = [
        "Aaron", "Adam", "Albert", "Alexander", "Alfie", "Alfred", "Andrew", "Angus", "Anthony", "Archie",
        "Arlo", "Arthur", "Austin", "Barnaby", "Benedict", "Benjamin", "Bertie", "Caleb", "Charlie", "Christopher",
        "Clement", "Colin", "Connor", "Daniel", "David", "Dexter", "Dominic", "Douglas", "Duncan", "Edmund",
        "Edward", "Edwin", "Elliot", "Ellis", "Ernest", "Ethan", "Ezra", "Felix", "Finlay", "Finn",
        "Francis", "Frank", "Franklin", "Fraser", "Freddie", "Frederick", "Gabriel", "Gareth", "George", "Giles",
        "Graham", "Gregory", "Hamish", "Harold", "Harrison", "Harry", "Harvey", "Henry", "Hugh", "Hugo",
        "Humphrey", "Isaac", "Jack", "Jacob", "James", "Jasper", "Jeremy", "Jerome", "Jesse", "Joel",
        "John", "Jonah", "Jonathan", "Joseph", "Joshua", "Julian", "Kit", "Laurence", "Leo", "Leonard",
        "Lewis", "Liam", "Louie", "Louis", "Lucas", "Luke", "Magnus", "Malcolm", "Marcus", "Martin",
        "Mason", "Matthew", "Maurice", "Max", "Maxwell", "Michael", "Miles", "Monty", "Nathaniel", "Nicholas",
        "Noah", "Oliver", "Ollie", "Oscar", "Otto", "Owen", "Patrick", "Paul", "Percy", "Peter",
        "Philip", "Quentin", "Ralph", "Raymond", "Reuben", "Richard", "Robert", "Rory", "Rufus", "Rupert",
        "Samuel", "Sebastian", "Seth", "Simon", "Solomon", "Stanley", "Stephen", "Teddy", "Theo", "Theodore",
        "Thomas", "Timothy", "Tobias", "Toby", "Tristan", "Victor", "Vincent", "Walter", "William", "Zachary",
    ]

    /// Nature-leaning unisex names that suit plants and aren't in either gendered list.
    static let unisex: [String] = [
        "Ash", "Basil", "Bay", "Briar", "Clover", "Fern", "Juniper", "Laurel", "Linden", "Moss",
        "Olive", "Reed", "River", "Robin", "Rowan", "Sage", "Sorrel", "Sunny", "Vale", "Willow",
    ]

    /// The full pool the provider draws from.
    static let all: [String] = girls + boys + unisex
}
