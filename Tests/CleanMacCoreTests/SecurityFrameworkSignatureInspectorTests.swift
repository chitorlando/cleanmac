import CleanMacCore
import Foundation
import Testing

/// Checks real signatures on disk, which every Mac has.
struct SecurityFrameworkSignatureInspectorTests {
    private let inspector = SecurityFrameworkSignatureInspector()

    @Test func recognizesAnAppOfMacOS() {
        let facts = inspector.facts(forCodeAt: URL(filePath: "/System/Applications/Calculator.app"))

        #expect(facts.validity == .valid)
        #expect(facts.isIssuedByApple)
        #expect(facts.isApple)
    }

    @Test func findsNoSignatureOnAScript() throws {
        let script = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).sh")
        try Data("#!/bin/sh\necho hello\n".utf8).write(to: script)
        defer { try? FileManager.default.removeItem(at: script) }

        #expect(inspector.facts(forCodeAt: script).validity == .unsigned)
    }

    @Test func cannotReadWhatIsMissing() {
        let missing = URL(filePath: "/nonexistent/\(UUID().uuidString)/Missing.app")

        #expect(inspector.facts(forCodeAt: missing).validity == .unreadable)
        #expect(inspector.identity(ofCodeAt: missing) == nil)
    }

    @Test func identifiesAnAppOfMacOSByItsCDHashAlone() throws {
        let identity = try #require(inspector.identity(ofCodeAt: URL(filePath: "/System/Applications/Calculator.app")))

        #expect(identity.teamID == nil)
        #expect(!identity.cdHashes.isEmpty)
        #expect(identity.cdHashes.allSatisfy { $0.count == 20 })
    }

    @Test func identifiesTheMainProgramOfAnAppAsTheApp() {
        let app = URL(filePath: "/System/Applications/Calculator.app")

        #expect(inspector.identity(ofCodeAt: app.appending(path: "Contents/MacOS/Calculator")) == inspector.identity(ofCodeAt: app))
    }

    @Test func findsNoIdentityOnAScript() throws {
        let script = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).sh")
        try Data("#!/bin/sh\necho hello\n".utf8).write(to: script)
        defer { try? FileManager.default.removeItem(at: script) }

        #expect(inspector.identity(ofCodeAt: script) == nil)
    }
}
