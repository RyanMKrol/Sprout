import SwiftUI

/// Root screen. With the T002 demo-seed hook active (`-seedDemoData YES` in DEBUG)
/// it renders a populated stand-in list so screenshots show real content; otherwise
/// it shows the minimal first-run welcome. The real My Plants list arrives in T006
/// (persistence in T005) and will reuse the same launch-argument contract.
struct ContentView: View {
    var body: some View {
        if DemoSeed.isActive {
            DemoPlantListView(plants: DemoSeed.plants)
        } else {
            WelcomeView()
        }
    }
}

/// Minimal first-run screen for the unseeded scaffold.
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Sprout")
                .font(.largeTitle.bold())
            Text("Track your plants and never miss a watering.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// A throwaway populated list used only for seeded screenshots until T006 builds the
/// real My Plants list from the repository.
struct DemoPlantListView: View {
    let plants: [DemoPlant]

    var body: some View {
        NavigationStack {
            List(plants) { plant in
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plant.name)
                            .font(.headline)
                        Text(plant.species)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(plant.nextDue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.blue.opacity(0.15), in: Capsule())
                            .foregroundStyle(.blue)
                        Image(systemName: plant.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(plant.isHealthy ? .green : .orange)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("My Plants")
        }
    }
}

#Preview {
    WelcomeView()
}
