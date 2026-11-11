/// Decides who carries out what a key press asks of the disk map.
///
/// The map does nearly all of it. The exception is opening an app: the map has nothing to
/// show inside one and leaves its removal to the Uninstaller, so → and Return on a highlighted
/// app show it there, as a click on the note of its row does. Without a feature that
/// uninstalls apps the keys stay with the map, which does nothing with them on an app.
struct DiskMapKeyRouter: Sendable {
    /// Id of the feature that uninstalls apps, or `nil` when the app has none.
    let uninstallerFeatureID: String?

    /// - Parameters:
    ///   - highlighted: The highlighted item, if there is one.
    ///   - advice: What the map lets the user do with that item.
    func route(for action: DiskMapKeyAction, highlighted: DiskNode?, advice: RemovalAdvice?) -> DiskMapKeyRoute {
        guard
            action == .openHighlighted,
            advice == .useUninstaller,
            let highlighted,
            let uninstallerFeatureID
        else { return .map }
        return .feature(id: uninstallerFeatureID, itemURL: highlighted.url)
    }
}
