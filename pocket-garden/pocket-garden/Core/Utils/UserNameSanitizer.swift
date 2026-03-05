import Foundation

enum UserNameSanitizer {
    static let maxLength = 25

    private static let allowedScalars: CharacterSet = {
        var set = CharacterSet.letters
        set.formUnion(.decimalDigits)
        set.insert(charactersIn: " '-")
        return set
    }()

    /// Lightweight filtering for TextField updates.
    /// Keeps only allowed characters and enforces length.
    static func filterForInput(_ raw: String) -> String {
        let filtered = raw.unicodeScalars.filter { scalar in
            allowedScalars.contains(scalar)
        }
        return String(String.UnicodeScalarView(filtered)).prefixGraphemes(maxLength)
    }

    /// Final canonical value for persistence/display.
    static func sanitize(_ raw: String) -> String {
        let inputFiltered = filterForInput(raw)
        let collapsed = inputFiltered
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed.prefixGraphemes(maxLength)
    }
}

private extension String {
    func prefixGraphemes(_ maxCount: Int) -> String {
        guard count > maxCount else { return self }
        return String(prefix(maxCount))
    }
}
