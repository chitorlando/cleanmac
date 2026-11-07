@testable import CleanMacCore
import Foundation
import Testing

struct PermissionDeniedErrorTests {
    private struct UnrelatedError: Error {}

    private static func posix(_ code: Int32) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }

    private static func wrapping(_ underlying: any Error) -> NSError {
        NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: [NSUnderlyingErrorKey: underlying])
    }

    @Test func recognizesCocoaWritePermissionError() {
        #expect(CocoaError(.fileWriteNoPermission).isPermissionDenied)
    }

    @Test(arguments: [EACCES, EPERM])
    func recognizesPOSIXAccessErrors(code: Int32) {
        #expect(Self.posix(code).isPermissionDenied)
    }

    @Test func recognizesSwiftPOSIXError() {
        #expect(POSIXError(.EACCES).isPermissionDenied)
    }

    @Test func looksInsideUnderlyingErrors() {
        let nested = Self.wrapping(Self.wrapping(Self.posix(EPERM)))

        #expect(nested.isPermissionDenied)
    }

    @Test func ignoresOtherErrors() {
        #expect(!CocoaError(.fileNoSuchFile).isPermissionDenied)
        #expect(!Self.posix(ENOENT).isPermissionDenied)
        #expect(!Self.wrapping(Self.posix(ENOENT)).isPermissionDenied)
        #expect(!UnrelatedError().isPermissionDenied)
    }
}
