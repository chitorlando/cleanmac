import Foundation

extension URL {
    /// Name of the folder as Finder shows it, such as “Descargas” for `~/Downloads` in Spanish.
    var folderDisplayName: String {
        FileManager.default.displayName(atPath: path)
    }
}
