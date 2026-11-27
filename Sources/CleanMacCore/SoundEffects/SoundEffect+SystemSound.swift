public extension SoundEffect {
    /// The sound of macOS that marks the moment: a soft tick when a scan ends, Finder's own
    /// sounds when items go to the Trash or the Trash is emptied, a brighter one when maintenance
    /// ends, and a low one, which no success plays, when a threat is found.
    var systemSound: SystemSound {
        switch self {
        case .scanFinished:
            return .alert("Tink")
        case .cleanupFinished, .appUninstalled:
            return .moveToTrash
        case .trashEmptied:
            return .emptyTrash
        case .maintenanceFinished:
            return .alert("Hero")
        case .threatFound:
            return .alert("Basso")
        }
    }
}
