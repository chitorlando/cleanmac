/// Tells whether CleanMac has Full Disk Access, without ever asking the user.
public protocol FullDiskAccessChecking: Sendable {
    func hasFullDiskAccess() -> Bool
}
