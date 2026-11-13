import Foundation

/// Tells why removing an item failed from the error the remover threw.
///
/// It looks at the error and every error it wraps: Cocoa and POSIX errors from the file
/// system, OSStatus codes, and the code Finder reports at the end of an AppleScript error,
/// such as `… execution error: Finder got an error: … (-5000)`.
public enum CleanupFailureClassifier {
    /// Codes that mean access was denied: `afpAccessDenied`, `errAEPrivilegeError`,
    /// `errAEEventNotPermitted` (CleanMac may not control Finder) and `permErr`.
    static let protectedStatusCodes: Set<Int> = [-5000, -10004, -1743, -54]
    /// Codes that mean the file is busy: `fBsyErr` and `afpObjectLocked`.
    static let inUseStatusCodes: Set<Int> = [-47, -5034]
    static let missingStatusCodes: Set<Int> = [-43]

    public static func kind(of error: any Error) -> CleanupFailureKind {
        var current: NSError? = error as NSError
        while let error = current {
            if let kind = kind(ofSingle: error) {
                return kind
            }
            current = error.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return .unknown
    }

    private static func kind(ofSingle error: NSError) -> CleanupFailureKind? {
        if let failure = error as Error as? CommandFailure {
            return failure.appleScriptErrorCode.flatMap(kind(ofStatus:))
        }
        switch error.domain {
        case NSCocoaErrorDomain:
            return kind(ofCocoaCode: error.code)
        case NSPOSIXErrorDomain:
            return kind(ofPOSIXCode: Int32(error.code))
        case NSOSStatusErrorDomain:
            return kind(ofStatus: error.code)
        default:
            return nil
        }
    }

    private static func kind(ofCocoaCode code: Int) -> CleanupFailureKind? {
        switch CocoaError.Code(rawValue: code) {
        case .fileWriteNoPermission, .fileReadNoPermission: .protectedByMacOS
        case .fileNoSuchFile, .fileReadNoSuchFile: .missing
        case .fileLocking: .inUse
        default: nil
        }
    }

    private static func kind(ofPOSIXCode code: Int32) -> CleanupFailureKind? {
        switch code {
        case EPERM, EACCES: .protectedByMacOS
        case EBUSY, ETXTBSY: .inUse
        case ENOENT: .missing
        default: nil
        }
    }

    private static func kind(ofStatus code: Int) -> CleanupFailureKind? {
        if protectedStatusCodes.contains(code) { return .protectedByMacOS }
        if inUseStatusCodes.contains(code) { return .inUse }
        if missingStatusCodes.contains(code) { return .missing }
        return nil
    }
}
