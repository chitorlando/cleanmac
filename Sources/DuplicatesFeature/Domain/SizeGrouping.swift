import CleanMacCore

/// First, cheap pass: only files of the same size can be identical.
enum SizeGrouping {
    /// Groups of two or more files with the same size, largest size first.
    static func candidateGroups(_ records: [FileRecord]) -> [[FileRecord]] {
        Dictionary(grouping: records, by: \.size)
            .filter { $0.value.count > 1 }
            .sorted { $0.key > $1.key }
            .map(\.value)
    }
}
