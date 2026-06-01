import SwiftUI

/// The outcome of the basket add flow, handed back to the presenter.
enum BasketAddResult: Equatable {
    /// The user cancelled — nothing was created.
    case cancelled
    /// The user committed; the created plants are returned in basket order so the
    /// presenter can refresh the list and (T208) offer to photograph them.
    case created([Plant])
}

/// The **basket add** screen (T204) — the fast, batch replacement for the single
/// Add form. Tap species to drop plants into the basket (the same species more than
/// once is fine); each gets an auto-assigned random English nickname you can edit
/// inline or reroll. "Add N plants" commits them all at once.
///
/// Pure presentation: all state + rules live in `BasketAddViewModel`.
struct BasketAddView: View {
    @StateObject private var viewModel: BasketAddViewModel
    private let onFinish: (BasketAddResult) -> Void

    init(viewModel: BasketAddViewModel, onFinish: @escaping (BasketAddResult) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            List {
                basketSection
                speciesSection
            }
            .navigationTitle("Add Plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onFinish(.cancelled) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(addButtonTitle) {
                        if let created = try? viewModel.commit() {
                            onFinish(.created(created))
                        }
                    }
                    .disabled(!viewModel.canCommit)
                }
            }
        }
    }

    private var addButtonTitle: String {
        let n = viewModel.commitCount
        return n <= 1 ? "Add Plant" : "Add \(n) Plants"
    }

    // MARK: - Basket

    @ViewBuilder
    private var basketSection: some View {
        if viewModel.basket.isEmpty {
            Section {
                Text("Tap a species below to add it. Each plant gets a random name you can edit.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else {
            Section("Basket (\(viewModel.basket.count))") {
                ForEach(viewModel.basket) { entry in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Name", text: nameBinding(for: entry))
                                .textInputAutocapitalization(.words)
                                .font(.body)
                            Text(entry.species)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.reroll(entry)
                        } label: {
                            Image(systemName: "shuffle")
                                .accessibilityLabel("New random name")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onDelete { viewModel.remove(atOffsets: $0) }
            }
        }
    }

    /// A read/write binding to a basket entry's nickname for inline editing.
    private func nameBinding(for entry: BasketAddViewModel.Entry) -> Binding<String> {
        Binding(
            get: { viewModel.basket.first { $0.id == entry.id }?.nickname ?? entry.nickname },
            set: { viewModel.rename(entry, to: $0) }
        )
    }

    // MARK: - Species picker

    private var speciesSection: some View {
        Section("Add species") {
            TextField("Search species", text: $viewModel.speciesQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            ForEach(viewModel.speciesResults) { profile in
                Button {
                    viewModel.add(profile)
                } label: {
                    HStack {
                        Text(profile.species)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityLabel("Add \(profile.species)")
                    }
                }
            }
        }
    }
}
