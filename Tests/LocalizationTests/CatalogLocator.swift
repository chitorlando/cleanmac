import Foundation

/// Finds every module's `Sources/<Module>/Resources/Localizable.xcstrings`.
enum CatalogLocator {
    static func catalogs(packageRoot: URL = packageRoot()) -> [CatalogFile] {
        let sources = packageRoot.appending(path: "Sources")
        let modules = (try? FileManager.default.contentsOfDirectory(atPath: sources.path)) ?? []
        return modules.sorted().compactMap { module in
            let url = sources.appending(path: "\(module)/Resources/Localizable.xcstrings")
            return FileManager.default.fileExists(atPath: url.path) ? CatalogFile(url: url) : nil
        }
    }

    /// The package root, three levels above this file: `Tests/LocalizationTests/<file>`.
    static func packageRoot(filePath: String = #filePath) -> URL {
        URL(filePath: filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
