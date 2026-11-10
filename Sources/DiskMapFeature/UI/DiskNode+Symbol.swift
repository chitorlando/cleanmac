extension DiskNode {
    /// Icon of the item in the list.
    var symbolName: String {
        switch kind {
        case .folder: "folder.fill"
        case .file: "doc.fill"
        case .package: url.pathExtension.lowercased() == "app" ? "app.fill" : "shippingbox.fill"
        }
    }
}
