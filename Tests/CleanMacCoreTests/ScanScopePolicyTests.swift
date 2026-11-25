import Foundation
import CleanMacCore
import Testing

/// Each test builds a home folder of its own, whose `Library` is excluded as the app excludes `~/Library`.
struct ScanScopePolicyTests {
    private func makePolicy(home: TemporaryFolder) -> ScanScopePolicy {
        ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
    }

    /// Path of the folder the scan would be limited to when asked for `url`, or `nil` when the policy refuses it.
    private func scopedPath(of url: URL, in home: TemporaryFolder) -> String? {
        makePolicy(home: home).scope(limitedTo: url)?.folder?.path
    }

    /// Path of the folder the scan would be limited to when asked for `path`, relative to the home.
    private func scopedPath(_ path: String, in home: TemporaryFolder) -> String? {
        scopedPath(of: home.root.appending(path: path), in: home)
    }

    private func path(_ path: String, in home: TemporaryFolder) -> String {
        home.root.appending(path: path).path
    }

    /// The URL of the item at `url` as the disk spells it, without symbolic links.
    private func realURL(of url: URL) throws -> URL {
        let path = try #require(try url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath)
        return URL(filePath: path)
    }

    // MARK: Folders the scan can be limited to

    @Test func limitsTheScanToAFolderOfTheHome() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Movies/Trips")
        let projects = try home.makeFolder("Documents/Work/Projects 2026")

        #expect(scopedPath("Movies", in: home) == path("Movies", in: home))
        #expect(scopedPath("Movies/Trips", in: home) == path("Movies/Trips", in: home))
        #expect(scopedPath(of: projects, in: home) == projects.path)
        #expect(makePolicy(home: home).allows(projects))
    }

    @Test func theHomeFolderIsTheWholeHome() throws {
        let home = try TemporaryFolder()
        let policy = makePolicy(home: home)

        #expect(policy.scope(limitedTo: home.root) == .home)
        #expect(policy.scope(limitedTo: URL(filePath: home.root.path + "/")) == .home)
        #expect(policy.allows(home.root))
    }

    @Test func aTrailingSlashGivesTheSameScope() throws {
        let home = try TemporaryFolder()
        let downloads = try home.makeFolder("Downloads")
        let policy = makePolicy(home: home)

        let scope = policy.scope(limitedTo: URL(filePath: downloads.path + "/", directoryHint: .isDirectory))

        #expect(scope != nil)
        #expect(scope == policy.scope(limitedTo: downloads))
    }

    @Test func findsTheRealFolderBehindASymbolicLinkOnTheWay() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Movies/Trips")
        try home.makeLink("Shortcut", to: "Movies")

        #expect(scopedPath("Shortcut/Trips", in: home) == path("Movies/Trips", in: home))
    }

    @Test func findsTheRealFolderBehindAPathWithDots() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Movies/Trips")
        try home.makeFolder("Documents")

        #expect(scopedPath("Documents/../Movies/./Trips", in: home) == path("Movies/Trips", in: home))
    }

    /// A walk reports what it finds with its real path, which is another spelling of the same
    /// folders when the path of the home folder goes through a symbolic link.
    @Test func acceptsAFolderSpelledWithTheRealPathOfTheHomeFolder() throws {
        let volume = try TemporaryFolder()
        let realHome = try realURL(of: volume.makeFolder("Real/Home"))
        let realDocuments = try realURL(of: volume.makeFolder("Real/Home/Documents"))
        let realCaches = try realURL(of: volume.makeFolder("Real/Home/Library/Caches"))
        let users = try volume.makeLink("Users", to: "Real")
        let home = users.appending(path: "Home")
        let policy = ScanScopePolicy(home: home, excludedDirectories: [home.appending(path: "Library")])

        #expect(policy.scope(limitedTo: realDocuments)?.folder?.path == home.path + "/Documents")
        #expect(policy.scope(limitedTo: home.appending(path: "Documents"))?.folder?.path == home.path + "/Documents")
        #expect(policy.scope(limitedTo: realHome) == .home)
        #expect(!policy.allows(realCaches))
        #expect(!policy.allows(home.appending(path: "Library/Caches")))
    }

    // MARK: What is not a folder of the home folder

    @Test func refusesAFile() throws {
        let home = try TemporaryFolder()
        let file = try home.makeFile("Movies/trip.mov")

        #expect(scopedPath("Movies/trip.mov", in: home) == nil)
        #expect(!makePolicy(home: home).allows(file))
    }

    @Test func refusesAFolderThatIsGone() throws {
        let home = try TemporaryFolder()
        let old = try home.makeFolder("Documents/Old")
        try FileManager.default.removeItem(at: old)

        #expect(scopedPath("Movies", in: home) == nil)
        #expect(!makePolicy(home: home).allows(old))
        #expect(!makePolicy(home: home).allows(old.appending(path: "Inside")))
    }

    @Test func refusesASymbolicLinkToAFolder() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Movies")
        let link = try home.makeLink("Shortcut", to: "Movies")

        #expect(scopedPath("Shortcut", in: home) == nil)
        #expect(!makePolicy(home: home).allows(URL(filePath: link.path + "/", directoryHint: .isDirectory)))
    }

    @Test func refusesWhatASymbolicLinkLeadsToOutsideTheHome() throws {
        let home = try TemporaryFolder()
        let elsewhere = try TemporaryFolder()
        try elsewhere.makeFolder("Photos")
        let link = try home.makeLink("Elsewhere", to: elsewhere.root)
        let policy = makePolicy(home: home)

        #expect(!policy.allows(link))
        #expect(!policy.allows(URL(filePath: link.path + "/", directoryHint: .isDirectory)))
        #expect(!policy.allows(link.appending(path: "Photos")))
    }

    @Test func refusesFoldersOutsideTheHome() throws {
        let disk = try TemporaryFolder()
        let home = try disk.makeFolder("Users/test")
        let elsewhere = try disk.makeFolder("Applications")
        let policy = ScanScopePolicy(home: home)

        #expect(policy.scope(limitedTo: elsewhere) == nil)
        #expect(policy.scope(limitedTo: home.deletingLastPathComponent()) == nil)
        #expect(!policy.allows(disk.root))
        #expect(!policy.allows(URL(filePath: "/")))
    }

    @Test func refusesAFolderWhoseNameOnlyStartsLikeTheHomeFolder() throws {
        let disk = try TemporaryFolder()
        let home = try disk.makeFolder("Users/test")
        let sibling = try disk.makeFolder("Users/test copy")

        #expect(!ScanScopePolicy(home: home).allows(sibling))
    }

    @Test func refusesWhatIsNotOnDisk() throws {
        let home = try TemporaryFolder()
        let page = try #require(URL(string: "https://example.com/Movies"))

        #expect(!makePolicy(home: home).allows(page))
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
        try home.makeFolder("Private/Movies")
        try home.hide("Private")

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

        #expect(scopedPath("library", in: home) == nil)
        #expect(scopedPath("LIBRARY/Caches", in: home) == nil)
        #expect(scopedPath("LIBRARY/caches", in: home) == nil)
    }

    @Test func refusesAnExcludedDirectoryReachedWithDots() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Library/Caches")
        try home.makeFolder("Documents")
        let policy = makePolicy(home: home)

        #expect(!policy.allows(URL(filePath: home.root.path + "/Documents/../Library/Caches")))
        #expect(!policy.allows(URL(filePath: home.root.path + "/./Library/Caches")))
    }

    @Test func refusesAnExcludedDirectoryReachedThroughASymbolicLink() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Library/Caches")
        try home.makeLink("Shortcut", to: "Library")

        #expect(scopedPath("Shortcut/Caches", in: home) == nil)
    }

    // MARK: Folders left out of one scan

    @Test func refusesTheFoldersAScanAlsoLeavesOutAndWhatIsInside() throws {
        let home = try TemporaryFolder()
        let movies = try home.makeFolder("Movies")
        let trips = try home.makeFolder("Movies/Trips")
        let music = try home.makeFolder("Music")
        try home.makeFolder("Library/Caches")
        let policy = makePolicy(home: home).excluding([movies])

        #expect(policy.scope(limitedTo: movies) == nil)
        #expect(policy.scope(limitedTo: trips) == nil)
        #expect(policy.scope(limitedTo: home.root.appending(path: "Library/Caches")) == nil)
        #expect(policy.scope(limitedTo: music)?.folder?.path == music.path)
        #expect(policy.scope(limitedTo: home.root) == .home)
    }

    @Test func leavingOutMoreFoldersKeepsTheOnesItAlreadyLeftOut() throws {
        let home = try TemporaryFolder()
        let movies = home.root.appending(path: "Movies")
        let policy = makePolicy(home: home)

        let withoutMovies = policy.excluding([movies])

        #expect(withoutMovies.home == home.root)
        #expect(withoutMovies.excludedDirectories == [home.root.appending(path: "Library"), movies])
        #expect(policy.excludedDirectories == [home.root.appending(path: "Library")])
    }

    @Test func refusesAFolderLeftOutOfOneScanWrittenInAnotherCase() throws {
        let home = try TemporaryFolder()
        let movies = try home.makeFolder("Movies/Trips").deletingLastPathComponent()
        let policy = makePolicy(home: home).excluding([movies])

        #expect(!policy.allows(home.root.appending(path: "movies")))
        #expect(!policy.allows(home.root.appending(path: "MOVIES/Trips")))
    }

    @Test func walksNothingOnceTheFolderOfAScopeIsLeftOut() throws {
        let home = try TemporaryFolder()
        let movies = try home.makeFolder("Movies")
        let scope = try #require(makePolicy(home: home).scope(limitedTo: movies))

        #expect(makePolicy(home: home).excluding([movies]).folder(of: scope) == nil)
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

    @Test func walksTheHomeFolderWhenItIsTheFolderOfAScope() throws {
        let home = try TemporaryFolder()

        #expect(makePolicy(home: home).folder(of: .folder(home.root))?.path == home.root.path)
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
