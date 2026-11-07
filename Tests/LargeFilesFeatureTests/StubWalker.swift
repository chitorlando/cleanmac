import CleanMacCore
import Foundation
import LargeFilesFeature

/// Walks a fixed list of records, as if they were on disk.
struct StubWalker: FileWalking {
    let records: [FileRecord]

    init(sizes: [Int64]) {
        records = sizes.enumerated().map { index, size in
            FileRecord(
                url: URL(filePath: "/tmp/file\(index).mov"),
                size: size,
                accessDate: nil,
                modificationDate: nil
            )
        }
    }

    func walk(_ root: URL, visit: (FileRecord) -> Bool) {
        for record in records where !visit(record) {
            return
        }
    }
}
