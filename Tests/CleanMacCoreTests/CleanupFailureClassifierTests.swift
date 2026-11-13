@testable import CleanMacCore
import Foundation
import Testing

struct CleanupFailureClassifierTests {
    /// What osascript printed when Finder couldn't trash another app's container, as the user saw it.
    static let finderDenied = CommandFailure(
        status: 1,
        message: "99:117: execution error: Finder detectó un error: No se puede completar la operación porque no tienes el permiso necesario. (-5000)"
    )

    private func kind(_ error: any Error) -> CleanupFailureKind {
        CleanupFailureClassifier.kind(of: error)
    }

    @Test func finderDenyingAccessMeansProtected() {
        #expect(kind(Self.finderDenied) == .protectedByMacOS)
        #expect(kind(CommandFailure(status: 1, message: "12:40: execution error: Finder got an error: A privilege violation occurred. (-10004)")) == .protectedByMacOS)
        #expect(kind(CommandFailure(status: 1, message: "execution error: Not authorized to send Apple events to Finder. (-1743)")) == .protectedByMacOS)
    }

    @Test func fileSystemPermissionErrorsMeanProtected() {
        #expect(kind(CocoaError(.fileWriteNoPermission)) == .protectedByMacOS)
        #expect(kind(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM))) == .protectedByMacOS)
        #expect(kind(NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES))) == .protectedByMacOS)
        #expect(kind(NSError(domain: NSOSStatusErrorDomain, code: -5000)) == .protectedByMacOS)
    }

    @Test func looksInsideWrappedErrors() {
        let underlying = NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM))
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: 512, userInfo: [NSUnderlyingErrorKey: underlying])

        #expect(kind(wrapped) == .protectedByMacOS)
    }

    @Test func busyFilesAreInUse() {
        #expect(kind(NSError(domain: NSPOSIXErrorDomain, code: Int(EBUSY))) == .inUse)
        #expect(kind(CommandFailure(status: 1, message: "execution error: Finder got an error: The file is busy. (-47)")) == .inUse)
    }

    @Test func goneFilesAreMissing() {
        #expect(kind(CocoaError(.fileNoSuchFile)) == .missing)
        #expect(kind(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))) == .missing)
        #expect(kind(CommandFailure(status: 1, message: "execution error: File not found. (-43)")) == .missing)
    }

    @Test func anythingElseIsUnknown() {
        struct Odd: Error {}
        #expect(kind(Odd()) == .unknown)
        #expect(kind(NSError(domain: NSPOSIXErrorDomain, code: Int(EROFS))) == .unknown)
        #expect(kind(CommandFailure(status: 1, message: "")) == .unknown)
        #expect(kind(CommandFailure(status: 1, message: "execution error: Something odd (-9999)")) == .unknown)
        #expect(kind(CommandFailure(status: 1, message: "no code here (text)")) == .unknown)
    }

    @Test func readsTheAppleScriptErrorCodeWhateverTheLanguage() {
        #expect(Self.finderDenied.appleScriptErrorCode == -5000)
        #expect(CommandFailure(status: 1, message: "Erreur dans Finder (-10004)").appleScriptErrorCode == -10004)
        #expect(CommandFailure(status: 1, message: "(-5000) at the start").appleScriptErrorCode == nil)
    }
}

struct CleanupFailureReportTests {
    /// Fails like the uninstaller's remover did: the direct move is denied, then Finder is too.
    private struct DeniedEverywhere: ItemRemoving {
        func remove(_ url: URL) async throws {
            throw CleanupFailureClassifierTests.finderDenied
        }
    }

    private struct DeniedByFileSystem: ItemRemoving {
        func remove(_ url: URL) async throws {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSUnderlyingErrorKey: NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM))])
        }
    }

    private let container = CleanableItem(url: URL(filePath: "/Users/test/Library/Containers/com.sega.soccer.manager.23"), size: 10)

    @Test func theReportTellsWhyAndKeepsTheDetail() async throws {
        let remover = FallbackItemRemover(primary: DeniedByFileSystem(), fallback: DeniedEverywhere())

        let report = await CleanupService(remover: remover).clean([container])

        let failure = try #require(report.failures.first)
        #expect(failure.kind == .protectedByMacOS)
        #expect(failure.reason == CleanupFailureClassifierTests.finderDenied.message)
        #expect(report.failures.includesProtectedItems)
    }

    @Test func onlyProtectedItemsCallForFullDiskAccess() {
        let busy = CleanupFailure(item: container, kind: .inUse, reason: "")
        let odd = CleanupFailure(item: container, kind: .unknown, reason: "")

        #expect(![busy, odd].includesProtectedItems)
        #expect([busy, CleanupFailure(item: container, kind: .protectedByMacOS, reason: "")].includesProtectedItems)
    }
}
