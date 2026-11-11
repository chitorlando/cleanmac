import CleanMacCore

/// A file that may have identical copies, with the metadata read once for it.
struct DuplicateCandidate: Sendable {
    let record: FileRecord
    let metadata: FileMetadata

    var file: DuplicateFile {
        DuplicateFile(
            item: CleanableItem(url: record.url, size: record.size),
            creationDate: metadata.creationDate,
            cloneInfo: nil,
            linkCount: metadata.linkCount
        )
    }

    /// Reads the metadata of each record and keeps one path per file,
    /// so hard links to the same data are never reported as copies.
    static func unique(_ records: [FileRecord], reader: any FileMetadataReading) -> [DuplicateCandidate] {
        var seen: Set<FileMetadata.Identity> = []
        return records.compactMap { record in
            guard
                let metadata = reader.metadata(of: record.url),
                seen.insert(metadata.identity).inserted
            else { return nil }
            return DuplicateCandidate(record: record, metadata: metadata)
        }
    }
}
