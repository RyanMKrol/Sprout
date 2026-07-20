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
