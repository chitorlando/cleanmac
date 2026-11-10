import Darwin

/// A `getattrlist` request for what a volume knows about the data of a file: its data stream
/// (`ATTR_CMNEXT_CLONEID`), whether it may share only part of it (`ATTR_CMNEXT_EXT_FLAGS`)
/// and, when asked to count clones, how many files share all of it (`ATTR_CMNEXT_CLONE_REFCNT`).
struct CloneAttributeRequest: Sendable {
    enum Outcome: Equatable, Sendable {
        case attributes(CloneAttributes)
        /// The file can't be inspected, or its volume didn't return every attribute, as volumes
        /// that don't track clones won't.
        case unavailable
        /// The system doesn't know one of the attributes asked for.
        case rejected
    }

    /// Byte offsets in the buffer `getattrlist` fills: the returned length, the set of attributes
    /// returned, then each requested attribute in the order of its bit, aligned to 4 bytes.
    /// The count of clones has the highest bit, so leaving it out moves no other attribute.
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

    /// Whether to ask how many files share the data, which macOS 13 can't answer: it rejects
    /// the whole request instead of leaving the count out.
    let countsClones: Bool

    private var extendedAttributes: attrgroup_t {
        let stream = attrgroup_t(ATTR_CMNEXT_CLONEID) | attrgroup_t(ATTR_CMNEXT_EXT_FLAGS)
        return countsClones ? stream | attrgroup_t(ATTR_CMNEXT_CLONE_REFCNT) : stream
    }

    func send(for path: String) -> Outcome {
        var request = attrlist()
        request.bitmapcount = u_short(ATTR_BIT_MAP_COUNT)
        request.commonattr = attrgroup_t(ATTR_CMN_RETURNED_ATTRS) | Self.commonAttributes
        // With FSOPT_ATTR_CMN_EXTENDED, `forkattr` holds the extended common attributes.
        request.forkattr = extendedAttributes
        // Unsupported attributes are packed with default values, so every offset stays fixed.
        let options = UInt32(FSOPT_ATTR_CMN_EXTENDED | FSOPT_PACK_INVAL_ATTRS | FSOPT_NOFOLLOW | FSOPT_RETURN_REALDEV)

        var buffer = [UInt8](repeating: 0, count: Offset.end)
        let errorCode = buffer.withUnsafeMutableBytes { bytes in
            getattrlist(path, &request, bytes.baseAddress, bytes.count, options) == 0 ? 0 : errno
        }
        switch errorCode {
        case 0:
            return buffer.withUnsafeBytes { attributes(in: $0) }.map(Outcome.attributes) ?? .unavailable
        case EINVAL:
            return .rejected
        default:
            return .unavailable
        }
    }

    /// `nil` unless the volume returned every attribute asked for.
    private func attributes(in buffer: UnsafeRawBufferPointer) -> CloneAttributes? {
        let returnedCommon = buffer.loadUnaligned(fromByteOffset: Offset.returnedCommonAttributes, as: attrgroup_t.self)
        let returnedExtended = buffer.loadUnaligned(fromByteOffset: Offset.returnedExtendedAttributes, as: attrgroup_t.self)
        guard
            returnedCommon & Self.commonAttributes == Self.commonAttributes,
            returnedExtended & extendedAttributes == extendedAttributes
        else { return nil }

        return CloneAttributes(
            device: Int64(buffer.loadUnaligned(fromByteOffset: Offset.device, as: dev_t.self)),
            cloneID: buffer.loadUnaligned(fromByteOffset: Offset.cloneID, as: UInt64.self),
            flags: buffer.loadUnaligned(fromByteOffset: Offset.flags, as: UInt64.self),
            referenceCount: countsClones
                ? Int(buffer.loadUnaligned(fromByteOffset: Offset.cloneCount, as: UInt32.self))
                : nil,
            allocatedSize: nil,
            privateSize: nil
        )
    }
}
