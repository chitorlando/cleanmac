import CleanMacCore
import DuplicatesFeature
import Foundation

/// Builders for duplicate files and groups that never touch the disk.
enum DuplicateFixtures {
    /// How a fixture copy keeps its data on disk.
    enum Storage {
        /// Its data is its own.
        case own
        /// Shares all of its data with the other files of `stream`, `count` files in total.
        case clone(stream: UInt64, count: Int)
        /// Shares data with the other files of `stream` on a system that can't count them, as
        /// macOS 13 reports any clone: it may share only part of it, with any number of files.
        case uncountedClone(stream: UInt64)
        /// May share part of its data with other files.
        case partlyShared
        /// The volume couldn't tell.
        case unknown
    }

    static let fileSize: Int64 = 5_000_000
    static let device: Int64 = 1

    static func date(_ day: Int) -> Date {
        Date(timeIntervalSince1970: 1_767_225_600 + TimeInterval(day) * 86_400)
    }

    static func file(_ path: String, created: Date? = date(1), storage: Storage = .own) -> DuplicateFile {
        let url = URL(filePath: path)
        return DuplicateFile(
            item: CleanableItem(url: url, size: fileSize),
            creationDate: created,
            cloneInfo: cloneInfo(for: storage, url: url)
        )
    }

    static func group(_ files: DuplicateFile..., id: String? = nil) -> DuplicateGroup {
        DuplicateGroup(id: id ?? files.first?.item.name ?? "", files: files, fileSize: fileSize)
    }

    private static func cloneInfo(for storage: Storage, url: URL) -> CloneInfo? {
        switch storage {
        case .own:
            CloneInfo(streamID: ownStream(of: url), cloneCount: 1, mayShareSomeData: false)
        case let .clone(stream, count):
            CloneInfo(streamID: CloneInfo.StreamID(device: device, cloneID: stream), cloneCount: count, mayShareSomeData: false)
        case let .uncountedClone(stream):
            CloneInfo(streamID: CloneInfo.StreamID(device: device, cloneID: stream), cloneCount: nil, mayShareSomeData: true)
        case .partlyShared:
            CloneInfo(streamID: ownStream(of: url), cloneCount: 1, mayShareSomeData: true)
        case .unknown:
            nil
        }
    }

    /// A stream no other fixture uses: clone streams are small numbers, these are on another device.
    private static func ownStream(of url: URL) -> CloneInfo.StreamID {
        CloneInfo.StreamID(device: device + 1, cloneID: UInt64(bitPattern: Int64(url.path.hashValue)))
    }
}
