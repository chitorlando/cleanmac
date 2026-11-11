import Foundation

/// Looks for a text in file names, ignoring case, accents and the spaces around the text.
///
/// Trimming the text takes about as long as searching one name, and it's the same for
/// every file, so a pass over many files prepares the search once.
struct LargeFileNameSearch: Sendable {
    private let term: String

    init(_ text: String) {
        term = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// An empty text matches every file.
    func matches(_ file: LargeFile) -> Bool {
        term.isEmpty || file.item.name.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
