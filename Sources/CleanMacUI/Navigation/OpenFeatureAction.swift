/// Asks the app to show another feature, given its id.
///
/// Features read it from the environment as `openFeature` and call it like a function,
/// such as `openFeature("uninstaller")`. The app shell provides it; elsewhere, such as in
/// previews, it does nothing. Ids that match no feature are ignored.
public struct OpenFeatureAction: Sendable {
    private let handler: @MainActor @Sendable (String) -> Void

    public init(_ handler: @escaping @MainActor @Sendable (String) -> Void) {
        self.handler = handler
    }

    /// Does nothing, for views shown outside the app shell.
    public static let none = OpenFeatureAction { _ in }

    @MainActor
    public func callAsFunction(_ featureID: String) {
        handler(featureID)
    }
}
