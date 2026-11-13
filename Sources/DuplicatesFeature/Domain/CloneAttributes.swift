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
    /// `ATTR_FILE_ALLOCSIZE`: the space the file takes up on disk, or `nil` when it wasn't
    /// asked for or the volume didn't return it.
    let allocatedSize: Int64?
    /// `ATTR_CMNEXT_PRIVATESIZE`: the part of that space no other file shares, which is what
    /// removing the file alone frees, or `nil` when it wasn't asked for or the volume didn't
    /// return it.
    let privateSize: Int64?

    /// How the file shares its data, or `nil` when the volume tells nothing about it.
    ///
    /// Without a count, as on macOS 13, a file is known to stand alone when it shares no
    /// blocks: it never did, or it keeps the flag of a file that had clones but all of its
    /// space is its own again, because those clones were deleted or rewritten in full.
    /// Any other may be a clone or a clone that was later modified: macOS 13 flags them alike,
    /// never with `EF_SHARES_ALL_BLOCKS`, so the number of clones stays unknown and the file
    /// counts as one that may share part of its data.
    var cloneInfo: CloneInfo? {
        guard tracksClones else { return nil }
        let mayShareBlocks = flags & UInt64(EF_MAY_SHARE_BLOCKS) != 0
        let sharesAllBlocks = flags & UInt64(EF_SHARES_ALL_BLOCKS) != 0
        // Where clones are counted the sizes aren't needed, and don't change what the count says.
        let sharesNothingNow = referenceCount == nil && keepsAllItsSpace
        return CloneInfo(
            streamID: CloneInfo.StreamID(device: device, cloneID: cloneID),
            cloneCount: referenceCount ?? (mayShareBlocks && !sharesNothingNow ? nil : 1),
            mayShareSomeData: mayShareBlocks && !sharesAllBlocks && !sharesNothingNow
        )
    }

    /// Whether the volume keeps track of the file's data. One that doesn't, such as HFS+ or
    /// exFAT, still answers, with zeros: no file counted or, where clones can't be counted,
    /// no data stream. Its files would otherwise all seem to be on the same stream.
    private var tracksClones: Bool {
        if let referenceCount { return referenceCount > 0 }
        return cloneID != 0
    }

    /// Whether no other file shares any of the space the file takes up, by the sizes the volume
    /// reports. A file that takes up no space proves nothing, and neither do missing sizes.
    private var keepsAllItsSpace: Bool {
        guard let allocatedSize, let privateSize, allocatedSize > 0 else { return false }
        return privateSize >= allocatedSize
    }
}
