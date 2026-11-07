/// A way in which the name of a file in the Library can point to an app.
public enum MatchRule: Hashable, Sendable {
    /// The name equals the bundle ID, such as "com.foo.app".
    case bundleID
    /// The name starts with the bundle ID followed by a dot, such as "com.foo.app.helper".
    case bundleIDPrefix
    /// The name ends with a dot followed by the bundle ID, such as "group.com.foo.app".
    case groupContainer
    /// The name equals the app name or one of its alternate names.
    case appName
}
