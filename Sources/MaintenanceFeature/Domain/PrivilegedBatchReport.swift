import Foundation

/// The per-job results that the administrator AppleScript writes to standard output.
/// Each record ends with `recordSeparator` and is `ok`, `cancelled`, or `failed`
/// followed by `fieldSeparator` and the error message. The script strips both
/// separators from messages, so they can never break a record apart.
enum PrivilegedBatchReport {
    static let recordSeparator: Character = "\u{1E}"
    static let fieldSeparator: Character = "\u{1F}"

    /// Throws `MaintenanceError.unreadableResult` unless there is a valid record for every job.
    static func outcomes(from output: String, jobCount: Int) throws -> [MaintenanceOutcome] {
        var records = output.split(separator: recordSeparator, omittingEmptySubsequences: false)
        guard records.last?.allSatisfy(\.isNewline) == true else {
            throw MaintenanceError.unreadableResult
        }
        records.removeLast()
        guard records.count == jobCount else { throw MaintenanceError.unreadableResult }
        return try records.map(outcome)
    }

    private static func outcome(of record: Substring) throws -> MaintenanceOutcome {
        let fields = record.split(separator: fieldSeparator, maxSplits: 1, omittingEmptySubsequences: false)
        switch (fields.first, fields.count) {
        case ("ok", 1):
            return .succeeded
        case ("cancelled", 1):
            return .failed(.authorizationCancelled)
        case ("failed", 2):
            let message = fields[1]
                .replacingOccurrences(of: "\r", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .failed(.failed(message: message))
        default:
            throw MaintenanceError.unreadableResult
        }
    }
}
