import CleanMacCore
import Foundation

/// Lists the apps allowed each sensitive permission.
public protocol PermissionsReviewing: Sendable {
    /// - Parameter knownApps: Apps whose signature was already checked, which aren't checked again.
    func review(knownApps: [AppSignatureCheck]) -> PermissionsReview
}

/// Reads the user's and the system's privacy databases, finds each app they name and checks
/// how it's signed, without asking Gatekeeper: only a missing or damaged signature matters here.
public struct PermissionsReviewer: PermissionsReviewing {
    private static let appExtension = "app"

    private let databases: [URL]
    private let reader: any PermissionDatabaseReading
    private let appLocator: any AppLocating
    private let files: any DirectoryReading
    private let inspector: any CodeSignatureInspecting

    public init(
        databases: [URL],
        reader: any PermissionDatabaseReading,
        appLocator: any AppLocating,
        files: any DirectoryReading,
        inspector: any CodeSignatureInspecting
    ) {
        self.databases = databases
        self.reader = reader
        self.appLocator = appLocator
        self.files = files
        self.inspector = inspector
    }

    /// The user's database, which holds the camera and the microphone, then the system's, which
    /// holds Full Disk Access, Screen Recording, Accessibility and Input Monitoring.
    public static func standardDatabases(home: URL) -> [URL] {
        [
            home.appending(path: "Library/Application Support/com.apple.TCC/TCC.db"),
            URL(filePath: "/Library/Application Support/com.apple.TCC/TCC.db")
        ]
    }

    public func review(knownApps: [AppSignatureCheck]) -> PermissionsReview {
        let results = databases.map { reader.grants(in: $0) }
        let readable = results.compactMap { $0 }
        guard !readable.isEmpty else { return PermissionsReview(availability: .unavailable) }

        let known = Dictionary(
            knownApps.map { ($0.url.standardizedFileURL.path, $0.signature) },
            uniquingKeysWith: { first, _ in first }
        )
        let grants = readable.flatMap { $0 }
        // Each client is found and checked once, whatever it's allowed.
        var clients: [PermissionGrant.Client: PermissionClient] = [:]
        for client in Set(grants.map(\.client)) {
            clients[client] = resolve(client, known: known)
        }
        let groups = PrivacyPermission.allCases.compactMap { permission -> PermissionGroup? in
            let allowed = Set(grants.filter { $0.permission == permission }.map(\.client))
                .compactMap { clients[$0] }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return allowed.isEmpty ? nil : PermissionGroup(permission: permission, clients: allowed)
        }
        return PermissionsReview(availability: readable.count == results.count ? .complete : .partial, groups: groups)
    }

    /// The app or program a client names, as found on this Mac, with its signature.
    private func resolve(_ client: PermissionGrant.Client, known: [String: AppSignature]) -> PermissionClient {
        let identifier: String
        let url: URL?
        switch client {
        case .bundleID(let bundleID):
            identifier = bundleID
            url = appLocator.appURL(forBundleID: bundleID)
        case .path(let path):
            identifier = path
            let program = URL(filePath: path)
            url = files.itemExists(at: program) ? (Self.enclosingApp(of: program) ?? program) : nil
        }
        guard let url else {
            return PermissionClient(identifier: identifier, name: identifier, url: nil, signature: nil)
        }
        let signature = known[url.standardizedFileURL.path]
            ?? SignatureClassifier.classify(inspector.facts(forCodeAt: url), gatekeeper: nil)
        return PermissionClient(
            identifier: identifier,
            name: url.deletingPathExtension().lastPathComponent,
            url: url,
            signature: signature
        )
    }

    /// The outermost app bundle on the program's path, such as the app a helper is part of.
    private static func enclosingApp(of program: URL) -> URL? {
        var url = URL(filePath: "/")
        for component in program.pathComponents.dropFirst() {
            url.append(path: component)
            if (component as NSString).pathExtension.lowercased() == appExtension {
                return url
            }
        }
        return nil
    }
}
