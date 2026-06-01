import Foundation

/// Why a `PlantEditViewModel.save()` could not proceed. A structured error (not a
/// string) so the view and unit tests assert the *kind* of problem.
enum PlantEditError: Error, Equatable {
    /// The form is missing a nickname.
    case incomplete
}

/// Drives the **Edit Plant** form (T007, narrowed by T218). Collects the user's
/// nickname and the plant's room, then saves through the `PlantRepository` (T005),
/// preserving the plant's learned scheduling state. **Species is fixed once a plant
/// exists** — adding a plant (and choosing its species) goes through the basket flow
/// (T204), so this form no longer offers a species picker.
///
/// All form rules live here behind a plain, testable surface — the view depends on
/// this view model rather than on the repository directly. The `Mode` enum is
/// retained for source compatibility with the presenter, but only the `edit` path is
/// reached in the app.
@MainActor
final class PlantEditViewModel: ObservableObject {
    /// Whether the form is adding a new plant or editing an existing one. Carries
    /// the plant's identifier (not the whole value) in *edit* mode; the model
    /// loads the current plant from the repository so it can preserve fields the
    /// form doesn't touch (`species`, `adj`, `lastWatered`, `nextDue`, `checkIns`).
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
    /// The room the plant is assigned to (T213). `nil` → no room (neutral schedule).
    @Published var selectedRoomID: UUID?
    /// Rooms available to assign to (loaded from the repository).
    @Published private(set) var availableRooms: [Room] = []
    /// `true` if *edit* mode was asked to edit a plant the repository doesn't have.
    @Published private(set) var loadFailed: Bool = false

    let mode: Mode
    private let repository: PlantRepository
    /// Retained for source compatibility with the presenter (`ContentView.makeEditor`)
    /// and any future add path; the edit form no longer reads the care database.
    private let careDatabase: CareDatabase
    /// The plant being edited, loaded once in *edit* mode so `save()` can update it
    /// without clobbering its scheduling state. `nil` in *add* mode.
    private var editingPlant: Plant?
    /// The plant's species — **fixed once the plant exists** (T218). Loaded from the
    /// plant in *edit* mode and preserved verbatim on save; the form never changes it.
    private var species: String = ""

    init(mode: Mode, repository: PlantRepository, careDatabase: CareDatabase) {
        self.mode = mode
        self.repository = repository
        self.careDatabase = careDatabase
        availableRooms = (try? repository.allRooms()) ?? []
        if case let .edit(plantID) = mode {
            if let plant = (try? repository.plant(id: plantID)) ?? nil {
                editingPlant = plant
                nickname = plant.nickname
                species = plant.species
                selectedRoomID = plant.roomID
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

    // MARK: - Save

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `true` when the form is complete: a non-blank nickname. Species is fixed and
    /// no longer part of form completeness (T218).
    var canSave: Bool { !trimmedNickname.isEmpty }

    /// Persist the plant via the repository — updating nickname/room (preserving
    /// species and scheduling state) in edit mode. Returns the saved plant.
    /// - Throws: `PlantEditError.incomplete` if `canSave` is `false`, or a
    ///   `PlantRepositoryError` from the store.
    @discardableResult
    func save() throws -> Plant {
        guard canSave else {
            throw PlantEditError.incomplete
        }
        if var plant = editingPlant {
            plant.nickname = trimmedNickname
            plant.roomID = selectedRoomID
            // species + scheduling state (adj/lastWatered/nextDue/checkIns) untouched.
            try repository.update(plant)
            editingPlant = plant
            return plant
        } else {
            let plant = Plant(nickname: trimmedNickname, species: species, roomID: selectedRoomID)
            try repository.add(plant)
            return plant
        }
    }
}
