import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

struct TrashJunkScannerTests {
    private func scanner(home: URL, volumes: URL, fullDiskAccess: Bool = true) -> TrashJunkScanner {
        TrashJunkScanner(reader: TrashSizeReader(
            home: home,
            volumes: volumes,
            userID: 501,
            sizer: UniformSizeCalculator(bytes: 100),
            fullDiskAccess: StubFullDiskAccess(granted: fullDiskAccess)
        ))
    }

    @Test func offersEachBinThatHoldsSomethingWithItsVolume() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("home/.Trash/report.pdf")
        try folder.makeFile("home/.Trash/notes.txt")
        try folder.makeFile("Volumes/Backup Disk/.Trashes/501/movie.mov")
        try folder.makeFolder("Volumes/Empty Disk/.Trashes/501")

        let result = await scanner(home: folder.root.appending(path: "home"), volumes: folder.root.appending(path: "Volumes")).scan()

        #expect(result.category == .trashBins)
        #expect(!result.needsFullDiskAccess)
        #expect(result.items.map(\.size) == [200, 100])
        let details = result.items.compactMap { result.detail(of: $0) }
        #expect(details.count == 2)
        #expect(details.map { volumeName(of: $0) } == [nil, "Backup Disk"])
    }

    @Test func saysWhenMacOSKeepsCleanMacOutOfTheTrash() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("home/.Trash/report.pdf")
        try folder.setPermissions("home/.Trash", to: 0)
        defer { _ = try? folder.setPermissions("home/.Trash", to: 0o755) }

        let result = await scanner(home: folder.root.appending(path: "home"), volumes: folder.root.appending(path: "Volumes")).scan()

        #expect(result.needsFullDiskAccess)
        #expect(result.items.isEmpty)
    }

    @Test func emptiesTheTrashForGoodAndWaitsForTheUserToPickIt() {
        #expect(JunkCategory.trashBins.removal == .emptyTrash)
        #expect(!JunkCategory.trashBins.preselectsItems)
    }

    private func volumeName(of detail: JunkItemDetail) -> String? {
        guard case .trashBin(let bin) = detail else { return nil }
        return bin.volumeName
    }
}
