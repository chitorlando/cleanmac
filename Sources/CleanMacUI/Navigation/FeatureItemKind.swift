/// The kinds of item one feature can hand to another.
public enum FeatureItemKind: Hashable, Sendable {
    /// A folder, for a feature that looks into it.
    case folder
    /// An app bundle.
    case app
}
