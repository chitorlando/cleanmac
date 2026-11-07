import Darwin
import Foundation

/// `FileMetadataReading` backed by `lstat`, which doesn't follow symbolic links.
public struct LocalFileMetadataReader: FileMetadataReading {
    public init() {}

    public func metadata(of url: URL) -> FileMetadata? {
        var info = stat()
        guard lstat(url.path, &info) == 0 else { return nil }
        let birth = info.st_birthtimespec
        return FileMetadata(
            identity: FileMetadata.Identity(device: Int64(info.st_dev), inode: UInt64(info.st_ino)),
            creationDate: Date(timeIntervalSince1970: TimeInterval(birth.tv_sec) + TimeInterval(birth.tv_nsec) / 1e9)
        )
    }
}
