import Foundation
import SecurityFeature
import Testing

struct ApplicationFolderAppFinderTests {
    @Test func findsAppsAtTheTopAndOneFolderDown() {
        let reader = StubDirectoryReader(tree: [
            "/Applications": ["Zed.app", "Utilities", "notes.txt", "alpha.app", ".hidden.app", "Tools"],
            "/Applications/Utilities": ["Helper.app", "Deep"],
            "/Applications/Utilities/Deep": ["TooDeep.app"],
            "/Applications/Tools": ["Tool.app"],
            "/Users/ana/Applications": ["Web App.app"]
        ])
        let finder = ApplicationFolderAppFinder(
            folders: [URL(filePath: "/Applications"), URL(filePath: "/Users/ana/Applications")],
            reader: reader
        )

        #expect(finder.apps().map(\.path) == [
            "/Applications/alpha.app",
            "/Applications/Utilities/Helper.app",
            "/Applications/Tools/Tool.app",
            "/Users/ana/Applications/Web App.app",
            "/Applications/Zed.app"
        ])
    }

    @Test func skipsFoldersThatAreMissing() {
        let finder = ApplicationFolderAppFinder(folders: [URL(filePath: "/Nowhere")], reader: StubDirectoryReader(tree: [:]))

        #expect(finder.apps().isEmpty)
    }
}

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
