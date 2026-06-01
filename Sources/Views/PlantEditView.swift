import SwiftUI

/// The **Add / Edit Plant** form (T007). A nickname field and a species picker
/// sourced from the bundled care database (T004); saving routes through the
/// repository (T005) via `PlantEditViewModel`. Presented as a sheet from the My
/// Plants list, and verified by the `-seedDemoData YES` screenshot convention
/// (`SPROUT_SCREEN=add`).
///
/// Pure presentation: every form rule (what's selectable, when a save is allowed,
/// add-vs-edit) lives in the view model.
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
                Section("Name") {
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

                Section("Species") {
                    TextField("Search species", text: $viewModel.speciesQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    ForEach(viewModel.speciesResults) { profile in
                        Button {
                            viewModel.select(profile)
                        } label: {
                            HStack {
                                Text(profile.species)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.isSelected(profile) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .accessibilityLabel("Selected")
                                }
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
