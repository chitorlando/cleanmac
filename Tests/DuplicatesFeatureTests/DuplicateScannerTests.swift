import CleanMacCore
import DuplicatesFeature
import Foundation
import Testing

struct DuplicateScannerTests {
    private static let fileSize = 200_000

    /// Scanner of `home` whose walker skips the folders at the `excluded` paths, relative to it.
    private func scanner(
        for home: TemporaryFolder,
        excluding excluded: [String] = [],
        minimumSize: Int64 = 100_000,
        cloneInfoReader: any CloneInfoReading = APFSCloneInfoReader()
    ) -> DuplicateScanner {
        let excludedDirectories = excluded.map { home.root.appending(path: $0) }
        return DuplicateScanner(
            home: home.root,
            walker: FileSystemWalker(excludedDirectories: excludedDirectories),
            excludedDirectories: excludedDirectories,
            cloneInfoReader: cloneInfoReader,
            minimumSize: minimumSize
        )
    }

    private func events(of scanner: DuplicateScanner, scanning scope: DuplicateScanScope) async -> [DuplicateScanEvent] {
        var events: [DuplicateScanEvent] = []
        for await event in scanner.scan(scope) {
            events.append(event)
        }
        return events
    }

    private func scan(
        _ home: TemporaryFolder,
        scope: DuplicateScanScope = .home,
        excluding excluded: [String] = [],
        minimumSize: Int64 = 100_000,
        cloneInfoReader: any CloneInfoReading = APFSCloneInfoReader()
    ) async -> [DuplicateScanEvent] {
        let scanner = scanner(for: home, excluding: excluded, minimumSize: minimumSize, cloneInfoReader: cloneInfoReader)
        return await events(of: scanner, scanning: scope)
    }

    /// Paths of the copies in `groups`, relative to `home`, in order.
    ///
    /// The walk may spell the path of `home` another way, so what follows its name is taken.
    private func copies(in groups: [DuplicateGroup], of home: TemporaryFolder) -> [String] {
        let homeName = home.root.lastPathComponent + "/"
        return groups
            .flatMap(\.files)
            .map { $0.item.url.path.components(separatedBy: homeName).last ?? "" }
            .sorted()
    }

    private func groups(_ events: [DuplicateScanEvent]) -> [DuplicateGroup] {
        events.compactMap { event in
            if case .found(let group) = event { group } else { nil }
        }
    }

    @Test func groupsIdenticalFiles() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(content, to: "Documents/report.pdf")
        try folder.write(content, to: "Downloads/report.pdf")
        try folder.write(content, to: "Desktop/report copy.pdf")
        try folder.write(Data.pattern(count: Self.fileSize, seed: 2), to: "Documents/other.pdf")

        let found = groups(await scan(folder))

        #expect(found.count == 1)
        let group = try #require(found.first)
        #expect(Set(group.files.map(\.item.name)) == ["report.pdf", "report copy.pdf"])
        #expect(group.files.count == 3)
        #expect(group.recoverableSize == group.fileSize * 2)
        #expect(group.files.allSatisfy { $0.creationDate != nil })
    }

    @Test func ignoresFilesOfTheSameSizeWithDifferentContents() async throws {
        let folder = try TemporaryFolder()
        try folder.write(Data.pattern(count: Self.fileSize, seed: 1), to: "a.bin")
        try folder.write(Data.pattern(count: Self.fileSize, seed: 2), to: "b.bin")

        #expect(groups(await scan(folder)).isEmpty)
    }

    @Test func ignoresFilesThatOnlyShareTheirBeginning() async throws {
        let folder = try TemporaryFolder()
        var original = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(original, to: "a.bin")
        original[Self.fileSize - 1] ^= 0xFF
        try folder.write(original, to: "b.bin")

        #expect(groups(await scan(folder)).isEmpty)
    }

    @Test func ignoresFilesBelowTheMinimumSize() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: 1_000, seed: 1)
        try folder.write(content, to: "a.txt")
        try folder.write(content, to: "b.txt")

        #expect(groups(await scan(folder, minimumSize: DuplicateScanner.defaultMinimumSize)).isEmpty)
    }

    @Test func doesNotReportHardLinksAsCopies() async throws {
        let folder = try TemporaryFolder()
        let original = try folder.write(Data.pattern(count: Self.fileSize, seed: 1), to: "a.bin")
        try folder.makeHardLink("link.bin", to: original)

        #expect(groups(await scan(folder)).isEmpty)
    }

    @Test func tellsWhichCopiesHaveOtherNames() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let linked = try folder.write(content, to: "Documents/report.pdf")
        // A hidden name, which the walk skips like any hidden file.
        try folder.makeHardLink(".report.pdf", to: linked)
        try folder.write(content, to: "Downloads/report.pdf")

        let group = try #require(groups(await scan(folder)).first)

        #expect(group.files.count == 2)
        let linkedFolders = group.files.filter(\.hasOtherNames).map { $0.item.url.deletingLastPathComponent().lastPathComponent }
        #expect(linkedFolders == ["Documents"])
    }

    @Test func promisesNoSpaceForAFileWithANameTheScanSkips() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let linked = try folder.write(content, to: "Documents/report.pdf")
        try folder.makeHardLink(".report.pdf", to: linked)
        try folder.write(content, to: "Downloads/report.pdf")

        let group = try #require(groups(await scan(folder)).first)
        let linkedCopy = try #require(group.files.first { $0.hasOtherNames })

        #expect(group.physicalCopy(containing: linkedCopy)?.freeableSize == 0)
        #expect(group.recoverableSize == group.fileSize)
        #expect(DuplicateKeeper.keeper(in: group) == linkedCopy)
    }

    @Test func promisesNoSpaceForAFileWithTwoScannedNames() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let linked = try folder.write(content, to: "Documents/report.pdf")
        try folder.makeHardLink("report link.pdf", to: linked)
        try folder.write(content, to: "Downloads/report.pdf")

        let group = try #require(groups(await scan(folder)).first)
        let linkedCopy = try #require(group.files.first { $0.hasOtherNames })

        #expect(group.files.count == 2)
        #expect(group.physicalCopy(containing: linkedCopy)?.freeableSize == 0)
        #expect(group.recoverableSize == group.fileSize)
    }

    @Test func countsClonesOfEachOtherAsOnePhysicalCopy() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let original = try folder.write(content, to: "Documents/photo.heic")
        try folder.makeClone("Desktop/photo.heic", of: original)
        try folder.write(content, to: "Downloads/photo.heic")

        let group = try #require(groups(await scan(folder)).first)

        #expect(group.files.count == 3)
        #expect(group.physicalCopies.count == 2)
        #expect(group.recoverableSize == group.fileSize)
        let clonedFolders = group.files.filter(\.isClone).map { $0.item.url.deletingLastPathComponent().lastPathComponent }
        #expect(Set(clonedFolders) == ["Documents", "Desktop"])
    }

    @Test func doesNotCountSpaceWhenTheVolumeCannotTellHowDataIsShared() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(content, to: "a.bin")
        try folder.write(content, to: "b.bin")

        let group = try #require(groups(await scan(folder, cloneInfoReader: StubCloneInfoReader())).first)

        #expect(group.files.count == 2)
        #expect(group.files.allSatisfy { $0.cloneInfo == nil })
        #expect(group.recoverableSize == 0)
    }

    @Test func reportsScannedFilesAndHashedBytes() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(content, to: "a.bin")
        try folder.write(content, to: "b.bin")
        try folder.write(Data.pattern(count: 10, seed: 1), to: "small.txt")

        let progress = await scan(folder).compactMap { event in
            if case .progress(let progress) = event { progress } else { nil }
        }

        let last = try #require(progress.last)
        #expect(last.scannedFiles == 3)
        // Two partial hashes of 64 KB, then two full hashes.
        #expect(last.hashedBytes == 2 * 65_536 + 2 * Int64(Self.fileSize))
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsWalkingWhenTheConsumerStopsListening() async {
        let walker = EndlessWalker()
        let scanner = DuplicateScanner(
            home: URL(filePath: "/tmp"),
            walker: walker,
            excludedDirectories: [],
            progressInterval: 1
        )

        for await _ in scanner.scan(.home) {
            break
        }

        for await _ in walker.finished {}
    }

    // MARK: Scanning one folder

    @Test func scansOnlyTheChosenFolder() async throws {
        let home = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try home.write(content, to: "Documents/report.pdf")
        try home.write(content, to: "Downloads/report.pdf")
        try home.write(content, to: "Downloads/Old/report.pdf")
        let downloads = home.root.appending(path: "Downloads")

        let wholeHome = groups(await scan(home))
        let onlyDownloads = groups(await scan(home, scope: .folder(downloads)))

        #expect(copies(in: wholeHome, of: home) == ["Documents/report.pdf", "Downloads/Old/report.pdf", "Downloads/report.pdf"])
        #expect(copies(in: onlyDownloads, of: home) == ["Downloads/Old/report.pdf", "Downloads/report.pdf"])
    }

    @Test func countsOnlyTheFilesOfTheChosenFolder() async throws {
        let home = try TemporaryFolder()
        try home.write(Data.pattern(count: 10, seed: 1), to: "Documents/notes.txt")
        try home.write(Data.pattern(count: 10, seed: 2), to: "Downloads/a.txt")
        try home.write(Data.pattern(count: 10, seed: 3), to: "Downloads/b.txt")

        let events = await scan(home, scope: .folder(home.root.appending(path: "Downloads")))

        #expect(events.last == .progress(DuplicateScanProgress(scannedFiles: 2)))
    }

    /// Hidden items, packages and excluded folders are left out wherever the walk starts.
    @Test func skipsInsideTheChosenFolderWhatTheHomeScanSkips() async throws {
        let home = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try home.write(content, to: "Projects/site/logo.png")
        try home.write(content, to: "Projects/site/logo copy.png")
        try home.write(content, to: "Projects/.git/objects/logo")
        try home.write(content, to: "Projects/Editor.app/Contents/Resources/logo.png")
        try home.write(content, to: "Projects/Cache/logo.png")
        try home.write(content, to: "Projects/Secret/logo.png")
        try home.hide("Projects/Secret")
        let projects = home.root.appending(path: "Projects")

        let wholeHome = groups(await scan(home, excluding: ["Projects/Cache"]))
        let onlyProjects = groups(await scan(home, scope: .folder(projects), excluding: ["Projects/Cache"]))

        #expect(copies(in: onlyProjects, of: home) == ["Projects/site/logo copy.png", "Projects/site/logo.png"])
        #expect(copies(in: onlyProjects, of: home) == copies(in: wholeHome, of: home))
    }

    /// Every folder here holds two identical files that a walk started inside it would find.
    @Test func reportsNothingForAFolderTheHomeScanNeverWalks() async throws {
        let home = try TemporaryFolder()
        let elsewhere = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let unwalkedFolders = [
            "Library/Caches",
            ".Trash",
            ".config/tool",
            "Secret",
            "Secret/Photos",
            "Editor.app",
            "Editor.app/Contents/Resources"
        ]
        for folder in unwalkedFolders {
            try home.write(content, to: "\(folder)/a.bin")
            try home.write(content, to: "\(folder)/b.bin")
        }
        try home.hide("Secret")
        try elsewhere.write(content, to: "Photos/a.bin")
        try elsewhere.write(content, to: "Photos/b.bin")
        try home.makeSymbolicLink("Elsewhere", to: elsewhere.root)
        let scanner = scanner(for: home, excluding: ["Library"])
        let unwalked = unwalkedFolders.map { home.root.appending(path: $0) } + [
            home.root.appending(path: "Library"),
            home.root.appending(path: "library/Caches"),
            home.root.appending(path: "Elsewhere"),
            home.root.appending(path: "Elsewhere/Photos"),
            elsewhere.root.appending(path: "Photos"),
            home.root.appending(path: "Editor.app/Contents/Resources/a.bin"),
            home.root.appending(path: "Gone")
        ]

        for folder in unwalked {
            let events = await events(of: scanner, scanning: .folder(folder))
            #expect(scanner.scope(limitedTo: folder) == nil, "\(folder.path)")
            #expect(events.isEmpty, "\(folder.path)")
        }
        #expect(groups(await events(of: scanner, scanning: .home)).isEmpty)
    }

    @Test func givesTheScopeOfAFolderItCanScanOnItsOwn() throws {
        let home = try TemporaryFolder()
        let downloads = try home.makeFolder("Downloads")
        let scanner = scanner(for: home, excluding: ["Library"])

        #expect(scanner.scope(limitedTo: downloads)?.folder?.path == downloads.path)
        #expect(scanner.scope(limitedTo: home.root) == .home)
    }

    @Test func theHomeFolderChosenAsAFolderIsScannedWhole() async throws {
        let home = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try home.write(content, to: "Documents/report.pdf")
        try home.write(content, to: "Downloads/report.pdf")

        let found = groups(await scan(home, scope: .folder(home.root)))

        #expect(copies(in: found, of: home) == ["Documents/report.pdf", "Downloads/report.pdf"])
    }
}
