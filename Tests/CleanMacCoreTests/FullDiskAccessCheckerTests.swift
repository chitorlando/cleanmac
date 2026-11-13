import CleanMacCore
import Foundation
import Testing

struct FullDiskAccessCheckerTests {
    private let first = URL(filePath: "/protected/first")
    private let second = URL(filePath: "/protected/second")

    private func checker(_ outcomes: [URL: ProtectedFileAccess]) -> ProtectedFileFullDiskAccessChecker {
        ProtectedFileFullDiskAccessChecker(probes: [first, second]) { outcomes[$0] ?? .missing }
    }

    @Test func grantsAccessWhenAProtectedFileOpens() {
        #expect(checker([first: .allowed]).hasFullDiskAccess())
    }

    @Test func refusesAccessWhenTheProtectionSaysNo() {
        #expect(!checker([first: .denied, second: .allowed]).hasFullDiskAccess())
    }

    @Test func asksTheNextFileWhenOneIsMissing() {
        #expect(checker([first: .missing, second: .allowed]).hasFullDiskAccess())
        #expect(!checker([first: .missing, second: .denied]).hasFullDiskAccess())
    }

    @Test func countsAccessAsMissingWhenNoFileAnswers() {
        #expect(!checker([:]).hasFullDiskAccess())
    }

    @Test func probesTheSystemPrivacyDatabaseFirst() {
        let probes = ProtectedFileFullDiskAccessChecker.defaultProbes

        #expect(probes.first?.path == "/Library/Application Support/com.apple.TCC/TCC.db")
    }

    @Test func tellsMissingFilesApartWithoutAnyProtection() {
        let nowhere = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

        #expect(ProtectedFileFullDiskAccessChecker.open(nowhere) == .missing)
    }

    @Test func opensFilesItMayRead() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("x".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }

        #expect(ProtectedFileFullDiskAccessChecker.open(file) == .allowed)
    }
}
