@testable import CleanMacCore
import Foundation
import Testing

struct NoSuchFileErrorTests {
    private struct UnrelatedError: Error {}

    @Test func recognizesCocoaErrors() {
        #expect(CocoaError(.fileNoSuchFile).isNoSuchFile)
        #expect(CocoaError(.fileReadNoSuchFile).isNoSuchFile)
    }

    @Test func recognizesPOSIXErrors() {
        #expect(POSIXError(.ENOENT).isNoSuchFile)
        #expect(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isNoSuchFile)
    }

    @Test func looksInsideUnderlyingErrors() {
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: [NSUnderlyingErrorKey: POSIXError(.ENOENT)])

        #expect(wrapped.isNoSuchFile)
    }

    @Test func ignoresOtherErrors() {
        #expect(!CocoaError(.fileWriteNoPermission).isNoSuchFile)
        #expect(!POSIXError(.EACCES).isNoSuchFile)
        #expect(!UnrelatedError().isNoSuchFile)
    }
}
