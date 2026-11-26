import CleanMacCore
import Foundation
import Testing

struct TrashSizeReaderTests {
    /// Answers Full Disk Access with what the test sets.
    private struct StubFullDiskAccess: FullDiskAccessChecking {
        let granted: Bool

        func hasFullDiskAccess() -> Bool { granted }
    }

    private let userID: uid_t = 501

    private func reader(
        in folder: TemporaryFolder,
        sizer: FixedSizeCalculator = FixedSizeCalculator(bytes: 10),
        fullDiskAccess: Bool = true
    ) -> TrashSizeReader {
        TrashSizeReader(
            home: folder.root.appending(path: "home"),
            volumes: folder.root.appending(path: "Volumes"),
            userID: userID,
            sizer: sizer,
            fullDiskAccess: StubFullDiskAccess(granted: fullDiskAccess)
        )
    }

    /// Each bin read, as its path inside the folder, its volume and its size, or `nil` when the
    /// Trash is unreadable. Listing a folder may spell the temporary folder with `/private`.
    private func bins(of usage: TrashUsage, in folder: TemporaryFolder) -> [String]? {
        guard case .readable(let usages) = usage else { return nil }
        return usages.map { usage in
            let components = usage.bin.url.pathComponents
            let start = components.lastIndex(of: folder.root.lastPathComponent).map { $0 + 1 } ?? 0
            let path = components[start...].joined(separator: "/")
            return "\(path) | \(usage.bin.volumeName ?? "home") | \(usage.size)"
        }
    }

    @Test func measuresTheHomeBinAndTheUsersBinOnEachVolume() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("home/.Trash/report.pdf")
        try folder.makeFile("home/.Trash/Old Photos/one.jpg")
        try folder.makeFile("Volumes/Backup Disk/.Trashes/501/movie.mov")
        try folder.makeFile("Volumes/Archive/.Trashes/501/notes.txt")

        let usage = reader(in: folder).read()

        #expect(bins(of: usage, in: folder) == [
            "home/.Trash | home | 20",
            "Volumes/Archive/.Trashes/501 | Archive | 10",
            "Volumes/Backup Disk/.Trashes/501 | Backup Disk | 10"
        ])
    }

    @Test func neverLooksAtTheBinsOfOtherUsers() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Volumes/Shared/.Trashes/502/theirs.mov")
        let sizer = FixedSizeCalculator(bytes: 10)

        let usage = reader(in: folder, sizer: sizer).read()

        #expect(usage == .readable([]))
        #expect(sizer.measured.isEmpty)
    }

    @Test func leavesOutBinsThatOnlyHoldFinderFiles() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("home/.Trash/.DS_Store")
        try folder.makeFolder("Volumes/Empty Disk/.Trashes/501")

        #expect(reader(in: folder).read() == .readable([]))
    }

    @Test func leavesOutLinksToOtherVolumes() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Startup/.Trashes/501/system.log")
        try folder.makeFolder("Volumes")
        try folder.makeLink("Volumes/Macintosh HD", to: "Startup")

        #expect(reader(in: folder).read() == .readable([]))
    }

    /// Looking inside an external volume without Full Disk Access makes macOS ask the user.
    @Test func looksOnlyAtTheHomeBinWithoutFullDiskAccess() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("home/.Trash/report.pdf")
        try folder.makeFile("Volumes/Backup Disk/.Trashes/501/movie.mov")
        let sizer = FixedSizeCalculator(bytes: 10)

        let usage = reader(in: folder, sizer: sizer, fullDiskAccess: false).read()

        #expect(bins(of: usage, in: folder) == ["home/.Trash | home | 10"])
        #expect(sizer.measured.map(\.lastPathComponent) == ["report.pdf"])
    }

    @Test func reportsTheTrashAsUnreadableWhenMacOSKeepsCleanMacOut() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("home/.Trash/report.pdf")
        try folder.setPermissions("home/.Trash", to: 0)
        defer { _ = try? folder.setPermissions("home/.Trash", to: 0o755) }
        let sizer = FixedSizeCalculator(bytes: 10)

        #expect(reader(in: folder, sizer: sizer).read() == .unreadable)
        #expect(sizer.measured.isEmpty)
    }

    @Test func findsNothingWithoutATrash() throws {
        let folder = try TemporaryFolder()

        #expect(reader(in: folder).read() == .readable([]))
    }
}
