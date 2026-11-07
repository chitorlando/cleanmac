import CleanMacCore
import Foundation

/// Why a maintenance task did not complete. The presentation layer turns it into user-facing text.
public enum MaintenanceError: Error, Equatable, Sendable {
    /// The user dismissed the administrator password prompt.
    case authorizationCancelled
    /// The run was cancelled before the task finished.
    case cancelled
    /// A command failed; the message is what the tool reported.
    case failed(message: String)
    /// The administrator batch ran but its results could not be read.
    case unreadableResult

    init(_ error: any Error) {
        switch error {
        case let error as MaintenanceError: self = error
        case is CancellationError: self = .cancelled
        case let failure as CommandFailure: self = .failed(message: failure.message)
        default: self = .failed(message: error.localizedDescription)
        }
    }
}
