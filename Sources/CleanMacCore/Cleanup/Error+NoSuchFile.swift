import Foundation

extension Error {
    /// Whether the error, or any error it wraps, means the file wasn't there.
    var isNoSuchFile: Bool {
        let error = self as NSError
        if error.isCocoaNoSuchFile || error.isPOSIXNoSuchFile {
            return true
        }
        guard let underlying = error.userInfo[NSUnderlyingErrorKey] as? any Error else {
            return false
        }
        return underlying.isNoSuchFile
    }
}

private extension NSError {
    var isCocoaNoSuchFile: Bool {
        domain == NSCocoaErrorDomain
            && [CocoaError.fileNoSuchFile.rawValue, CocoaError.fileReadNoSuchFile.rawValue].contains(code)
    }

    var isPOSIXNoSuchFile: Bool {
        domain == NSPOSIXErrorDomain && Int32(code) == ENOENT
    }
}
