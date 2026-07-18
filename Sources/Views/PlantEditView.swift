import SwiftUI
import UIKit

/// The **Edit Plant** form redesign (T046). Edits a plant's nickname, icon, room, and photo.
/// **Species is fixed** — choosing a species happens in the basket add flow (T204). Saving
/// routes through the repository via `PlantEditViewModel`, preserving the plant's learned
/// scheduling state. Tapping "Delete" shows a confirmation alert; on confirm, deletes via the
/// repository and dismisses to the list.
///
/// Pure presentation: every form rule (when a save is allowed) lives in the view model.
struct PlantEditView: View {
    @StateObject private var viewModel: PlantEditViewModel
    /// Called after a successful save or a cancel, so the presenter can dismiss the sheet.
    private let onFinish: () -> Void
    @State private var capturingPhoto = false
    @State private var pickingIcon = false
    @State private var showDeleteConfirm = false

    init(
        viewModel: PlantEditViewModel,
        onFinish: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            SproutSheetHeader(
                title: "Edit Plant",
                confirmLabel: "Save",
                confirmEnabled: viewModel.canSave,
                onCancel: onFinish,
                onConfirm: saveAndDismiss
            )

            ScrollView {
                VStack(spacing: 20) {
                    // PHOTO section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionEyebrow(text: "Photo")

                        HStack(spacing: 16) {
                            if let photoData = viewModel.photoData,
                               let photo = UIImage(data: photoData) {
                                PlantToken(
                                    icon: viewModel.plantIcon,
                                    duo: PlantTokenPalette.duo(for: viewModel.plantID),
                                    size: 64,
                                    photo: photo
                                )
                            } else {
                                FixedGlyphPlantToken(
                                    icon: viewModel.plantIcon,
                                    duo: PlantTokenPalette.duo(for: viewModel.plantID),
                                    size: 64
                                )
                            }

                            Button(action: { capturingPhoto = true }) {
                                Text(viewModel.hasPhoto ? "Change photo" : "Add photo")
                                    .font(SproutFont.body(17, weight: .medium))
                                    .foregroundStyle(SproutTheme.brandGreen)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(SproutTheme.Radius.row)
                    }

                    // ICON section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionEyebrow(text: "Icon")

                        HStack(spacing: 16) {
                            FixedGlyphPlantToken(
                                icon: viewModel.plantIcon,
                                duo: PlantTokenPalette.duo(for: viewModel.plantID),
                                size: 34
                            )

                            Button(action: { pickingIcon = true }) {
                                Text("Change icon")
                                    .font(SproutFont.body(17, weight: .medium))
                                    .foregroundStyle(SproutTheme.brandGreen)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(SproutTheme.Radius.row)
                    }

                    // NICKNAME section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionEyebrow(text: "Nickname")

                        TextField("Plant name", text: $viewModel.nickname)
                            .font(SproutFont.body(17))
                            .foregroundStyle(SproutTheme.ink)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(SproutTheme.Radius.row)
                    }

                    // ROOM section
                    if !viewModel.availableRooms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionEyebrow(text: "Room")

                            HStack(spacing: 12) {
                                Menu {
                                    Button("None") {
                                        viewModel.selectedRoomID = nil
                                    }
                                    ForEach(viewModel.availableRooms) { room in
                                        Button(room.name) {
                                            viewModel.selectedRoomID = room.id
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(roomDisplayName)
                                            .font(SproutFont.body(17))
                                            .foregroundStyle(SproutTheme.ink)
                                        Spacer()
                                        ChromeIcon.chevronRight.image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(SproutTheme.textMuted)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(SproutTheme.Radius.row)
                            }
                        }
                    }

                    // DELETE section (30pt gap before)
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            ChromeIcon.trash.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(SproutTheme.destructive)

                            Button(action: { showDeleteConfirm = true }) {
                                Text("Delete Plant")
                                    .font(SproutFont.body(17, weight: .semibold))
                                    .foregroundStyle(SproutTheme.destructive)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(
                            Color.white
                                .border(
                                    Color(red: 196.0 / 255, green: 85.0 / 255, blue: 59.0 / 255, opacity: 0.2),
                                    width: 1
                                )
                        )
                        .cornerRadius(SproutTheme.Radius.row)
                    }
                    .padding(.top, 30)
                }
                .padding(20)
            }

            Spacer()
        }
        .background(SproutTheme.paper)
        .sproutSheetBackground()
        .fullScreenCover(isPresented: $capturingPhoto) {
            CapturePhotoView(
                camera: viewModel.camera,
                onCapture: { image in
                    viewModel.stage(image)
                    capturingPhoto = false
                },
                onCancel: { capturingPhoto = false }
            )
        }
        .sheet(isPresented: $pickingIcon) {
            IconPickerView(
                plant: viewModel.plantForIconPicker(repository: viewModel.repository),
                repository: viewModel.repository,
                onFinish: { pickingIcon = false }
            )
        }
        .sproutAlert(isPresented: $showDeleteConfirm) {
            SproutAlert(
                icon: .trash,
                tint: SproutTheme.destructive,
                title: "Delete \(viewModel.nickname)?",
                message: "This removes the plant and its check-in history. This can't be undone.",
                confirmLabel: "Delete",
                confirmRole: .destructive,
                onConfirm: deleteAndDismiss,
                onCancel: { showDeleteConfirm = false }
            )
        }
    }

    private var roomDisplayName: String {
        if let roomID = viewModel.selectedRoomID,
           let room = viewModel.availableRooms.first(where: { $0.id == roomID }) {
            return room.name
        }
        return "None"
    }

    private func saveAndDismiss() {
        if (try? viewModel.save()) != nil { onFinish() }
    }

    private func deleteAndDismiss() {
        try? viewModel.repository.delete(id: viewModel.plantID)
        showDeleteConfirm = false
        onFinish()
    }
}
