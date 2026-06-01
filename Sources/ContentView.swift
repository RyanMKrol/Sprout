import SwiftUI

/// Minimal first-run screen for the T001 scaffold. The real home screen
/// (My Plants list + empty state) arrives in T006; persistence in T005.
struct ContentView: View {
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

#Preview {
    ContentView()
}
