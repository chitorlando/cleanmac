import CleanMacCore
import Foundation
@testable import PrivacyFeature
import Testing

struct CacheLocationResolverTests {
    private let folder: TemporaryFolder
    private let resolver: CacheLocationResolver

    init() throws {
        folder = try TemporaryFolder()
        resolver = CacheLocationResolver(library: folder.url("Library"), reader: LocalDirectoryReader())
    }

    /// Paths relative to the Library. Folder listings may leave out the "/private" of the
    /// temporary directory, so both sides resolve their symbolic links first.
    private func names(_ urls: [URL]) -> [String] {
        let library = folder.url("Library").resolvingSymlinksInPath().path + "/"
        return urls.map { String($0.resolvingSymlinksInPath().path.dropFirst(library.count)) }
    }

    @Test func findsTheCacheFoldersOfEveryChromiumProfileAndNothingElse() throws {
        let chrome = "Library/Application Support/Google/Chrome"
        for path in [
            "Default/Cache/data_0", "Default/Code Cache/js/index", "Default/GPUCache/data_1",
            "Default/Service Worker/CacheStorage/a", "Default/Service Worker/ScriptCache/b",
            "Default/Service Worker/Database/c", "Default/History", "Default/Cookies", "Default/Login Data",
            "Default/Web Data", "Default/Local Storage/leveldb/1", "Default/IndexedDB/x", "Default/Sessions/s",
            "Default/Bookmarks", "Default/Preferences",
            "Profile 2/Cache/data_0", "Guest Profile/Cache/data_0", "Profile x/Cache/data_0", "System Profile/Cache/d"
        ] {
            try folder.make("\(chrome)/\(path)")
        }

        let found = resolver.folders(for: [
            .profileFolders(userData: "Application Support/Google/Chrome", layout: .chromium, cacheFolders: CacheLocation.chromiumCacheFolders)
        ])

        #expect(names(found) == [
            "Application Support/Google/Chrome/Default/Cache",
            "Application Support/Google/Chrome/Default/Code Cache",
            "Application Support/Google/Chrome/Default/GPUCache",
            "Application Support/Google/Chrome/Default/Service Worker/CacheStorage",
            "Application Support/Google/Chrome/Default/Service Worker/ScriptCache",
            "Application Support/Google/Chrome/Profile 2/Cache"
        ])
    }

    @Test func findsTheCachesNamedAfterABundleID() throws {
        for name in ["com.apple.Safari", "com.apple.Safari.SafeBrowsing", "com.apple.SafariTechnologyPreview", "com.apple.mail"] {
            try folder.make("Library/Caches/\(name)/file")
        }

        let found = resolver.folders(for: [.cachesNamed(bundleID: "com.apple.Safari")])

        #expect(names(found) == ["Caches/com.apple.Safari", "Caches/com.apple.Safari.SafeBrowsing"])
    }

    @Test func findsAFolderOfTheCaches() throws {
        try folder.make("Library/Caches/Google/Chrome/Default/Cache/data")

        #expect(names(resolver.folders(for: [.cachesFolder("Google/Chrome"), .cachesFolder("Missing")])) == ["Caches/Google/Chrome"])
    }

    @Test func takesEveryFolderAsAProfileWhenAsked() throws {
        for path in ["abc.default-release/cache2/entries/1", "abc.default-release/startupCache/s", "abc.default-release/thumbnails/t", "xyz.dev/cache2/e"] {
            try folder.make("Library/Caches/Firefox/Profiles/\(path)")
        }

        let found = resolver.folders(for: [
            .profileFolders(userData: "Caches/Firefox/Profiles", layout: .anyFolder, cacheFolders: ["cache2", "startupCache"])
        ])

        #expect(names(found) == [
            "Caches/Firefox/Profiles/abc.default-release/cache2",
            "Caches/Firefox/Profiles/abc.default-release/startupCache",
            "Caches/Firefox/Profiles/xyz.dev/cache2"
        ])
    }

    @Test func takesTheUserDataFolderAsTheProfileWhenAsked() throws {
        try folder.make("Library/Application Support/com.operasoftware.Opera/Cache/data")
        try folder.make("Library/Application Support/com.operasoftware.Opera/Cookies")

        let found = resolver.folders(for: [
            .profileFolders(userData: "Application Support/com.operasoftware.Opera", layout: .rootIsProfile, cacheFolders: ["Cache", "GPUCache"])
        ])

        #expect(names(found) == ["Application Support/com.operasoftware.Opera/Cache"])
    }

    @Test func listsAFolderOnlyOnce() throws {
        try folder.make("Library/Caches/com.example/file")

        #expect(resolver.folders(for: [.cachesFolder("com.example"), .cachesNamed(bundleID: "com.example")]).count == 1)
    }

    @Test(arguments: ["Default", "Profile 1", "Profile 12"])
    func recognizesChromiumProfiles(name: String) {
        #expect(CacheLocationResolver.isChromiumProfileName(name))
    }

    @Test(arguments: ["Guest Profile", "System Profile", "Profile", "Profile ", "Profile x", "default", "Profile 1a"])
    func rejectsOtherChromiumFolders(name: String) {
        #expect(!CacheLocationResolver.isChromiumProfileName(name))
    }
}
