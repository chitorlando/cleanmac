@testable import MaintenanceFeature
import Foundation
import Testing

struct PrivilegedBatchReportTests {
    private static let record = String(PrivilegedBatchReport.recordSeparator)
    private static let field = String(PrivilegedBatchReport.fieldSeparator)

    private func outcomes(_ records: [String], jobCount: Int) throws -> [MaintenanceOutcome] {
        let output = records.map { $0 + Self.record }.joined() + "\n"
        return try PrivilegedBatchReport.outcomes(from: output, jobCount: jobCount)
    }

    @Test func readsOneOutcomePerJob() throws {
        let records = ["ok", "failed" + Self.field + "no such volume", "cancelled"]

        #expect(try outcomes(records, jobCount: 3) == [
            .succeeded,
            .failed(.failed(message: "no such volume")),
            .failed(.authorizationCancelled)
        ])
    }

    @Test func keepsMultilineMessages() throws {
        let records = ["failed" + Self.field + "first line\rsecond line\r"]

        #expect(try outcomes(records, jobCount: 1) == [.failed(.failed(message: "first line\nsecond line"))])
    }

    @Test func rejectsAMissingRecord() {
        #expect(throws: MaintenanceError.unreadableResult) {
            try outcomes(["ok"], jobCount: 2)
        }
    }

    @Test func rejectsUnknownRecords() {
        #expect(throws: MaintenanceError.unreadableResult) {
            try outcomes(["maybe"], jobCount: 1)
        }
    }

    @Test func rejectsOutputWithoutTheFinalSeparator() {
        #expect(throws: MaintenanceError.unreadableResult) {
            try PrivilegedBatchReport.outcomes(from: "ok", jobCount: 1)
        }
    }
}
