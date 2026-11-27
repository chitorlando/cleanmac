import CleanMacCore

/// Turns the facts of a signature and Gatekeeper's verdict into how far it can be trusted.
public enum SignatureClassifier {
    /// Prefixes Apple puts before the developer's name in the subject of its certificates.
    private static let certificateKinds = [
        "Developer ID Application: ",
        "Apple Development: ",
        "Apple Distribution: ",
        "Mac Developer: ",
        "3rd Party Mac Developer Application: "
    ]

    /// Whether Gatekeeper's verdict would change the classification. Asking for it can take
    /// seconds, so it's only asked about valid signatures issued by Apple that are neither
    /// Apple's, nor the App Store's, nor notarized: those always open.
    public static func needsGatekeeperVerdict(_ facts: SignatureFacts) -> Bool {
        facts.validity == .valid && !facts.isAdHoc && facts.isIssuedByApple
            && !facts.isApple && !facts.isAppStore && !facts.isNotarized
    }

    /// - Parameter gatekeeper: Gatekeeper's verdict, when it was asked for.
    public static func classify(_ facts: SignatureFacts, gatekeeper: GatekeeperVerdict?) -> AppSignature {
        switch facts.validity {
        case .unreadable: return .unknown
        case .unsigned: return .unsigned
        case .invalid: return .damaged
        case .valid: break
        }
        if facts.isAdHoc || !facts.isIssuedByApple { return .adHocOrSelfSigned }
        if facts.isApple { return .apple }
        if facts.isAppStore { return .appStore }
        if facts.isNotarized { return .notarized }
        if gatekeeper == .rejected { return .rejectedByGatekeeper }
        return .identifiedDeveloper
    }

    /// Who signed the code, such as “Example Ltd (ABCDE12345)” for a Developer ID, or the
    /// name of a self-signed certificate. `nil` for Apple's and the App Store's signatures,
    /// which don't name the developer, and for signatures without a certificate.
    public static func signer(of facts: SignatureFacts) -> String? {
        guard !facts.isApple, !facts.isAppStore, !facts.isAdHoc,
              let subject = facts.certificateSubject, !subject.isEmpty
        else { return nil }
        let kind = certificateKinds.first { subject.hasPrefix($0) }
        return kind.map { String(subject.dropFirst($0.count)) } ?? subject
    }
}
