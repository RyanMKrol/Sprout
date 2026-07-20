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
    /// One pending plant in the basket: a chosen species, its (editable) nickname,
    /// and the (editable) Phosphor icon it'll be created with — T023 lets the icon
    /// picker be opened on a still-pending entry, persisting the choice into the
    /// entry so it's carried through to the plant `commit()` creates.
    struct Entry: Identifiable, Equatable {
        let id: UUID
        var species: String
        var nickname: String
        var icon: PlantIcon
        /// Index into `PlantTokenPalette.duos` for this entry's token colour. Starts
        /// derived from `id` (a stable first render) and is rerolled by `reroll`.
        var paletteIndex: Int

        init(id: UUID = UUID(), species: String, nickname: String, icon: PlantIcon? = nil, paletteIndex: Int? = nil) {
            self.id = id
            self.species = species
            self.nickname = nickname
            self.icon = icon ?? PlantIcon.default(forSpecies: species)
            self.paletteIndex = paletteIndex ?? PlantTokenPalette.indexOfDuo(for: id)
        }

        /// This entry's token colour, resolved from its stored `paletteIndex`.
        var duo: PlantTokenPalette.Duo { PlantTokenPalette.duo(atIndex: paletteIndex) }
    }

    /// The two ordered stages of the **room-first** add flow (T221): first choose or
    /// create the room the batch lives in, then add the plants into it.
    enum Step: Equatable { case room, plants }

    /// Which step the flow is on. Starts on `.room` — a room is chosen/created before
    /// any plant is added, so every committed plant inherits it.
    @Published private(set) var step: Step = .room

    /// The pending plants, in the order they'll be created.
    @Published private(set) var basket: [Entry] = []
    /// The species-picker search query; filters `speciesResults`.
    @Published var speciesQuery: String = ""

    /// The room all basket plants are added to (T213's picker sets this). `nil` → no
    /// room; a neutral initial cadence. Drives both `roomID` and the initial schedule.
    @Published var selectedRoom: Room?
    /// Rooms available to assign the batch to (loaded from the repository).
    @Published private(set) var availableRooms: [Room] = []

    private let repository: PlantRepository
    private let careDatabase: CareDatabase
    private var nicknameProvider: RandomNicknameProvider<AnyRandomNumberGenerator>
    /// The view model's own handle on the injected generator, used by `reroll` to
    /// pick a random icon + palette colour. Seeded from the SAME injected `rng` as
    /// the nickname provider (not a fresh `SystemRandomNumberGenerator`), so a
    /// fixed-seed run stays fully deterministic in tests and DemoSeed.
    private var rng: AnyRandomNumberGenerator
    private let schedule = ScheduleEngine()

    init(
        repository: PlantRepository,
        careDatabase: CareDatabase,
        rng: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.repository = repository
        self.careDatabase = careDatabase
        let anyRng = AnyRandomNumberGenerator(rng)
        self.nicknameProvider = RandomNicknameProvider(rng: anyRng)
        self.rng = anyRng
    }

    /// Load the rooms available for assignment (call on appear).
    func loadRooms() {
        availableRooms = (try? repository.allRooms()) ?? []
    }

    // MARK: - Room step (T221 — room-first ordering)

    /// Choose the room (or `nil` for no room) the whole batch lives in and advance to
    /// the plant-adding step. The selection drives both each plant's `roomID` and its
    /// initial cadence at `commit()`.
    func chooseRoom(_ room: Room?) {
        selectedRoom = room
        step = .plants
    }

    /// Create a new room from the editor inputs, select it for the batch, and advance
    /// to the plant-adding step. Reuses the same two-input light model as the Rooms
    /// editor (T220). Blank names are ignored (the flow stays on the room step).
    func createRoom(name: String, directSun: LightLevel, indirectSun: LightLevel, humidity: RoomHumidity) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let room = Room(name: trimmed.capitalisedWords, directSun: directSun, indirectSun: indirectSun, humidity: humidity)
        try? repository.addRoom(room)
        loadRooms()
        chooseRoom(room)
    }

    /// Step back to room selection (e.g. to pick a different room) without losing the
    /// basket already assembled.
    func backToRoomStep() {
        step = .room
    }

    // MARK: - Species picker (sourced from the care database)

    /// The species matching `speciesQuery` — the picker's rows (full list when empty).
    var speciesResults: [CareProfile] { careDatabase.search(speciesQuery) }

    // MARK: - Basket editing

    /// Drop one plant of `profile` into the basket with a fresh unique random name,
    /// a random token colour, and a random glyph. Colour and glyph are drawn from the
    /// injected RNG and differ from the previously-added entry's where the pool allows
    /// — so a batch gets varied, non-repeating looks instead of a hash of the plant id
    /// (which clustered into duplicate colours). Adding the same species again is
    /// allowed and yields a distinct name/colour/glyph.
    func add(_ profile: CareProfile) {
        let name = nicknameProvider.next(avoiding: takenNames())
        let previous = basket.last
        basket.append(Entry(
            species: profile.species,
            nickname: name,
            icon: randomIcon(avoiding: previous?.icon),
            paletteIndex: randomPaletteIndex(avoiding: previous?.paletteIndex)
        ))
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

    /// Reroll an entry's name **and** its look — a fresh unique random nickname, a new
    /// token glyph, and a new token colour — in one tap, all drawn from the injected
    /// seedable RNG. The current name stays in the avoided set (it's still in the
    /// basket), so the reroll yields a *different* name while the pool has room; the
    /// icon and colour likewise differ from their current value where the pool allows.
    /// The rerolled colour is basket-preview-only (it is not persisted onto the
    /// created plant — see T059).
    func reroll(_ entry: Entry) {
        guard let i = basket.firstIndex(where: { $0.id == entry.id }) else { return }
        basket[i].nickname = nicknameProvider.next(avoiding: takenNames())
        basket[i].icon = randomIcon(avoiding: basket[i].icon)
        basket[i].paletteIndex = randomPaletteIndex(avoiding: basket[i].paletteIndex)
    }

    /// A random `PlantIcon` drawn from the injected RNG, differing from `avoiding`
    /// where the pool allows (falls back to any icon when `avoiding` is nil / the pool
    /// is a singleton).
    private func randomIcon(avoiding: PlantIcon?) -> PlantIcon {
        let options = PlantIcon.allCases.filter { $0 != avoiding }
        return options.randomElement(using: &rng) ?? avoiding ?? PlantIcon.allCases[0]
    }

    /// A random palette index drawn from the injected RNG, differing from `avoiding`
    /// where the pool allows.
    private func randomPaletteIndex(avoiding: Int?) -> Int {
        let options = PlantTokenPalette.duos.indices.filter { $0 != avoiding }
        return options.randomElement(using: &rng) ?? avoiding ?? 0
    }

    /// Set the icon a still-pending basket entry will be created with (the icon
    /// picker opened from a basket row's token, T023).
    func updateIcon(_ icon: PlantIcon, for entry: Entry) {
        guard let i = basket.firstIndex(where: { $0.id == entry.id }) else { return }
        basket[i].icon = icon
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
    /// name. Each plant is assigned to `selectedRoom` and given an **initial cadence**
    /// from its species and the room's environment factor (anchored at `now`, assuming
    /// a freshly-added plant was just watered). Clears the basket on success.
    /// - Throws: `BasketAddError.incomplete` if `canCommit` is `false`, or a
    ///   `PlantRepositoryError` from the store.
    @discardableResult
    func commit(now: Date = Date()) throws -> [Plant] {
        guard canCommit else { throw BasketAddError.incomplete }
        let factor = RoomEnvironment.factor(for: selectedRoom)
        var taken = takenNames()
        var created: [Plant] = []
        for entry in basket {
            let trimmed = entry.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? nicknameProvider.next(avoiding: taken) : trimmed
            taken.insert(name)

            // Seed an initial schedule from the species cadence + room environment.
            var nextDue: Date?
            if let profile = careDatabase.profile(forSpecies: entry.species) {
                nextDue = schedule.nextDue(for: profile, adj: Plant.defaultAdj, lastWatered: now, weatherFactor: factor)
            }
            let plant = Plant(
                nickname: name,
                species: entry.species,
                lastWatered: now,
                nextDue: nextDue,
                roomID: selectedRoom?.id,
                icon: entry.icon
            )
            try repository.add(plant)
            created.append(plant)
        }
        basket = []
        return created
    }
}
