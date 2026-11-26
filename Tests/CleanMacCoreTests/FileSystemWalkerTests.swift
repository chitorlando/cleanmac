import Foundation
import CleanMacCore
import Testing

struct FileSystemWalkerTests {
    private func walkedNames(
        in folder: TemporaryFolder,
        excluding excluded: [URL] = [],
        includingHiddenItems includesHiddenItems: Bool = false
    ) -> Set<String> {
        var names: Set<String> = []
        FileSystemWalker(excludedDirectories: excluded, includesHiddenItems: includesHiddenItems).walk(folder.root) { record in
            names.insert(record.url.lastPathComponent)
            return true
        }
        return names
    }

    @Test func visitsRegularFilesInNestedFolders() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("top.bin")
        try folder.makeFile("Movies/Trips/beach.mov")

        #expect(walkedNames(in: folder) == ["top.bin", "beach.mov"])
    }

    @Test func reportsAllocatedSizeAndDates() throws {
        let folder = try TemporaryFolder()
        let accessDate = Date(timeIntervalSince1970: 1_600_000_000)
        try folder.makeFile("video.mov", size: 20_000, accessDate: accessDate)

        var records: [FileRecord] = []
        FileSystemWalker(excludedDirectories: []).walk(folder.root) { records.append($0); return true }

        let record = try #require(records.first)
        #expect(record.size >= 20_000)
        #expect(record.lastAccessDate == accessDate)
    }

    @Test func skipsHiddenFilesAndFolders() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("visible.bin")
        try folder.makeFile(".hidden.bin")
        try folder.makeFile(".cache/inside.bin")

        #expect(walkedNames(in: folder) == ["visible.bin"])
    }

    @Test func skipsFoldersFinderHides() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("visible.bin")
        try folder.makeFile("Library/Caches/cache.bin")
        try folder.hide("Library")

        #expect(walkedNames(in: folder) == ["visible.bin"])
    }

    @Test func walksHiddenFilesAndFoldersWhenAskedTo() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("visible.bin")
        try folder.makeFile(".hidden.bin")
        try folder.makeFile(".cache/inside.bin")
        try folder.makeFile("Library/Caches/cache.bin")
        try folder.hide("Library")

        let names = walkedNames(in: folder, includingHiddenItems: true)

        #expect(names == ["visible.bin", ".hidden.bin", "inside.bin", "cache.bin"])
    }

    @Test func neverEntersPackagesEvenWithHiddenItems() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Tool.app/Contents/MacOS/Tool")
        try folder.makeFile(".config/Helper.app/Contents/MacOS/Helper")
        try folder.makeFile(".config/settings.json")

        #expect(walkedNames(in: folder, includingHiddenItems: true) == ["settings.json"])
    }

    @Test func neverEntersNorOffersPackages() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Tool.app/Contents/MacOS/Tool")
        try folder.makeFile("Tool.app/Contents/Resources/big.bin")
        try folder.makeFile("notes.txt")

        #expect(walkedNames(in: folder) == ["notes.txt"])
    }

    @Test func reportsPackagesWholeWhenAskedToMeasureThem() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Tool.app/Contents/MacOS/Tool")
        try folder.makeFile("Tool.app/Contents/Resources/big.bin")
        try folder.makeFile("notes.txt")
        let calculator = FixedSizeCalculator(bytes: 7_000_000)

        var records: [FileRecord] = []
        FileSystemWalker(excludedDirectories: [], packageSizeCalculator: calculator).walk(folder.root) { record in
            records.append(record)
            return true
        }

        let package = try #require(records.first { $0.url.lastPathComponent == "Tool.app" })
        #expect(records.count == 2)
        #expect(package.isPackage)
        #expect(package.size == 7_000_000)
        #expect(calculator.measured.map(\.lastPathComponent) == ["Tool.app"])
        #expect(records.first { $0.url.lastPathComponent == "notes.txt" }?.isPackage == false)
    }

    @Test func measuresPackagesWithEverythingInside() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Tool.app/Contents/MacOS/Tool", size: 30_000)
        try folder.makeFile("Tool.app/Contents/Resources/big.bin", size: 50_000)

        var records: [FileRecord] = []
        FileSystemWalker(excludedDirectories: [], packageSizeCalculator: AllocatedSizeCalculator()).walk(folder.root) {
            records.append($0)
            return true
        }

        #expect(records.map(\.url.lastPathComponent) == ["Tool.app"])
        #expect((records.first?.size ?? 0) >= 80_000)
    }

    @Test func skipsExcludedFoldersEntirely() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Library/Caches/cache.bin")
        try folder.makeFile("Library/Application Support/data.bin")
        try folder.makeFile("Documents/report.pdf")

        let names = walkedNames(in: folder, excluding: [folder.root.appending(path: "Library")])

        #expect(names == ["report.pdf"])
    }

    @Test func excludesTheUserLibraryByDefault() {
        let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
        #expect(FileSystemWalker.userLibrary.standardizedFileURL == library.standardizedFileURL)
    }

    /// Its permissions keep everyone out of the folder but root, as macOS keeps apps without
    /// Full Disk Access out of private folders such as Mail.
    @Test(.enabled(if: getuid() != 0, "Root reads every folder."))
    func reportsTheFoldersItCannotRead() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Documents/report.pdf")
        try folder.makeFile("Private/secret.bin")
        try folder.makeFile("Private/Inside/deep.bin")
        let locked = try folder.setPermissions("Private", to: 0)
        defer { _ = try? folder.setPermissions("Private", to: 0o755) }

        var names: Set<String> = []
        var unreadable: [URL] = []
        FileSystemWalker(excludedDirectories: []).walk(
            folder.root,
            visit: { record in
                names.insert(record.url.lastPathComponent)
                return true
            },
            unreadable: { unreadable.append($0) }
        )

        #expect(names == ["report.pdf"])
        #expect(unreadable.map(\.standardizedFileURL.path) == [locked.standardizedFileURL.path])
    }

    @Test(.enabled(if: getuid() != 0, "Root reads every folder."))
    func reportsTheFolderItStartsFromWhenItCannotReadIt() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Private/secret.bin")
        let locked = try folder.setPermissions("Private", to: 0)
        defer { _ = try? folder.setPermissions("Private", to: 0o755) }

        var visited = 0
        var unreadable: [URL] = []
        FileSystemWalker(excludedDirectories: []).walk(
            locked,
            visit: { _ in
                visited += 1
                return true
            },
            unreadable: { unreadable.append($0) }
        )

        #expect(visited == 0)
        #expect(unreadable.map(\.lastPathComponent) == ["Private"])
    }

    @Test(.enabled(if: getuid() != 0, "Root reads every folder."))
    func neverReportsAnExcludedFolder() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Private/secret.bin")
        let locked = try folder.setPermissions("Private", to: 0)
        defer { _ = try? folder.setPermissions("Private", to: 0o755) }

        var unreadable: [URL] = []
        FileSystemWalker(excludedDirectories: [locked]).walk(
            folder.root,
            visit: { _ in true },
            unreadable: { unreadable.append($0) }
        )

        #expect(unreadable.isEmpty)
    }

    @Test func reportsNoFolderThatIsGone() throws {
        let folder = try TemporaryFolder()

        var unreadable: [URL] = []
        FileSystemWalker(excludedDirectories: []).walk(
            folder.root.appending(path: "Gone"),
            visit: { _ in true },
            unreadable: { unreadable.append($0) }
        )

        #expect(unreadable.isEmpty)
    }

    @Test func stopsWhenTheVisitorAsksTo() throws {
        let folder = try TemporaryFolder()
        for index in 0..<5 {
            try folder.makeFile("file\(index).bin")
        }

        var visited = 0
        FileSystemWalker(excludedDirectories: []).walk(folder.root) { _ in
            visited += 1
            return visited < 2
        }

        #expect(visited == 2)
    }
}
