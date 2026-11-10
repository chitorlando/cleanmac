import Darwin

/// What `getattrlist` returns about the data of a file, before it's interpreted.
struct CloneAttributes: Equatable, Sendable {
    let device: Int64
    /// `ATTR_CMNEXT_CLONEID`: the data stream of the file.
    let cloneID: UInt64
    /// `ATTR_CMNEXT_EXT_FLAGS`: the `EF_` flags of the file.
    let flags: UInt64
    /// `ATTR_CMNEXT_CLONE_REFCNT`: how many files share all of the data, or `nil` when the
    /// system can't count them.
    let referenceCount: Int?

    /// How the file shares its data, or `nil` when the volume counts no file on it, as one
    /// that doesn't track clones would.
    ///
    /// Without a count, as on macOS 13, only a file that shares no blocks is known to stand
    /// alone. Any other may be a clone, a clone that was later modified or the last of its
    /// clones: macOS 13 flags them all alike, never with `EF_SHARES_ALL_BLOCKS`, so the number
    /// of clones stays unknown and the file counts as one that may share part of its data.
    var cloneInfo: CloneInfo? {
        if let referenceCount, referenceCount <= 0 { return nil }
        let mayShareBlocks = flags & UInt64(EF_MAY_SHARE_BLOCKS) != 0
        let sharesAllBlocks = flags & UInt64(EF_SHARES_ALL_BLOCKS) != 0
        return CloneInfo(
            streamID: CloneInfo.StreamID(device: device, cloneID: cloneID),
            cloneCount: referenceCount ?? (mayShareBlocks ? nil : 1),
            mayShareSomeData: mayShareBlocks && !sharesAllBlocks
        )
    }
}
