import Darwin

/// Keeps file system access on the current thread from downloading files that live
/// only in the cloud.
///
/// iCloud Drive and File Provider folders, such as `~/Library/CloudStorage`, can hold
/// dataless files and folders: placeholders whose contents or listings are downloaded
/// on first access. With materialization off, reading their metadata never downloads
/// them, and listing a dataless folder fails as unreadable instead.
/// See `setiopolicy_np(3)`, `IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES`.
public enum DatalessFilePolicy {
    /// Runs `body` with materialization of dataless files off for the current thread,
    /// then restores the thread's previous policy.
    ///
    /// `body` must stay on the calling thread, so it must be synchronous.
    public static func withoutMaterializing<Result>(_ body: () throws -> Result) rethrows -> Result {
        let previous = currentPolicy
        setiopolicy_np(IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES, IOPOL_SCOPE_THREAD, IOPOL_MATERIALIZE_DATALESS_FILES_OFF)
        defer {
            let restored = previous >= 0 ? previous : IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT
            setiopolicy_np(IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES, IOPOL_SCOPE_THREAD, restored)
        }
        return try body()
    }

    /// The current thread's policy, or -1 when it can't be read.
    static var currentPolicy: Int32 {
        getiopolicy_np(IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES, IOPOL_SCOPE_THREAD)
    }
}
