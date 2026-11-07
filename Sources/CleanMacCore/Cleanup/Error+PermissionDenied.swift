import Foundation

extension Error {
    /// Whether the error, or any error it wraps, means the system refused access to the file.
    var isPermissionDenied: Bool {
        let error = self as NSError
        if error.isNoWritePermission || error.isPOSIXAccessDenied {
            return true
        }
        guard let underlying = error.userInfo[NSUnderlyingErrorKey] as? any Error else {
            return false
        }
        return underlying.isPermissionDenied
    }
}

private extension NSError {
    var isNoWritePermission: Bool {
        domain == NSCocoaErrorDomain && code == CocoaError.fileWriteNoPermission.rawValue
    }

    var isPOSIXAccessDenied: Bool {
        domain == NSPOSIXErrorDomain && [EACCES, EPERM].contains(Int32(code))
    }
}
