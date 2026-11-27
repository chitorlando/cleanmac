import Foundation
import SecurityFeature
import Testing

struct AppSignatureCheckerTests {
    private let app = URL(filePath: "/Applications/Example.app")

    @Test func trustsANotarizedAppWithoutAskingGatekeeper() {
        let gatekeeper = SpyGatekeeper(.rejected)
        let checker = AppSignatureChecker(inspector: StubSignatureInspector(), gatekeeper: gatekeeper)

        let check = checker.check(app)

        #expect(check == AppSignatureCheck(url: app, signature: .notarized, signer: "Example Ltd (ABCDE12345)"))
        #expect(gatekeeper.asked.isEmpty)
    }

    @Test func asksGatekeeperAboutADeveloperThatIsNotNotarized() {
        let gatekeeper = SpyGatekeeper(.rejected)
        let inspector = StubSignatureInspector([app.path: StubSignatureInspector.developerID])

        let check = AppSignatureChecker(inspector: inspector, gatekeeper: gatekeeper).check(app)

        #expect(check.signature == .rejectedByGatekeeper)
        #expect(check.signature.isRisky)
        #expect(gatekeeper.asked == [app.path])
    }

    @Test func flagsAnAdHocSignatureWithoutAskingGatekeeper() {
        let gatekeeper = SpyGatekeeper(.accepted)
        let inspector = StubSignatureInspector([app.path: StubSignatureInspector.adHoc])

        let check = AppSignatureChecker(inspector: inspector, gatekeeper: gatekeeper).check(app)

        #expect(check == AppSignatureCheck(url: app, signature: .adHocOrSelfSigned))
        #expect(gatekeeper.asked.isEmpty)
    }

    @Test func namesTheAppAfterItsBundle() {
        #expect(AppSignatureCheck(url: app, signature: .apple).name == "Example")
    }
}
