import DuplicatesFeature
import Foundation
import Testing

/// Each test builds a home folder of its own, whose `Library` is excluded like `~/Library`.
struct ScanScopePolicyTests {
    private func policy(for home: TemporaryFolder) -> ScanScopePolicy {
        ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
    }

    /// Path of the folder that would be scanned for `url`, or `nil` when the policy refuses it.
    private func scannedPath(for url: URL, in home: TemporaryFolder) -> String? {
        policy(for: home).scope(limitedTo: url)?.folder?.path
    }

    // MARK: Folders the home scan walks

    @Test func scansAFolderOfTheHomeFolderOnItsOwn() throws {
        let home = try TemporaryFolder()
        let documents = try home.makeFolder("Documents")
        let projects = try home.makeFolder("Documents/Work/Projects 2026")

        #expect(scannedPath(for: documents, in: home) == documents.path)
        #expect(scannedPath(for: projects, in: home) == projects.path)
        #expect(policy(for: home).allows(projects))
    }

    @Test func theHomeFolderIsTheWholeScope() throws {
        let home = try TemporaryFolder()

        #expect(policy(for: home).scope(limitedTo: home.root) == .home)
        #expect(policy(for: home).scope(limitedTo: URL(filePath: home.root.path + "/")) == .home)
    }

    @Test func aTrailingSlashGivesTheSameScope() throws {
        let home = try TemporaryFolder()
        let downloads = try home.makeFolder("Downloads")
        let policy = policy(for: home)

        let scope = policy.scope(limitedTo: URL(filePath: downloads.path + "/", directoryHint: .isDirectory))

        #expect(scope != nil)
        #expect(scope == policy.scope(limitedTo: downloads))
    }

    /// A walk reports what it finds with its real path, which is another spelling of the same
    /// folders when the path of the home folder goes through a symbolic link.
    @Test func acceptsAFolderSpelledWithTheRealPathOfTheHomeFolder() throws {
        let volume = try TemporaryFolder()
        let realHome = try realURL(of: volume.makeFolder("Real/Home"))
        let realDocuments = try realURL(of: volume.makeFolder("Real/Home/Documents"))
        let realCaches = try realURL(of: volume.makeFolder("Real/Home/Library/Caches"))
        let users = try volume.makeSymbolicLink("Users", to: volume.root.appending(path: "Real"))
        let home = users.appending(path: "Home")
        let policy = ScanScopePolicy(home: home, excludedDirectories: [home.appending(path: "Library")])

        #expect(policy.scope(limitedTo: realDocuments)?.folder?.path == home.path + "/Documents")
        #expect(policy.scope(limitedTo: home.appending(path: "Documents"))?.folder?.path == home.path + "/Documents")
        #expect(policy.scope(limitedTo: realHome) == .home)
        #expect(!policy.allows(realCaches))
        #expect(!policy.allows(home.appending(path: "Library/Caches")))
    }

    /// The URL of the item at `url` as the file system spells it, without symbolic links.
    private func realURL(of url: URL) throws -> URL {
        let path = try #require(try url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath)
        return URL(filePath: path)
    }

    // MARK: What is not a folder of the home folder

    @Test func refusesFoldersOutsideTheHomeFolder() throws {
        let home = try TemporaryFolder()
        let elsewhere = try TemporaryFolder()
        let outside = try elsewhere.makeFolder("Documents")

        #expect(!policy(for: home).allows(outside))
        #expect(!policy(for: home).allows(elsewhere.root))
        #expect(!policy(for: home).allows(home.root.deletingLastPathComponent()))
        #expect(!policy(for: home).allows(URL(filePath: "/")))
    }

    @Test func refusesAFolderWhoseNameOnlyStartsLikeTheHomeFolder() throws {
        let home = try TemporaryFolder()
        let sibling = URL(filePath: home.root.path + " copy")
        try FileManager.default.createDirectory(at: sibling, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: sibling) }

        #expect(!policy(for: home).allows(sibling))
    }

    @Test func refusesAFile() throws {
        let home = try TemporaryFolder()
        let file = try home.write(Data([1]), to: "Documents/report.pdf")

        #expect(!policy(for: home).allows(file))
    }

    @Test func refusesAFolderThatIsGone() throws {
        let home = try TemporaryFolder()
        let folder = try home.makeFolder("Documents/Old")
        try FileManager.default.removeItem(at: folder)

        #expect(!policy(for: home).allows(folder))
        #expect(!policy(for: home).allows(folder.appending(path: "Inside")))
    }

    // MARK: Folders the home scan never enters

    @Test func refusesASymbolicLinkAndWhatItLeadsTo() throws {
        let home = try TemporaryFolder()
        let elsewhere = try TemporaryFolder()
        try elsewhere.makeFolder("Photos")
        let link = try home.makeSymbolicLink("Elsewhere", to: elsewhere.root)
        let documents = try home.makeFolder("Documents")
        let linkToInside = try home.makeSymbolicLink("Shortcut", to: documents)

        #expect(!policy(for: home).allows(link))
        #expect(!policy(for: home).allows(URL(filePath: link.path + "/", directoryHint: .isDirectory)))
        #expect(!policy(for: home).allows(link.appending(path: "Photos")))
        #expect(!policy(for: home).allows(linkToInside))
    }

    @Test func refusesAHiddenFolderAndWhatIsInside() throws {
        let home = try TemporaryFolder()
        let dotFolder = try home.makeFolder(".config")
        let insideDotFolder = try home.makeFolder(".config/git")
        let flagged = try home.makeFolder("Secret")
        let insideFlagged = try home.makeFolder("Secret/Photos")
        try home.hide("Secret")

        #expect(!policy(for: home).allows(dotFolder))
        #expect(!policy(for: home).allows(insideDotFolder))
        #expect(!policy(for: home).allows(flagged))
        #expect(!policy(for: home).allows(insideFlagged))
    }

    @Test func refusesAPackageAndWhatIsInside() throws {
        let home = try TemporaryFolder()
        let resources = try home.makeFolder("Applications/Editor.app/Contents/Resources")
        let package = home.root.appending(path: "Applications/Editor.app")

        #expect(policy(for: home).allows(home.root.appending(path: "Applications")))
        #expect(!policy(for: home).allows(package))
        #expect(!policy(for: home).allows(resources))
    }

    @Test func refusesAnExcludedFolderAndWhatIsInside() throws {
        let home = try TemporaryFolder()
        let library = try home.makeFolder("Library")
        let caches = try home.makeFolder("Library/Caches/com.example.app")

        #expect(!policy(for: home).allows(library))
        #expect(!policy(for: home).allows(caches))
    }

    /// The volume may ignore case, and then `library` names the excluded `Library`.
    @Test func refusesAnExcludedFolderSpelledAnotherWay() throws {
        let home = try TemporaryFolder()
        try home.makeFolder("Library/Caches")
        try home.makeFolder("Documents")

        #expect(!policy(for: home).allows(home.root.appending(path: "library")))
        #expect(!policy(for: home).allows(home.root.appending(path: "LIBRARY/Caches")))
        #expect(!policy(for: home).allows(URL(filePath: home.root.path + "/Documents/../Library/Caches")))
        #expect(!policy(for: home).allows(URL(filePath: home.root.path + "/./Library/Caches")))
    }
}
