import CleanMacCore
import Foundation

/// Decides which launchd items deserve a look.
///
/// Installers put the programs of login and background items in the app that owns them or
/// in folders such as `/Library/Application Support`. Malware often hides them in folders any
/// app can write to, or in hidden ones, and often leaves them unsigned.
public enum PersistenceRules {
    /// Folders where any app or user can put files. Both spellings of the ones under `/private`
    /// are listed, since property lists use either.
    static let temporaryOrSharedFolders = [
        "/tmp/", "/private/tmp/",
        "/var/tmp/", "/private/var/tmp/",
        "/var/folders/", "/private/var/folders/",
        "/Users/Shared/"
    ]

    /// Concerns about where the job's program and what it plainly hands to an interpreter or
    /// launcher are, such as the script of `/bin/sh /tmp/run.sh`. Each concern is listed once.
    public static func locationConcerns(of job: LaunchJobDefinition) -> [PersistenceConcern] {
        let paths = job.requiredItems.map { $0.path }
        var concerns: [PersistenceConcern] = []
        if paths.contains(where: isInTemporaryOrSharedFolder) {
            concerns.append(.temporaryOrSharedFolder)
        }
        if paths.contains(where: isHidden) {
            concerns.append(.hiddenFolder)
        }
        return concerns
    }

    /// The concern a program's signature raises: only a missing or damaged one. Programs signed
    /// without a certificate from Apple are common among command-line tools and aren't flagged.
    public static func signatureConcern(of signature: AppSignature) -> PersistenceConcern? {
        switch signature {
        case .unsigned: .unsignedProgram
        case .damaged: .damagedProgram
        case .apple, .appStore, .notarized, .identifiedDeveloper, .rejectedByGatekeeper, .adHocOrSelfSigned, .unknown: nil
        }
    }

    static func isInTemporaryOrSharedFolder(_ path: String) -> Bool {
        temporaryOrSharedFolders.contains { path.hasPrefix($0) }
    }

    /// Whether the path goes through a folder, or ends at an item, whose name starts with a dot.
    static func isHidden(_ path: String) -> Bool {
        path.split(separator: "/").contains { $0.hasPrefix(".") && $0 != "." && $0 != ".." }
    }
}
