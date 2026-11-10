import Darwin

/// A `getattrlist` request for what a volume knows about the data of a file: its data stream
/// (`ATTR_CMNEXT_CLONEID`), whether it may share only part of it (`ATTR_CMNEXT_EXT_FLAGS`)
/// and, when asked to count clones, how many files share all of it (`ATTR_CMNEXT_CLONE_REFCNT`).
///
/// When it doesn't count clones it asks instead for the space the file takes up
/// (`ATTR_FILE_ALLOCSIZE`) and the part of it no other file shares (`ATTR_CMNEXT_PRIVATESIZE`),
/// which tell a file that had clones from one that still has them.
struct CloneAttributeRequest: Sendable {
    enum Outcome: Equatable, Sendable {
        case attributes(CloneAttributes)
        /// The file can't be inspected, or its volume didn't return every attribute, as volumes
        /// that don't track clones won't.
        case unavailable
        /// The system doesn't know one of the attributes asked for.
        case rejected
    }

    /// Byte offsets of the start of the buffer `getattrlist` fills: the returned length and the
    /// set of attributes returned, which holds one group of bits per kind of attribute.
    private enum Offset {
        static let returnedCommonAttributes = MemoryLayout<UInt32>.size
        static let returnedFileAttributes = returnedCommonAttributes + 3 * MemoryLayout<attrgroup_t>.size
        static let returnedExtendedAttributes = returnedCommonAttributes + 4 * MemoryLayout<attrgroup_t>.size
        static let values = MemoryLayout<UInt32>.size + MemoryLayout<attribute_set_t>.size
    }

    private static let commonAttributes = attrgroup_t(ATTR_CMN_DEVID)
    private static let streamAttributes = attrgroup_t(ATTR_CMNEXT_CLONEID) | attrgroup_t(ATTR_CMNEXT_EXT_FLAGS)
    private static let countAttribute = attrgroup_t(ATTR_CMNEXT_CLONE_REFCNT)
    private static let allocatedSizeAttribute = attrgroup_t(ATTR_FILE_ALLOCSIZE)
    private static let privateSizeAttribute = attrgroup_t(ATTR_CMNEXT_PRIVATESIZE)

    /// Whether to ask how many files share the data, which macOS 13 can't answer: it rejects
    /// the whole request instead of leaving the count out.
    let countsClones: Bool

    /// The extended attributes a volume must return for the file to tell anything. The sizes
    /// aren't among them: a volume that leaves them out still tells the rest.
    private var requiredExtendedAttributes: attrgroup_t {
        countsClones ? Self.streamAttributes | Self.countAttribute : Self.streamAttributes
    }

    /// The values come after the start of the buffer, each aligned to 4 bytes: the common
    /// attributes, the file's and the extended common ones, each kind in the order of its bits.
    private var bufferSize: Int {
        let stream = MemoryLayout<dev_t>.size + 2 * MemoryLayout<UInt64>.size
        let rest = countsClones ? MemoryLayout<UInt32>.size : 2 * MemoryLayout<off_t>.size
        return Offset.values + stream + rest
    }

    func send(for path: String) -> Outcome {
        var request = attrlist()
        request.bitmapcount = u_short(ATTR_BIT_MAP_COUNT)
        request.commonattr = attrgroup_t(ATTR_CMN_RETURNED_ATTRS) | Self.commonAttributes
        request.fileattr = countsClones ? 0 : Self.allocatedSizeAttribute
        // With FSOPT_ATTR_CMN_EXTENDED, `forkattr` holds the extended common attributes.
        request.forkattr = countsClones ? requiredExtendedAttributes : Self.streamAttributes | Self.privateSizeAttribute
        // Unsupported attributes are packed with default values, so every offset stays fixed.
        let options = UInt32(FSOPT_ATTR_CMN_EXTENDED | FSOPT_PACK_INVAL_ATTRS | FSOPT_NOFOLLOW | FSOPT_RETURN_REALDEV)

        var buffer = [UInt8](repeating: 0, count: bufferSize)
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

    /// `nil` unless the volume returned every attribute the file needs to tell anything.
    private func attributes(in buffer: UnsafeRawBufferPointer) -> CloneAttributes? {
        let returnedCommon = buffer.loadUnaligned(fromByteOffset: Offset.returnedCommonAttributes, as: attrgroup_t.self)
        let returnedFile = buffer.loadUnaligned(fromByteOffset: Offset.returnedFileAttributes, as: attrgroup_t.self)
        let returnedExtended = buffer.loadUnaligned(fromByteOffset: Offset.returnedExtendedAttributes, as: attrgroup_t.self)
        guard
            returnedCommon & Self.commonAttributes == Self.commonAttributes,
            returnedExtended & requiredExtendedAttributes == requiredExtendedAttributes
        else { return nil }

        // The sizes, when asked for, come between the device and the data stream, and take up
        // their place even if the volume doesn't return them. The count comes last.
        let allocatedSizeOffset = Offset.values + MemoryLayout<dev_t>.size
        let privateSizeOffset = allocatedSizeOffset + MemoryLayout<off_t>.size
        let cloneIDOffset = countsClones ? allocatedSizeOffset : privateSizeOffset + MemoryLayout<off_t>.size
        let flagsOffset = cloneIDOffset + MemoryLayout<UInt64>.size
        let countOffset = flagsOffset + MemoryLayout<UInt64>.size

        let returnsAllocatedSize = !countsClones && returnedFile & Self.allocatedSizeAttribute != 0
        let returnsPrivateSize = !countsClones && returnedExtended & Self.privateSizeAttribute != 0
        return CloneAttributes(
            device: Int64(buffer.loadUnaligned(fromByteOffset: Offset.values, as: dev_t.self)),
            cloneID: buffer.loadUnaligned(fromByteOffset: cloneIDOffset, as: UInt64.self),
            flags: buffer.loadUnaligned(fromByteOffset: flagsOffset, as: UInt64.self),
            referenceCount: countsClones
                ? Int(buffer.loadUnaligned(fromByteOffset: countOffset, as: UInt32.self))
                : nil,
            allocatedSize: returnsAllocatedSize
                ? buffer.loadUnaligned(fromByteOffset: allocatedSizeOffset, as: off_t.self)
                : nil,
            privateSize: returnsPrivateSize
                ? buffer.loadUnaligned(fromByteOffset: privateSizeOffset, as: off_t.self)
                : nil
        )
    }
}
