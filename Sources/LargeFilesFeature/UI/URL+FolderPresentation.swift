import Foundation

extension URL {
    /// Name of the folder as Finder shows it, which for folders such as Downloads is in the
    /// user's language.
    var folderDisplayName: String {
        FileManager.default.displayName(atPath: path)
    }

    /// Path with the home folder written as `~`.
    var tildeAbbreviatedPath: String {
        (path as NSString).abbreviatingWithTildeInPath
    }
}
