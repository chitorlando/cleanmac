import Foundation
import SQLite3

/// Reads which apps were allowed a permission from a privacy database.
public protocol PermissionDatabaseReading: Sendable {
    /// The permissions the database allows, or `nil` when it can't be read, such as without
    /// Full Disk Access, which macOS requires to open it, or when its layout is unknown.
    func grants(in database: URL) -> [PermissionGrant]?
}

/// `PermissionDatabaseReading` for the databases of TCC, the part of macOS that keeps the
/// permissions of Privacy & Security, read with SQLite and opened read-only.
///
/// The `access` table says whether a permission is allowed in its `auth_value` column since
/// macOS 11, where 2 means allowed, and in its `allowed` column before, where 1 does. Any other
/// layout is left unread rather than guessed.
public struct TCCDatabaseReader: PermissionDatabaseReading {
    /// `client_type` of a client named by its bundle identifier.
    private static let bundleIDClient: Int32 = 0
    /// `client_type` of a client named by its path.
    private static let pathClient: Int32 = 1

    public init() {}

    public func grants(in database: URL) -> [PermissionGrant]? {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(database.path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let connection = handle else {
            sqlite3_close(handle)
            return nil
        }
        defer { sqlite3_close(connection) }

        guard let condition = Self.allowedCondition(columns: columns(ofAccessTableIn: connection)) else { return nil }
        // The services are constants of this file, so they go into the query as they are.
        let services = PrivacyPermission.allCases.map { "'\($0.service)'" }.joined(separator: ", ")
        let query = "SELECT service, client, client_type FROM access WHERE \(condition) AND service IN (\(services))"
        return rows(of: query, in: connection) { statement in
            guard
                let service = Self.text(statement, column: 0),
                let permission = PrivacyPermission(service: service),
                let client = Self.text(statement, column: 1)
            else { return nil }
            switch sqlite3_column_int(statement, 2) {
            case Self.bundleIDClient: return PermissionGrant(permission: permission, client: .bundleID(client))
            case Self.pathClient: return PermissionGrant(permission: permission, client: .path(client))
            default: return nil
            }
        }
    }

    /// What makes a row of the `access` table an allowed permission, for the columns it has.
    static func allowedCondition(columns: Set<String>) -> String? {
        guard columns.isSuperset(of: ["service", "client", "client_type"]) else { return nil }
        if columns.contains("auth_value") { return "auth_value = 2" }
        if columns.contains("allowed") { return "allowed = 1" }
        return nil
    }

    private func columns(ofAccessTableIn connection: OpaquePointer) -> Set<String> {
        let names = rows(of: "PRAGMA table_info(access)", in: connection) { Self.text($0, column: 1) }
        return Set(names ?? [])
    }

    /// The values `transform` makes of each row the query returns, leaving out those it turns
    /// down, or `nil` when the query fails.
    private func rows<Value>(
        of query: String,
        in connection: OpaquePointer,
        transform: (OpaquePointer) -> Value?
    ) -> [Value]? {
        var handle: OpaquePointer?
        guard sqlite3_prepare_v2(connection, query, -1, &handle, nil) == SQLITE_OK, let statement = handle else {
            sqlite3_finalize(handle)
            return nil
        }
        defer { sqlite3_finalize(statement) }
        var values: [Value] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                if let value = transform(statement) { values.append(value) }
            case SQLITE_DONE:
                return values
            default:
                return nil
            }
        }
    }

    private static func text(_ statement: OpaquePointer, column: Int32) -> String? {
        sqlite3_column_text(statement, column).map { String(cString: $0) }
    }
}
