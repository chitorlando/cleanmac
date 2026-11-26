import Foundation
import SecurityFeature
import SQLite3
import Testing

/// Reads privacy databases made for each test with the layouts macOS has used.
struct TCCDatabaseReaderTests {
    private let database = FileManager.default.temporaryDirectory.appending(path: "TCC-\(UUID().uuidString).db")

    /// The layout of macOS 11 and later, trimmed to the columns the reader uses and a few more.
    private static let currentSchema = """
        CREATE TABLE access (service TEXT NOT NULL, client TEXT NOT NULL, client_type INTEGER NOT NULL, \
        auth_value INTEGER NOT NULL, auth_reason INTEGER NOT NULL, csreq BLOB, \
        PRIMARY KEY (service, client, client_type));
        """
    /// The layout of macOS 10.15 and earlier.
    private static let olderSchema = """
        CREATE TABLE access (service TEXT NOT NULL, client TEXT NOT NULL, client_type INTEGER NOT NULL, \
        allowed INTEGER NOT NULL, prompt_count INTEGER NOT NULL, csreq BLOB, \
        PRIMARY KEY (service, client, client_type));
        """

    private func makeDatabase(_ statements: [String]) throws {
        var handle: OpaquePointer?
        guard sqlite3_open(database.path, &handle) == SQLITE_OK, let connection = handle else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer { sqlite3_close(connection) }
        for statement in statements {
            guard sqlite3_exec(connection, statement, nil, nil, nil) == SQLITE_OK else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
    }

    private func removeDatabase() {
        try? FileManager.default.removeItem(at: database)
    }

    @Test func readsTheAllowedPermissionsOfTheCurrentLayout() throws {
        defer { removeDatabase() }
        try makeDatabase([
            Self.currentSchema,
            "INSERT INTO access VALUES ('kTCCServiceSystemPolicyAllFiles', 'com.example.backup', 0, 2, 4, NULL)",
            "INSERT INTO access VALUES ('kTCCServiceScreenCapture', '/usr/local/bin/recorder', 1, 2, 4, NULL)",
            "INSERT INTO access VALUES ('kTCCServiceCamera', 'com.example.denied', 0, 0, 4, NULL)",
            "INSERT INTO access VALUES ('kTCCServiceAddressBook', 'com.example.contacts', 0, 2, 4, NULL)",
            "INSERT INTO access VALUES ('kTCCServiceMicrophone', 'com.example.odd', 7, 2, 4, NULL)"
        ])

        let grants = try #require(TCCDatabaseReader().grants(in: database))

        #expect(Set(grants) == [
            PermissionGrant(permission: .fullDiskAccess, client: .bundleID("com.example.backup")),
            PermissionGrant(permission: .screenRecording, client: .path("/usr/local/bin/recorder"))
        ])
    }

    @Test func readsTheAllowedPermissionsOfTheOlderLayout() throws {
        defer { removeDatabase() }
        try makeDatabase([
            Self.olderSchema,
            "INSERT INTO access VALUES ('kTCCServiceAccessibility', 'com.example.helper', 0, 1, 1, NULL)",
            "INSERT INTO access VALUES ('kTCCServiceListenEvent', 'com.example.denied', 0, 0, 1, NULL)"
        ])

        let grants = try #require(TCCDatabaseReader().grants(in: database))

        #expect(grants == [PermissionGrant(permission: .accessibility, client: .bundleID("com.example.helper"))])
    }

    @Test func leavesAnUnknownLayoutUnread() throws {
        defer { removeDatabase() }
        try makeDatabase([
            "CREATE TABLE access (service TEXT, client TEXT, client_type INTEGER, decision TEXT)",
            "INSERT INTO access VALUES ('kTCCServiceCamera', 'com.example.app', 0, 'yes')"
        ])

        #expect(TCCDatabaseReader().grants(in: database) == nil)
    }

    @Test func leavesADatabaseWithoutTheTableUnread() throws {
        defer { removeDatabase() }
        try makeDatabase(["CREATE TABLE policies (id INTEGER)"])

        #expect(TCCDatabaseReader().grants(in: database) == nil)
    }

    @Test func cannotReadAMissingDatabase() {
        #expect(TCCDatabaseReader().grants(in: database) == nil)
    }

    @Test func namesEachPermissionAfterItsService() {
        #expect(PrivacyPermission.allCases.map(\.service) == [
            "kTCCServiceSystemPolicyAllFiles", "kTCCServiceScreenCapture", "kTCCServiceAccessibility",
            "kTCCServiceListenEvent", "kTCCServiceCamera", "kTCCServiceMicrophone"
        ])
        #expect(PrivacyPermission(service: "kTCCServiceCamera") == .camera)
        #expect(PrivacyPermission(service: "kTCCServicePhotos") == nil)
    }

    @Test func linksEveryPermissionToItsPaneOfPrivacyAndSecurity() {
        let urls = PrivacyPermission.allCases.compactMap(\.settingsURL)

        #expect(urls.count == PrivacyPermission.allCases.count)
        #expect(urls.first?.absoluteString == "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    }
}
