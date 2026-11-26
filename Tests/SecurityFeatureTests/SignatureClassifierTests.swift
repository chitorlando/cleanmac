import SecurityFeature
import Testing

struct SignatureClassifierTests {
    private func facts(
        _ validity: SignatureFacts.Validity = .valid,
        adHoc: Bool = false,
        issuedByApple: Bool = true,
        apple: Bool = false,
        appStore: Bool = false,
        developerID: Bool = false,
        notarized: Bool = false,
        subject: String? = nil
    ) -> SignatureFacts {
        var facts = SignatureFacts(validity: validity)
        facts.isAdHoc = adHoc
        facts.isIssuedByApple = issuedByApple
        facts.isApple = apple
        facts.isAppStore = appStore
        facts.isDeveloperID = developerID
        facts.isNotarized = notarized
        facts.certificateSubject = subject
        return facts
    }

    @Test func trustsAppleTheAppStoreAndNotarizedApps() {
        #expect(SignatureClassifier.classify(facts(apple: true), gatekeeper: nil) == .apple)
        #expect(SignatureClassifier.classify(facts(appStore: true), gatekeeper: nil) == .appStore)
        #expect(SignatureClassifier.classify(facts(developerID: true, notarized: true), gatekeeper: nil) == .notarized)
    }

    @Test func classifiesMissingAndBrokenSignatures() {
        #expect(SignatureClassifier.classify(facts(.unsigned, issuedByApple: false), gatekeeper: nil) == .unsigned)
        #expect(SignatureClassifier.classify(facts(.invalid(status: -67030), developerID: true), gatekeeper: nil) == .damaged)
        #expect(SignatureClassifier.classify(facts(.unreadable, issuedByApple: false), gatekeeper: nil) == .unknown)
    }

    /// CleanMac itself is signed this way, and gets no exception.
    @Test func classifiesSignaturesWithoutACertificateFromAppleAsUnverified() {
        #expect(SignatureClassifier.classify(facts(adHoc: true, issuedByApple: false), gatekeeper: nil) == .adHocOrSelfSigned)
        #expect(SignatureClassifier.classify(facts(issuedByApple: false, subject: "CleanMac"), gatekeeper: .accepted) == .adHocOrSelfSigned)
    }

    @Test func letsGatekeeperDecideAboutDevelopersThatAreNotNotarized() {
        let developer = facts(developerID: true)

        #expect(SignatureClassifier.classify(developer, gatekeeper: .rejected) == .rejectedByGatekeeper)
        #expect(SignatureClassifier.classify(developer, gatekeeper: .accepted) == .identifiedDeveloper)
        #expect(SignatureClassifier.classify(developer, gatekeeper: .unavailable) == .identifiedDeveloper)
    }

    @Test func asksGatekeeperOnlyWhenItsVerdictMatters() {
        #expect(SignatureClassifier.needsGatekeeperVerdict(facts(developerID: true)))
        #expect(SignatureClassifier.needsGatekeeperVerdict(facts()))
        #expect(!SignatureClassifier.needsGatekeeperVerdict(facts(apple: true)))
        #expect(!SignatureClassifier.needsGatekeeperVerdict(facts(appStore: true)))
        #expect(!SignatureClassifier.needsGatekeeperVerdict(facts(developerID: true, notarized: true)))
        #expect(!SignatureClassifier.needsGatekeeperVerdict(facts(adHoc: true, issuedByApple: false)))
        #expect(!SignatureClassifier.needsGatekeeperVerdict(facts(.unsigned, issuedByApple: false)))
        #expect(!SignatureClassifier.needsGatekeeperVerdict(facts(.invalid(status: -67061))))
    }

    @Test func flagsOnlyTheRiskySignatures() {
        let risky: [AppSignature] = [.rejectedByGatekeeper, .adHocOrSelfSigned, .unsigned, .damaged]
        let trusted: [AppSignature] = [.apple, .appStore, .notarized, .identifiedDeveloper, .unknown]

        #expect(risky.allSatisfy(\.isRisky))
        #expect(!trusted.contains(where: \.isRisky))
    }

    @Test func namesTheDeveloperWithoutTheKindOfCertificate() {
        let subject = "Developer ID Application: Example Ltd (ABCDE12345)"

        #expect(SignatureClassifier.signer(of: facts(developerID: true, subject: subject)) == "Example Ltd (ABCDE12345)")
        #expect(SignatureClassifier.signer(of: facts(issuedByApple: false, subject: "CleanMac")) == "CleanMac")
    }

    @Test func namesNoDeveloperForAppleOrTheAppStore() {
        #expect(SignatureClassifier.signer(of: facts(apple: true, subject: "Software Signing")) == nil)
        #expect(SignatureClassifier.signer(of: facts(appStore: true, subject: "Apple Mac OS Application Signing")) == nil)
        #expect(SignatureClassifier.signer(of: facts(adHoc: true, issuedByApple: false)) == nil)
    }
}
