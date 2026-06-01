import Foundation

/// Why a `PlantEditViewModel.save()` could not proceed. A structured error (not a
/// string) so the view and unit tests assert the *kind* of problem.
enum PlantEditError: Error, Equatable {
    /// The form is missing a nickname and/or a valid care-database species.
    case incomplete
}

/// Drives the **Add / Edit Plant** form (T007). Collects the user's nickname and a
/// species chosen from the bundled care database (T004), then saves through the
/// `PlantRepository` (T005) — inserting a new plant in *add* mode, or updating the
/// existing one (preserving its learned scheduling state) in *edit* mode.
///
/// All form rules live here behind a plain, testable surface — the view depends on
/// this view model rather than on the repository or care database directly. The
/// species list is sourced **only** from the care database, so a save can never
/// reference an unknown species.
@MainActor
final class PlantEditViewModel: ObservableObject {
    /// Whether the form is adding a new plant or editing an existing one. Carries
    /// the plant's identifier (not the whole value) in *edit* mode; the model
    /// loads the current plant from the repository so it can preserve fields the
    /// form doesn't touch (`adj`, `lastWatered`, `nextDue`, `checkIns`).
    enum Mode: Equatable, Identifiable {
        case add
        case edit(plantID: UUID)

        var id: String {
            switch self {
            case .add: return "add"
            case let .edit(plantID): return plantID.uuidString
            }
        }
    }

    /// The user's name for the plant.
    @Published var nickname: String = ""
    /// The currently selected species (a `CareProfile.species` from the care DB),
    /// or `""` when nothing is chosen yet.
    @Published var selectedSpecies: String = ""
    /// The species-picker search query; filters `speciesResults`.
    @Published var speciesQuery: String = ""
    /// `true` if *edit* mode was asked to edit a plant the repository doesn't have.
    @Published private(set) var loadFailed: Bool = false

    let mode: Mode
    private let repository: PlantRepository
    private let careDatabase: CareDatabase
    /// The plant being edited, loaded once in *edit* mode so `save()` can update it
    /// without clobbering its scheduling state. `nil` in *add* mode.
    private var editingPlant: Plant?

    init(mode: Mode, repository: PlantRepository, careDatabase: CareDatabase) {
        self.mode = mode
        self.repository = repository
        self.careDatabase = careDatabase
        if case let .edit(plantID) = mode {
            if let plant = (try? repository.plant(id: plantID)) ?? nil {
                editingPlant = plant
                nickname = plant.nickname
                selectedSpecies = plant.species
            } else {
                loadFailed = true
            }
        }
    }

    // MARK: - Presentation

    /// `true` when editing an existing plant rather than adding a new one.
    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    /// Navigation-bar title for the form.
    var title: String { isEditing ? "Edit Plant" : "Add Plant" }

    /// Save-button label.
    var saveButtonTitle: String { isEditing ? "Save" : "Add" }

    // MARK: - Species picker (sourced from the care database)

    /// Every species in the care database, sorted for display.
    var allSpecies: [CareProfile] { careDatabase.profiles }

    /// The species matching the current `speciesQuery` — the picker's rows. An
    /// empty query returns the full list.
    var speciesResults: [CareProfile] { careDatabase.search(speciesQuery) }

    /// Select a species from the picker.
    func select(_ profile: CareProfile) { selectedSpecies = profile.species }

    /// `true` when `profile.species` is the currently selected one (for a checkmark).
    func isSelected(_ profile: CareProfile) -> Bool {
        CareDatabaseValidator.normalisedKey(profile.species)
            == CareDatabaseValidator.normalisedKey(selectedSpecies)
    }

    // MARK: - Save

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The care-database profile for the selected species, if it resolves to a real
    /// record — the guard that keeps a save from referencing an unknown species.
    private var resolvedProfile: CareProfile? {
        careDatabase.profile(forSpecies: selectedSpecies)
    }

    /// `true` when the form is complete: a non-blank nickname and a species that
    /// exists in the care database.
    var canSave: Bool { !trimmedNickname.isEmpty && resolvedProfile != nil }

    /// Persist the plant via the repository — `add` in add mode, `update`
    /// (preserving scheduling state) in edit mode. Returns the saved plant.
    /// - Throws: `PlantEditError.incomplete` if `canSave` is `false`, or a
    ///   `PlantRepositoryError` from the store.
    @discardableResult
    func save() throws -> Plant {
        guard canSave, let profile = resolvedProfile else {
            throw PlantEditError.incomplete
        }
        if var plant = editingPlant {
            plant.nickname = trimmedNickname
            plant.species = profile.species
            try repository.update(plant)
            editingPlant = plant
            return plant
        } else {
            let plant = Plant(nickname: trimmedNickname, species: profile.species)
            try repository.add(plant)
            return plant
        }
    }
}
