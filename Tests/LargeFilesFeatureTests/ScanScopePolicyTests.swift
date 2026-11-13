import Foundation
import LargeFilesFeature
import Testing

struct ScanScopePolicyTests {
    /// Policy for a home folder whose `Library` is excluded, as the app excludes `~/Library`.
    private func makePolicy(home: TemporaryFolder) -> ScanScopePolicy {
        ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
    }

    /// Path of the folder the scan would be limited to when asked for `path`, relative to the home.
    private func scopedPath(_ path: String, in home: TemporaryFolder) -> String? {
        makePolicy(home: home).scope(limitedTo: home.root.appending(path: path))?.folder?.path
    }

    private func path(_ path: String, in home: TemporaryFolder) -> String {
        home.root.appending(path: path).path
    }

    // MARK: Folders the scan can be limited to

    @Test func limitsTheScanToAFolderOfTheHome() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Movies/Trips")

        #expect(scopedPath("Movies", in: home) == path("Movies", in: home))
        #expect(scopedPath("Movies/Trips", in: home) == path("Movies/Trips", in: home))
    }

    @Test func theHomeFolderIsTheWholeHome() throws {
        let home = try TemporaryFolder()

        #expect(makePolicy(home: home).scope(limitedTo: home.root) == .home)
    }

    @Test func findsTheRealFolderBehindASymbolicLinkOnTheWay() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Movies/Trips")
        try home.makeLink("Shortcut", to: "Movies")

        #expect(scopedPath("Shortcut/Trips", in: home) == path("Movies/Trips", in: home))
    }

    // MARK: What is not a folder

    @Test func refusesAFile() throws {
        let home = try TemporaryFolder()
        try home.makeFile("Movies/trip.mov")

        #expect(scopedPath("Movies/trip.mov", in: home) == nil)
    }

    @Test func refusesAFolderThatIsGone() throws {
        let home = try TemporaryFolder()

        #expect(scopedPath("Movies", in: home) == nil)
    }

    @Test func refusesASymbolicLinkToAFolder() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Movies")
        try home.makeLink("Shortcut", to: "Movies")

        #expect(scopedPath("Shortcut", in: home) == nil)
    }

    // MARK: Folders the scan of the home folder never enters

    @Test func refusesHiddenFoldersAndWhatIsInside() throws {
        let home = try TemporaryFolder()
        try home.makeFolder(".cache/downloads")

        #expect(scopedPath(".cache", in: home) == nil)
        #expect(scopedPath(".cache/downloads", in: home) == nil)
    }

    @Test func refusesFoldersHiddenWithTheFinderFlag() throws {
        let home = try TemporaryFolder()
        var hidden = try home.makeFolder("Private")
        try home.makeFolder("Private/Movies")
        var values = URLResourceValues()
        values.isHidden = true
        try hidden.setResourceValues(values)

        #expect(scopedPath("Private", in: home) == nil)
        #expect(scopedPath("Private/Movies", in: home) == nil)
    }

    @Test func refusesPackagesAndWhatIsInside() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Applications/Editor.app/Contents/Resources")

        #expect(scopedPath("Applications", in: home) != nil)
        #expect(scopedPath("Applications/Editor.app", in: home) == nil)
        #expect(scopedPath("Applications/Editor.app/Contents/Resources", in: home) == nil)
    }

    @Test func refusesExcludedDirectoriesAndWhatIsInside() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Library/Caches/Browser")

        #expect(scopedPath("Library", in: home) == nil)
        #expect(scopedPath("Library/Caches/Browser", in: home) == nil)
    }

    /// On a disk that ignores case, as most Macs have, another spelling reaches the same folder.
    /// On one that doesn't, there is no such folder. Neither can be scanned.
    @Test func refusesAnExcludedDirectoryWrittenInAnotherCase() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Library/Caches")

        #expect(scopedPath("LIBRARY/caches", in: home) == nil)
    }

    @Test func refusesAnExcludedDirectoryReachedThroughASymbolicLink() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Library/Caches")
        try home.makeLink("Shortcut", to: "Library")

        #expect(scopedPath("Shortcut/Caches", in: home) == nil)
    }

    @Test func refusesFoldersOutsideTheHome() throws {
        let disk = try TemporaryFolder()
        let home = try disk.makeFolder("Users/test")
        let elsewhere = try disk.makeFolder("Applications")
        let policy = ScanScopePolicy(home: home)

        #expect(policy.scope(limitedTo: elsewhere) == nil)
        #expect(policy.scope(limitedTo: home.deletingLastPathComponent()) == nil)
    }

    // MARK: Folder to walk

    @Test func walksTheHomeFolderForTheWholeHome() throws {
        let home = try TemporaryFolder()

        #expect(makePolicy(home: home).folder(of: .home) == home.root)
    }

    @Test func walksTheFolderOfAScope() throws {
        let home = try TemporaryFolder()
        let movies = try home.makeFolder("Movies")
        let policy = makePolicy(home: home)
        let scope = try #require(policy.scope(limitedTo: movies))

        #expect(policy.folder(of: scope)?.path == movies.path)
    }

    @Test func walksNothingOnceTheFolderOfAScopeIsGone() throws {
        let home = try TemporaryFolder()
        let movies = try home.makeFolder("Movies")
        let policy = makePolicy(home: home)
        let scope = try #require(policy.scope(limitedTo: movies))

        try FileManager.default.removeItem(at: movies)

        #expect(policy.folder(of: scope) == nil)
    }

    /// A scope is checked again whenever it's scanned, so it can't be pointed elsewhere later.
    @Test func walksNothingOnceTheFolderOfAScopeIsReplacedWithALinkToAnExcludedDirectory() throws {
        let home = try TemporaryFolder()
        let movies = try home.makeFolder("Movies")
        try home.makeFolder("Library/Caches")
        let policy = makePolicy(home: home)
        let scope = try #require(policy.scope(limitedTo: movies))

        try FileManager.default.removeItem(at: movies)
        try home.makeLink("Movies", to: "Library")

        #expect(policy.folder(of: scope) == nil)
    }

    @Test func walksNothingForAScopeThatWasNeverAllowed() throws {
        let home = try TemporaryFolder()
        let caches = try home.makeFolder("Library/Caches")

        #expect(makePolicy(home: home).folder(of: .folder(caches)) == nil)
    }
}
