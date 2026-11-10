import Foundation

/// `CloneInfoReading` with `getattrlist`, which on APFS reports the data stream of a file,
/// how many files share all of it and whether the file may share only part of it.
///
/// macOS 13 can't count the files that share a data stream and rejects the request that asks
/// for the count, so the reader then asks again without it. What a file shares is then known
/// only in part (see `CloneAttributes.cloneInfo`).
public struct APFSCloneInfoReader: CloneInfoReading {
    public init() {}

    public func cloneInfo(of url: URL) -> CloneInfo? {
        let path = url.path
        var outcome = CloneAttributeRequest(countsClones: true).send(for: path)
        if outcome == .rejected {
            outcome = CloneAttributeRequest(countsClones: false).send(for: path)
        }
        guard case .attributes(let attributes) = outcome else { return nil }
        return attributes.cloneInfo
    }
}
