import SwiftUI

@main
struct SproutApp: App {
    var body: some Scene {
        WindowGroup {
            // Sprout's visual design is a single fixed light theme (cream paper,
            // brand green). It has no dark-mode variants, so we pin the whole scene
            // to light — otherwise system/adaptive colors (wheel pickers, default
            // `.primary` labels) resolve to white in dark mode and vanish against the
            // fixed light backgrounds.
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
