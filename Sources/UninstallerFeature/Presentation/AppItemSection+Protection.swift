public extension AppItemSection.Category {
    /// Whether macOS protects the items of this group. See `LeftoverKind.isProtectedByMacOS`.
    var isProtectedByMacOS: Bool {
        switch self {
        case .application: false
        case .leftover(let kind): kind.isProtectedByMacOS
        }
    }
}
