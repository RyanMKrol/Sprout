import Foundation

/// Type-erased `RandomNumberGenerator` so `BasketAddViewModel` (and its
/// `RandomNicknameProvider`) need not be generic over the RNG — production injects
/// `SystemRandomNumberGenerator`, tests/DemoSeed inject a `SeededRandomNumberGenerator`.
struct AnyRandomNumberGenerator: RandomNumberGenerator {
    private var base: any RandomNumberGenerator
    init(_ base: any RandomNumberGenerator) { self.base = base }
    mutating func next() -> UInt64 { base.next() }
}

/// Why a basket commit could not proceed. Structured so the view and tests assert
/// the *kind* of problem.
enum BasketAddError: Error, Equatable {
    /// The basket is empty, or an entry references a species not in the care DB.
    case incomplete
}

/// Drives the **basket add** flow (T203) — the fast, batch replacement for the
/// single Add form. The user taps species from the care database to drop plants
/// into a basket; each gets an auto-assigned random English nickname (T202),
/// editable inline and re-rollable, unique across existing + in-basket names where
/// possible. Committing inserts every basket entry via the repository and returns
/// the created plants **in basket order** — the order the photo flow (T206+) walks.
///
/// All logic lives here behind a testable surface; the view is pure presentation.
@MainActor
final class BasketAddViewModel: ObservableObject {
    /// One pending plant in the basket: a chosen species and its (editable) nickname.
    struct Entry: Identifiable, Equatable {
        let id: UUID
        var species: String
        var nickname: String

        init(id: UUID = UUID(), species: String, nickname: String) {
            self.id = id
            self.species = species
            self.nickname = nickname
        }
    }

    /// The pending plants, in the order they'll be created.
    @Published private(set) var basket: [Entry] = []
    /// The species-picker search query; filters `speciesResults`.
    @Published var speciesQuery: String = ""

    private let repository: PlantRepository
    private let careDatabase: CareDatabase
    private var nicknameProvider: RandomNicknameProvider<AnyRandomNumberGenerator>

    init(
        repository: PlantRepository,
        careDatabase: CareDatabase,
        rng: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.repository = repository
        self.careDatabase = careDatabase
        self.nicknameProvider = RandomNicknameProvider(rng: AnyRandomNumberGenerator(rng))
    }

    // MARK: - Species picker (sourced from the care database)

    /// The species matching `speciesQuery` — the picker's rows (full list when empty).
    var speciesResults: [CareProfile] { careDatabase.search(speciesQuery) }

    // MARK: - Basket editing

    /// Drop one plant of `profile` into the basket with a fresh unique random name.
    /// Adding the same species again is allowed and yields a distinct name.
    func add(_ profile: CareProfile) {
        let name = nicknameProvider.next(avoiding: takenNames())
        basket.append(Entry(species: profile.species, nickname: name))
    }

    /// Remove a basket entry.
    func remove(_ entry: Entry) {
        basket.removeAll { $0.id == entry.id }
    }

    /// Remove entries at list offsets (for swipe-to-delete).
    func remove(atOffsets offsets: IndexSet) {
        basket.remove(atOffsets: offsets)
    }

    /// Rename an entry inline. Blank names are allowed in-flight (the user may be
    /// mid-edit); a blank is resolved to a fresh random name at `commit()`.
    func rename(_ entry: Entry, to newName: String) {
        guard let i = basket.firstIndex(where: { $0.id == entry.id }) else { return }
        basket[i].nickname = newName
    }

    /// Reassign a fresh unique random name to an entry. The current name stays in
    /// the avoided set (it's still in the basket), so the reroll yields a *different*
    /// name while the pool has room.
    func reroll(_ entry: Entry) {
        guard let i = basket.firstIndex(where: { $0.id == entry.id }) else { return }
        basket[i].nickname = nicknameProvider.next(avoiding: takenNames())
    }

    /// Existing plant nicknames ∪ current basket nicknames — what auto-naming avoids.
    private func takenNames() -> Set<String> {
        let existing = (try? repository.allPlants())?.map(\.nickname) ?? []
        return Set(existing).union(basket.map(\.nickname))
    }

    // MARK: - Commit

    /// `true` when the basket is non-empty and every entry resolves to a real
    /// care-database species — the guard that keeps a commit from referencing an
    /// unknown species.
    var canCommit: Bool {
        !basket.isEmpty && basket.allSatisfy { careDatabase.profile(forSpecies: $0.species) != nil }
    }

    /// Number of plants the basket will create (for the "Add N plants" button).
    var commitCount: Int { basket.count }

    /// Insert every basket entry via the repository and return the created plants
    /// **in basket order**. A blank nickname is resolved to a fresh unique random
    /// name. Clears the basket on success.
    /// - Throws: `BasketAddError.incomplete` if `canCommit` is `false`, or a
    ///   `PlantRepositoryError` from the store.
    @discardableResult
    func commit() throws -> [Plant] {
        guard canCommit else { throw BasketAddError.incomplete }
        var taken = takenNames()
        var created: [Plant] = []
        for entry in basket {
            let trimmed = entry.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? nicknameProvider.next(avoiding: taken) : trimmed
            taken.insert(name)
            let plant = Plant(nickname: name, species: entry.species)
            try repository.add(plant)
            created.append(plant)
        }
        basket = []
        return created
    }
}
