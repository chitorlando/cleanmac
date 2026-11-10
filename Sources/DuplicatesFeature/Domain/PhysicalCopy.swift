/// The copies of a group that keep their data in the same place on disk: APFS clones of
/// each other, or a single copy with its own data.
public struct PhysicalCopy: Hashable, Sendable {
    public let files: [DuplicateFile]
    /// Space freed once every file of this copy is removed.
    ///
    /// Zero whenever that isn't certain: when a volume couldn't tell how the data is shared
    /// or how many files share it, when files outside the group share it too, or when part
    /// of it may be shared.
    public let freeableSize: Int64

    init(files: [DuplicateFile], fileSize: Int64) {
        self.files = files
        freeableSize = Self.freesItsData(files) ? fileSize : 0
    }

    private static func freesItsData(_ files: [DuplicateFile]) -> Bool {
        let infos = files.compactMap(\.cloneInfo)
        guard infos.count == files.count, let info = infos.first else { return false }
        return info.cloneCount == files.count && !infos.contains(where: \.mayShareSomeData)
    }
}
