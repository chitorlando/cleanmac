import CleanMacCore
import Foundation
import LoginItemsFeature
import Testing

struct LoginItemAttributorTests {
    private let folder: TemporaryFolder

    init() throws {
        folder = try TemporaryFolder()
    }

    private func job(label: String = "com.example.agent", program: String? = nil) -> LaunchJobDefinition {
        LaunchJobDefinition(label: label, programPath: program, runsAtLoad: true, keepsAlive: false, isDisabled: false)
    }

    private func attributor(apps: [String: URL] = [:]) -> LoginItemAttributor {
        LoginItemAttributor(appLocator: FakeAppLocator(apps: apps), reader: LocalDirectoryReader())
    }

    @Test func attributesAProgramToTheOutermostAppThatContainsIt() throws {
        let program = try folder.make("Example.app/Contents/Library/LoginItems/Helper.app/Contents/MacOS/Helper")

        let owner = attributor().owner(of: job(program: program.path))

        #expect(owner == LoginItemOwner(appURL: folder.url("Example.app"), name: "Example"))
    }

    @Test func fallsBackToAnInstalledAppWhoseBundleIDStartsTheLabel() throws {
        let app = try folder.make("Example.app/")

        let owner = attributor(apps: ["com.example.app": app]).owner(of: job(label: "com.example.app.agent"))

        #expect(owner?.name == "Example")
    }

    @Test func prefersTheMostSpecificBundleID() throws {
        let vendor = try folder.make("Vendor.app/")
        let app = try folder.make("Example.app/")
        let apps = ["com.example": vendor, "com.example.app": app]

        #expect(attributor(apps: apps).owner(of: job(label: "com.example.app.agent"))?.appURL == app)
    }

    @Test func ignoresAppsThatNoLongerExist() {
        let deleted = folder.url("Deleted.app")

        #expect(attributor(apps: ["com.example.agent": deleted]).owner(of: job()) == nil)
    }

    @Test func hasNoOwnerWhenNothingMatches() {
        #expect(attributor().owner(of: job(program: "/usr/local/bin/tool")) == nil)
    }

    @Test func treatsAMissingProgramAsOrphaned() throws {
        let present = try folder.make("bin/tool")

        #expect(attributor().isOrphaned(job(program: folder.url("bin/missing").path)))
        #expect(!attributor().isOrphaned(job(program: present.path)))
    }

    @Test func neverTreatsAJobItCannotCheckAsOrphaned() {
        #expect(!attributor().isOrphaned(job(program: nil)))
        #expect(!attributor().isOrphaned(job(program: "relative/tool")))
    }
}
