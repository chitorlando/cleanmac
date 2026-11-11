import Foundation

/// Who carries out what a key press asks of the disk map.
enum DiskMapKeyRoute: Equatable, Sendable {
    /// The map itself.
    case map
    /// Another feature of the app, which shows the item at `itemURL`.
    case feature(id: String, itemURL: URL)
}
