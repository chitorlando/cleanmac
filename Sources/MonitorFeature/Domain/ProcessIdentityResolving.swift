/// Finds the app a process belongs to, to show its name and icon.
public protocol ProcessIdentityResolving: Sendable {
    func identity(of pid: Int32) -> ProcessIdentity?
}
