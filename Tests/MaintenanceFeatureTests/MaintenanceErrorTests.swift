import CleanMacCore
@testable import MaintenanceFeature
import Foundation
import Testing

struct MaintenanceErrorTests {
    private struct DescribedError: LocalizedError {
        var errorDescription: String? { "described" }
    }

    @Test func keepsMaintenanceErrors() {
        #expect(MaintenanceError(MaintenanceError.authorizationCancelled) == .authorizationCancelled)
    }

    @Test func mapsCancellation() {
        #expect(MaintenanceError(CancellationError()) == .cancelled)
    }

    @Test func usesTheToolOutputOfCommandFailures() {
        #expect(MaintenanceError(CommandFailure(status: 2, message: "denied")) == .failed(message: "denied"))
    }

    @Test func describesAnyOtherError() {
        #expect(MaintenanceError(DescribedError()) == .failed(message: "described"))
    }
}
