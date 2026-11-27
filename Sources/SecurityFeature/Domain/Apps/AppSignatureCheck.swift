import CleanMacCore
import Foundation

/// How far the signature of one app can be trusted.
public struct AppSignatureCheck: Identifiable, Hashable, Sendable {
    public let url: URL
    public let signature: AppSignature
    /// Who signed it, such as “Example Ltd (ABCDE12345)”, when the signature names someone.
    public let signer: String?

    public init(url: URL, signature: AppSignature, signer: String? = nil) {
        self.url = url
        self.signature = signature
        self.signer = signer
    }

    public var id: URL { url }

    /// The app's name, without the extension.
    public var name: String { url.deletingPathExtension().lastPathComponent }
}

/// Checks the signature of an app or a program and classifies it, asking Gatekeeper only
/// when its verdict matters.
public struct AppSignatureChecker: Sendable {
    private let inspector: any CodeSignatureInspecting
    private let gatekeeper: any GatekeeperAssessing

    public init(inspector: any CodeSignatureInspecting, gatekeeper: any GatekeeperAssessing) {
        self.inspector = inspector
        self.gatekeeper = gatekeeper
    }

    public func check(_ url: URL) -> AppSignatureCheck {
        let facts = inspector.facts(forCodeAt: url)
        let verdict = SignatureClassifier.needsGatekeeperVerdict(facts) ? gatekeeper.verdict(forAppAt: url) : nil
        return AppSignatureCheck(
            url: url,
            signature: SignatureClassifier.classify(facts, gatekeeper: verdict),
            signer: SignatureClassifier.signer(of: facts)
        )
    }
}
