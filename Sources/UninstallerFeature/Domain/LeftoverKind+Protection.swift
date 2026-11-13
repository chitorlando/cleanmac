public extension LeftoverKind {
    /// macOS guards apps' sandbox containers, including the ones they share with their
    /// extensions: without Full Disk Access, CleanMac and even Finder may be refused when they
    /// move them to the Trash, though the user can still do it by hand in Finder.
    var isProtectedByMacOS: Bool {
        switch self {
        case .containers, .groupContainers: true
        default: false
        }
    }
}
