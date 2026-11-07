import Foundation
import Testing

/// A module's String Catalog on disk.
struct CatalogFile: Sendable, CustomTestStringConvertible {
    let url: URL

    /// Name of the module that owns the catalog, such as `CleanMacUI`.
    var moduleName: String {
        url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
    }

    var testDescription: String { moduleName }

    func load() throws -> StringCatalog {
        try JSONDecoder().decode(StringCatalog.self, from: Data(contentsOf: url))
    }
}
