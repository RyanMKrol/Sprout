import Foundation

/// A plant the user owns. Holds its identity, the species it maps to in the care
/// database, and the *learned* scheduling state the adaptive engine maintains:
/// the per-plant multiplier `adj`, when it was last watered, and the current
/// `nextDue` date.
///
/// Pure value type: no SwiftUI / SwiftData imports. T005 maps this onto a
/// SwiftData `@Model` for persistence; the engine tasks (T009/T010) read and
/// update the scheduling fields.
struct Plant: Codable, Equatable, Identifiable, Sendable {
    /// Valid range for the learned multiplier `adj`. The schedule engine (T009)
    /// clamps `adj` into this band before using it.
    static let adjRange: ClosedRange<Double> = 0.5...2.0

    /// The default learned multiplier before any check-ins have nudged it.
    static let defaultAdj: Double = 1.0

    var id: UUID
    /// The user's name for the plant (e.g. "Monty").
    var nickname: String
    /// References `CareProfile.species` in the care database.
    var species: String
    /// Learned multiplier on the species' base interval, personalised from
    /// check-ins. Defaults to `1.0`; clamped to `adjRange` by the engine.
    var adj: Double
    /// When the plant was last watered, if ever.
    var lastWatered: Date?
    /// The current next-watering date, if scheduled.
    var nextDue: Date?
    /// Chronological history of check-ins for this plant.
    var checkIns: [CheckIn]
    /// An optional photo of the plant, stored as JPEG bytes (see `PlantPhoto`).
    /// `nil` until the user captures one; kept as raw `Data` so this stays a pure
    /// value type with no UIKit dependency.
    var photoData: Data?
    /// The room the plant lives in, if assigned. The room's environment drives the
    /// plant's watering cadence (see `RoomEnvironment`). `nil` → neutral schedule.
    var roomID: UUID?

    init(
        id: UUID = UUID(),
        nickname: String,
        species: String,
        adj: Double = Plant.defaultAdj,
        lastWatered: Date? = nil,
        nextDue: Date? = nil,
        checkIns: [CheckIn] = [],
        photoData: Data? = nil,
        roomID: UUID? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.species = species
        self.adj = adj
        self.lastWatered = lastWatered
        self.nextDue = nextDue
        self.checkIns = checkIns
        self.photoData = photoData
        self.roomID = roomID
    }
}
