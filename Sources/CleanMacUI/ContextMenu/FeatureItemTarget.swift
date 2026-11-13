import Foundation

/// What an item row hands to the actions other features offer, and as which kind of item.
///
/// An app goes as an app and a folder as a folder. A file goes as the folder that holds it,
/// so a large file can still offer to look for duplicates around it.
public struct FeatureItemTarget: Equatable, Sendable {
    public let kind: FeatureItemKind
    public let url: URL

    public init(itemAt url: URL, isFolder: Bool) {
        if url.pathExtension.lowercased() == "app" {
            kind = .app
            self.url = url
        } else {
            kind = .folder
            self.url = isFolder ? url : url.deletingLastPathComponent()
        }
    }
}
