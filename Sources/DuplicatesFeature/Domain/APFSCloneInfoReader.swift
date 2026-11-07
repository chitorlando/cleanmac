import Darwin
import Foundation

/// `CloneInfoReading` with `getattrlist`, which on APFS reports the data stream of a file
/// (`ATTR_CMNEXT_CLONEID`), how many files share all of it (`ATTR_CMNEXT_CLONE_REFCNT`)
/// and whether the file may share only part of it (`ATTR_CMNEXT_EXT_FLAGS`).
public struct APFSCloneInfoReader: CloneInfoReading {
    /// Byte offsets in the buffer `getattrlist` fills: the returned length, the set of attributes
    /// returned, then each requested attribute in the order of its bit, aligned to 4 bytes.
    private enum Offset {
        static let returnedCommonAttributes = MemoryLayout<UInt32>.size
        static let returnedExtendedAttributes = returnedCommonAttributes + 4 * MemoryLayout<attrgroup_t>.size
        static let device = MemoryLayout<UInt32>.size + MemoryLayout<attribute_set_t>.size
        static let cloneID = device + MemoryLayout<dev_t>.size
        static let flags = cloneID + MemoryLayout<UInt64>.size
        static let cloneCount = flags + MemoryLayout<UInt64>.size
        static let end = cloneCount + MemoryLayout<UInt32>.size
    }

    private static let commonAttributes = attrgroup_t(ATTR_CMN_DEVID)
    private static let extendedAttributes = attrgroup_t(ATTR_CMNEXT_CLONEID)
        | attrgroup_t(ATTR_CMNEXT_EXT_FLAGS)
        | attrgroup_t(ATTR_CMNEXT_CLONE_REFCNT)

    public init() {}

    public func cloneInfo(of url: URL) -> CloneInfo? {
        var request = attrlist()
        request.bitmapcount = u_short(ATTR_BIT_MAP_COUNT)
        request.commonattr = attrgroup_t(ATTR_CMN_RETURNED_ATTRS) | Self.commonAttributes
        // With FSOPT_ATTR_CMN_EXTENDED, `forkattr` holds the extended common attributes.
        request.forkattr = Self.extendedAttributes
        // Unsupported attributes are packed with default values, so every offset stays fixed.
        let options = UInt32(FSOPT_ATTR_CMN_EXTENDED | FSOPT_PACK_INVAL_ATTRS | FSOPT_NOFOLLOW | FSOPT_RETURN_REALDEV)

        var buffer = [UInt8](repeating: 0, count: Offset.end)
        let result = buffer.withUnsafeMutableBytes { bytes in
            getattrlist(url.path, &request, bytes.baseAddress, bytes.count, options)
        }
        guard result == 0 else { return nil }
        return buffer.withUnsafeBytes(Self.cloneInfo(in:))
    }

    /// `nil` unless the volume returned every attribute, as volumes that don't track clones won't.
    private static func cloneInfo(in buffer: UnsafeRawBufferPointer) -> CloneInfo? {
        let returnedCommon = buffer.loadUnaligned(fromByteOffset: Offset.returnedCommonAttributes, as: attrgroup_t.self)
        let returnedExtended = buffer.loadUnaligned(fromByteOffset: Offset.returnedExtendedAttributes, as: attrgroup_t.self)
        guard
            returnedCommon & commonAttributes == commonAttributes,
            returnedExtended & extendedAttributes == extendedAttributes
        else { return nil }

        let cloneCount = buffer.loadUnaligned(fromByteOffset: Offset.cloneCount, as: UInt32.self)
        guard cloneCount > 0 else { return nil }
        let flags = buffer.loadUnaligned(fromByteOffset: Offset.flags, as: UInt64.self)
        let streamID = CloneInfo.StreamID(
            device: Int64(buffer.loadUnaligned(fromByteOffset: Offset.device, as: dev_t.self)),
            cloneID: buffer.loadUnaligned(fromByteOffset: Offset.cloneID, as: UInt64.self)
        )
        return CloneInfo(
            streamID: streamID,
            cloneCount: Int(cloneCount),
            mayShareSomeData: flags & UInt64(EF_MAY_SHARE_BLOCKS) != 0 && flags & UInt64(EF_SHARES_ALL_BLOCKS) == 0
        )
    }
}
