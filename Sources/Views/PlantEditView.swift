import SwiftUI

/// The **Edit Plant** form (T007, narrowed by T218). Edits a plant's nickname and
/// room only — **species is fixed once a plant exists**, so there's no species
/// picker; choosing a species happens in the basket add flow (T204). Saving routes
/// through the repository (T005) via `PlantEditViewModel`, preserving the plant's
/// learned scheduling state.
///
/// Pure presentation: every form rule (when a save is allowed) lives in the view
/// model.
struct PlantEditView: View {
    @StateObject private var viewModel: PlantEditViewModel
    /// Called after a successful save or a cancel, so the presenter can dismiss the
    /// sheet and refresh the list.
    private let onFinish: () -> Void

    init(viewModel: PlantEditViewModel, onFinish: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nickname") {
                    TextField("Nickname", text: $viewModel.nickname)
                        .textInputAutocapitalization(.words)
                }

                if !viewModel.availableRooms.isEmpty {
                    Section("Room") {
                        Picker("Room", selection: $viewModel.selectedRoomID) {
                            Text("None").tag(UUID?.none)
                            ForEach(viewModel.availableRooms) { room in
                                Text(room.name).tag(UUID?.some(room.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onFinish() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.saveButtonTitle) {
                        if (try? viewModel.save()) != nil { onFinish() }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}
