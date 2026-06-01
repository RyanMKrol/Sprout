import Foundation

/// Why a care-database load or validation failed. A structured error (not a string)
/// so the loader, the unit tests, and every T101–T130 batch can assert the *kind*
/// of problem — a malformed record vs. a duplicate species vs. a missing resource.
enum CareDatabaseError: Error, Equatable {
    /// A record fails the single-record invariant (`min ≤ base ≤ max`, positive,
    /// non-blank species) — see `CareProfile.isValid`.
    case invalidRecord(species: String)
    /// Two records share the same (case-insensitively normalised) species name.
    case duplicateSpecies(String)
    /// The bundled `care_database.json` resource could not be located.
    case resourceMissing(String)
}

/// The reusable dataset-level validator — used here *and* by every Phase 6 batch
/// (T101–T130) before it appends new plants. It enforces the two rules the
/// single-record `CareProfile.isValid` cannot: every record is individually valid,
/// **and** species names are unique across the whole dataset.
enum CareDatabaseValidator {
    /// Throws the first problem found, or returns normally if `profiles` is a valid
    /// dataset. Order-independent: a duplicate is reported against the second
    /// occurrence in iteration order.
    static func validate(_ profiles: [CareProfile]) throws {
        var seen = Set<String>()
        for profile in profiles {
            guard profile.isValid else {
                throw CareDatabaseError.invalidRecord(species: profile.species)
            }
            let key = normalisedKey(profile.species)
            guard seen.insert(key).inserted else {
                throw CareDatabaseError.duplicateSpecies(profile.species)
            }
        }
    }

    /// The uniqueness key for a species: trimmed and case-folded, so "Pothos" and
    /// " pothos " collide. This is the same notion of "same plant" the picker uses.
    static func normalisedKey(_ species: String) -> String {
        species.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// The bundled, validated care database: the in-memory `[CareProfile]` decoded from
/// `care_database.json`, sorted for display and exposed with the search/sort the
/// species picker (T007) needs. Loading always runs the validator, so a
/// `CareDatabase` instance is guaranteed to hold a valid, duplicate-free dataset.
///
/// Pure value type: no SwiftUI / SwiftData imports.
struct CareDatabase: Equatable {
    /// All profiles, sorted by species name (case-insensitive) for the picker.
    let profiles: [CareProfile]

    /// Builds the database from already-decoded profiles, sorting them for display.
    /// Does **not** validate — use `load(from:)` / `loadBundled` for the validated path.
    init(profiles: [CareProfile]) {
        self.profiles = profiles.sorted {
            $0.species.localizedCaseInsensitiveCompare($1.species) == .orderedAscending
        }
    }

    /// Decode the JSON array of records without validating — the raw shape the file
    /// and every batch share. The file is a top-level array of `CareProfile` objects.
    static func decode(from data: Data) throws -> [CareProfile] {
        try JSONDecoder().decode([CareProfile].self, from: data)
    }

    /// Decode **and** validate `data`, returning a ready-to-use database. Throws a
    /// `CareDatabaseError` (or a decoding error) if the data is malformed.
    static func load(from data: Data) throws -> CareDatabase {
        let profiles = try decode(from: data)
        try CareDatabaseValidator.validate(profiles)
        return CareDatabase(profiles: profiles)
    }

    /// Load the bundled `care_database.json` (decode + validate). Defaults to the
    /// app bundle; injectable for tests. Throws `.resourceMissing` if absent.
    static func loadBundled(
        from bundle: Bundle = .main,
        resource: String = "care_database"
    ) throws -> CareDatabase {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw CareDatabaseError.resourceMissing("\(resource).json")
        }
        return try load(from: try Data(contentsOf: url))
    }

    // MARK: - Picker support

    /// Number of plants in the database.
    var count: Int { profiles.count }

    /// Case- and diacritic-insensitive substring search on species, for the picker.
    /// An empty/whitespace query returns the full sorted list.
    func search(_ query: String) -> [CareProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return profiles }
        return profiles.filter {
            $0.species.range(
                of: trimmed,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) != nil
        }
    }

    /// The profile for an exact (normalised) species name, if present — the lookup a
    /// `Plant.species` reference resolves through.
    func profile(forSpecies species: String) -> CareProfile? {
        let key = CareDatabaseValidator.normalisedKey(species)
        return profiles.first { CareDatabaseValidator.normalisedKey($0.species) == key }
    }
}
