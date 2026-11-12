import Foundation
import LoginItemsFeature
import Testing

struct LaunchPlistParserTests {
    private func job(_ keys: [String: Any], format: PropertyListSerialization.PropertyListFormat = .xml) throws -> LaunchJobDefinition? {
        LaunchPlistParser.job(from: try PropertyListSerialization.data(fromPropertyList: keys, format: format, options: 0))
    }

    @Test func readsEveryKey() throws {
        let job = try #require(try job([
            "Label": "com.example.agent",
            "Program": "/Applications/Example.app/Contents/MacOS/agent",
            "RunAtLoad": true,
            "KeepAlive": true,
            "Disabled": true
        ]))

        #expect(job == LaunchJobDefinition(
            label: "com.example.agent",
            programPath: "/Applications/Example.app/Contents/MacOS/agent",
            runsAtLoad: true,
            keepsAlive: true,
            isDisabled: true
        ))
    }

    @Test func defaultsMissingFlagsToFalse() throws {
        let job = try #require(try job(["Label": "com.example.agent"]))

        #expect(job.programPath == nil)
        #expect(!job.runsAtLoad && !job.keepsAlive && !job.isDisabled)
    }

    @Test func takesTheProgramFromItsArgumentsWhenThereIsNoProgramKey() throws {
        let job = try #require(try job(["Label": "a", "ProgramArguments": ["/usr/local/bin/tool", "--daemon"]]))

        #expect(job.programPath == "/usr/local/bin/tool")
    }

    @Test func prefersTheProgramKeyOverTheArguments() throws {
        let job = try #require(try job(["Label": "a", "Program": "/bin/real", "ProgramArguments": ["argv0"]]))

        #expect(job.programPath == "/bin/real")
    }

    @Test func keepsAliveUnderConditions() throws {
        let job = try #require(try job(["Label": "a", "KeepAlive": ["SuccessfulExit": false]]))

        #expect(job.keepsAlive)
    }

    @Test func readsBinaryPropertyLists() throws {
        let job = try #require(try job(["Label": "com.example.binary", "RunAtLoad": true], format: .binary))

        #expect(job.label == "com.example.binary" && job.runsAtLoad)
    }

    @Test func rejectsPropertyListsWithoutALabel() throws {
        #expect(try job(["Program": "/bin/tool"]) == nil)
        #expect(try job(["Label": ""]) == nil)
    }

    @Test func rejectsDataThatIsNotAPropertyList() {
        #expect(LaunchPlistParser.job(from: Data("not a plist".utf8)) == nil)
    }

    @Test func checksOnlyAbsoluteProgramPaths() {
        let relative = LaunchJobDefinition(label: "a", programPath: "tool", runsAtLoad: false, keepsAlive: false, isDisabled: false)
        let absolute = LaunchJobDefinition(label: "a", programPath: "/bin/tool", runsAtLoad: false, keepsAlive: false, isDisabled: false)

        #expect(relative.programURL == nil)
        #expect(absolute.programURL == URL(filePath: "/bin/tool"))
    }
}
