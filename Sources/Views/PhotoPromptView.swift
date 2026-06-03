import SwiftUI

/// The **post-add photo prompt** (T223) — shown right after a multi-add commit to offer
/// photographing the just-created plants. Replaces the old bare `confirmationDialog` that
/// floated, disconnected, over a long list: this is a proper sheet anchored to the add
/// flow, showing the new plants by name with a clear **Take Photos** primary action and an
/// equally obvious **Skip photos** decline.
///
/// Pure presentation: the host owns the targets and the two outcome closures; the copy
/// lives in `PhotoPromptText` so it's unit-testable without the view.
struct PhotoPromptView: View {
    /// The plants just created, in basket order — shown so the prompt reads as part of the
    /// add flow rather than a detached dialog.
    let plants: [PhotoCaptureCoordinator.Target]
    let onTakePhotos: () -> Void
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 64, height: 64)
                                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 18))
                            Text(PhotoPromptText.title(count: plants.count))
                                .font(.title3.bold())
                                .multilineTextAlignment(.center)
                            Text(PhotoPromptText.subtitle(count: plants.count))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                    Section(PhotoPromptText.listHeader(count: plants.count)) {
                        ForEach(plants) { plant in
                            HStack(spacing: 12) {
                                PlantThumbnail(photoData: nil, tint: PlantPalette.color(for: plant.id))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plant.nickname).font(.headline)
                                    Text(plant.species.capitalisedWords).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                VStack(spacing: 12) {
                    Button(action: onTakePhotos) {
                        Label("Take Photos", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Skip photos", action: onSkip)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("New plants added")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip", action: onSkip)
                }
            }
        }
    }
}

/// Pure copy for the post-add photo prompt (T223), factored out so the wording is
/// unit-testable without instantiating the SwiftUI view.
enum PhotoPromptText {
    static func title(count: Int) -> String {
        count <= 1 ? "Add a photo of your new plant?" : "Add photos of your new plants?"
    }

    static func subtitle(count: Int) -> String {
        count <= 1
            ? "Take a photo now, or skip and add one later from the plant's page."
            : "Walk through them one at a time, or skip and add photos later."
    }

    static func listHeader(count: Int) -> String {
        count <= 1 ? "New plant" : "New plants (\(count))"
    }
}
