/// Caches in `~/Library/Caches` that hold sync state or credentials. Removing them can force
/// iCloud to resync or sign the user out, so no feature offers to remove them.
public enum SyncStateCaches {
    /// Names of the caches, as they appear in `~/Library/Caches`.
    public static let names: Set<String> = [
        "com.apple.bird",
        "com.apple.akd",
        "com.apple.ap.adprivacyd",
        "CloudKit",
        "FamilyCircle"
    ]
}
