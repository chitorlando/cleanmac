import CleanMacCore
import Foundation

/// Walks a fixed list of records, as if they were on disk.
struct StubWalker: FileWalking {
    let records: [FileRecord]

    /// Files named `file0.bin`, `file1.bin`… in `root`, with the given sizes.
    init(root: URL, sizes: [Int64]) {
        records = sizes.enumerated().map { index, size in
            FileRecord(url: root.appending(path: "file\(index).bin"), size: size, accessDate: nil, modificationDate: nil)
        }
    }

    func walk(_ root: URL, visit: (FileRecord) -> Bool) {
        for record in records where !visit(record) {
            return
        }
    }
}
