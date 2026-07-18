import Foundation
import UIKit

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
    /// The plant's photo bytes (T219). Pre-filled from the plant in *edit* mode, then
    /// replaced in-memory by `stage(_:)` (from the capture screen) and persisted by
    /// `save()` — the form is transactional, so a Cancel discards a freshly-staged photo.
    @Published private(set) var photoData: Data?

    let mode: Mode
    let repository: PlantRepository
    /// Retained for source compatibility with the presenter (`ContentView.makeEditor`)
    /// and any future add path; the edit form no longer reads the care database.
    private let careDatabase: CareDatabase
    /// The camera seam (T207) handed to the capture screen (`CapturePhotoView`). The
    /// simulator/tests pass the stub so the path is screenshottable and testable.
    let camera: PhotoCapturing
    /// The plant being edited, loaded once in *edit* mode so `save()` can update it
    /// without clobbering its scheduling state. `nil` in *add* mode.
    private var editingPlant: Plant?
    /// The plant's species — **fixed once the plant exists** (T218). Loaded from the
    /// plant in *edit* mode and preserved verbatim on save; the form never changes it.
    private var species: String = ""
    /// The plant's current icon, editable.
    @Published var plantIcon: PlantIcon = .leaf
    /// The plant's ID, needed for the redesigned view (token colors + icon picker).
    @Published private(set) var plantID: UUID = UUID()

    init(
        mode: Mode,
        repository: PlantRepository,
        careDatabase: CareDatabase,
        camera: PhotoCapturing
    ) {
        self.mode = mode
        self.repository = repository
        self.careDatabase = careDatabase
        self.camera = camera
        availableRooms = (try? repository.allRooms()) ?? []
        if case let .edit(plantID) = mode {
            self.plantID = plantID
            if let plant = (try? repository.plant(id: plantID)) ?? nil {
                editingPlant = plant
                nickname = plant.nickname
                species = plant.species
                selectedRoomID = plant.roomID
                photoData = plant.photoData
                self.plantIcon = plant.icon
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

    // MARK: - Photo

    /// `true` when the plant currently has a photo (so the view can offer "Change
    /// photo" vs "Add photo" and show the image rather than a placeholder).
    var hasPhoto: Bool { photoData != nil }

    /// Stage a photo captured by `CapturePhotoView`: square + compress it with
    /// `PlantPhoto.encode` and hold it on the form. The preview updates immediately;
    /// the bytes are written to the plant by `save()` (the form is transactional, so a
    /// Cancel discards a just-staged photo). An unencodable image is ignored (keeps the
    /// existing photo).
    func stage(_ image: UIImage) {
        guard let data = PlantPhoto.encode(image) else { return }
        photoData = data
    }

    // MARK: - Save

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `true` when the form is complete: a non-blank nickname. Species is fixed and
    /// no longer part of form completeness (T218).
    var canSave: Bool { !trimmedNickname.isEmpty }

    /// Persist the plant via the repository — updating nickname/room/icon (preserving
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
            plant.photoData = photoData // staged by changePhoto() (T219)
            plant.icon = plantIcon
            // species + scheduling state (adj/lastWatered/nextDue/checkIns) untouched.
            try repository.update(plant)
            editingPlant = plant
            return plant
        } else {
            let plant = Plant(
                nickname: trimmedNickname,
                species: species,
                photoData: photoData,
                roomID: selectedRoomID,
                icon: plantIcon
            )
            try repository.add(plant)
            return plant
        }
    }

    /// Return the plant for the icon picker (with current values).
    func plantForIconPicker(repository: PlantRepository) -> Plant {
        if var plant = editingPlant {
            plant.nickname = trimmedNickname
            plant.icon = plantIcon
            return plant
        } else {
            return Plant(
                id: plantID,
                nickname: trimmedNickname,
                species: species,
                icon: plantIcon
            )
        }
    }
}
