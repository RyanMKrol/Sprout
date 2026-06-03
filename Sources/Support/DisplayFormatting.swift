import SwiftUI

extension String {
    /// Capitalises the **first letter of each whitespace-separated word**, leaving the
    /// rest of each word untouched. Unlike `Foundation.capitalized` this preserves
    /// existing capitals and punctuation, so botanical epithets get fixed
    /// ("Monstera deliciosa" → "Monstera Deliciosa") without mangling acronyms or
    /// apostrophes ("ZZ Plant" and "Bird's Nest Fern" are preserved). Used for
    /// plant-species and room-name display.
    var capitalisedWords: String {
        split(separator: " ", omittingEmptySubsequences: false)
            .map { word -> String in
                guard let first = word.firstIndex(where: { $0.isLetter }) else { return String(word) }
                return String(word[..<first]) + word[first].uppercased() + word[word.index(after: first)...]
            }
            .joined(separator: " ")
    }
}

/// A palette of bright, vibrant tints used to colour a plant's leaf-glyph placeholder
/// when it has no photo, so the My Plants list reads as playful rather than a wall of
/// identical blue badges. A plant's colour is picked deterministically from its id, so
/// it stays stable across launches and re-renders.
enum PlantPalette {
    /// Ten vibrant, well-separated hues.
    static let colors: [Color] = [
        Color(red: 0.94, green: 0.27, blue: 0.27), // red
        Color(red: 0.96, green: 0.55, blue: 0.13), // orange
        Color(red: 0.98, green: 0.78, blue: 0.18), // amber
        Color(red: 0.40, green: 0.78, blue: 0.22), // green
        Color(red: 0.13, green: 0.72, blue: 0.55), // teal
        Color(red: 0.20, green: 0.62, blue: 0.92), // blue
        Color(red: 0.36, green: 0.40, blue: 0.92), // indigo
        Color(red: 0.61, green: 0.35, blue: 0.91), // violet
        Color(red: 0.92, green: 0.36, blue: 0.65), // pink
        Color(red: 0.78, green: 0.45, blue: 0.20), // brown
    ]

    /// A stable vibrant colour for a plant id — same id always maps to the same hue
    /// (derived from the uuid string so it survives across app launches).
    static func color(for id: UUID) -> Color {
        let sum = id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[sum % colors.count]
    }
}
