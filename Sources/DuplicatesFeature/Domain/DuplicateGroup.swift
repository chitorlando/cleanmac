import CleanMacCore

/// Files with identical contents.
///
/// Copies that are APFS clones of each other share their data on disk, so together they
/// form a single physical copy, and removing only some of them frees nothing.
public struct DuplicateGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let files: [DuplicateFile]
    /// Space each copy occupies on disk.
    public let fileSize: Int64
    /// The copies grouped by the data they keep on disk, in the order of their first file.
    public let physicalCopies: [PhysicalCopy]

    public init(id: String, files: [DuplicateFile], fileSize: Int64) {
        self.id = id
        self.files = files
        self.fileSize = fileSize
        physicalCopies = Self.physicalCopies(of: files, fileSize: fileSize)
    }

    /// Space freed by keeping one physical copy, the one whose removal would free the least,
    /// and removing every other copy.
    public var recoverableSize: Int64 {
        let sizes = physicalCopies.map(\.freeableSize)
        return sizes.reduce(0, +) - (sizes.min() ?? 0)
    }

    /// Every copy shares the same data on disk, so removing any of them frees no space.
    public var isMadeOfClones: Bool { physicalCopies.count == 1 }

    /// Name of the first copy, to label the group.
    public var name: String { files.first?.item.name ?? "" }

    public var items: [CleanableItem] { files.map(\.item) }

    /// The physical copy that `file` belongs to.
    public func physicalCopy(containing file: DuplicateFile) -> PhysicalCopy? {
        physicalCopies.first { copy in copy.files.contains { $0.id == file.id } }
    }

    /// Space freed by removing the given copies: the data of every physical copy whose files are all removed.
    public func freedSize(removing removedIDs: Set<CleanableItem.ID>) -> Int64 {
        physicalCopies
            .filter { copy in copy.files.allSatisfy { removedIDs.contains($0.id) } }
            .map(\.freeableSize)
            .reduce(0, +)
    }

    func withCloneInfo(from reader: any CloneInfoReading) -> DuplicateGroup {
        DuplicateGroup(
            id: id,
            files: files.map { $0.withCloneInfo(reader.cloneInfo(of: $0.item.url)) },
            fileSize: fileSize
        )
    }

    /// Copies without clone information stand alone.
    private static func physicalCopies(of files: [DuplicateFile], fileSize: Int64) -> [PhysicalCopy] {
        var groupedFiles: [[DuplicateFile]] = []
        var indexByStream: [CloneInfo.StreamID: Int] = [:]
        for file in files {
            guard let streamID = file.cloneInfo?.streamID else {
                groupedFiles.append([file])
                continue
            }
            if let index = indexByStream[streamID] {
                groupedFiles[index].append(file)
            } else {
                indexByStream[streamID] = groupedFiles.count
                groupedFiles.append([file])
            }
        }
        return groupedFiles.map { PhysicalCopy(files: $0, fileSize: fileSize) }
    }
}
