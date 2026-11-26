import Foundation
import SecurityFeature
import Testing

/// Checks real signatures on disk, which every Mac has.
struct SecurityFrameworkSignatureInspectorTests {
    private let inspector = SecurityFrameworkSignatureInspector()

    @Test func recognizesAnAppOfMacOS() {
        let facts = inspector.facts(forCodeAt: URL(filePath: "/System/Applications/Calculator.app"))

        #expect(facts.validity == .valid)
        #expect(facts.isIssuedByApple)
        #expect(facts.isApple)
        #expect(SignatureClassifier.classify(facts, gatekeeper: nil) == .apple)
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
    }
}
