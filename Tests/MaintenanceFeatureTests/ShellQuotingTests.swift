import CleanMacCore
@testable import MaintenanceFeature
import Foundation
import Testing

struct ShellQuotingTests {
    private static let trickyWords = [
        "",
        "plain",
        "with space",
        "it's",
        "''",
        #"say "hi""#,
        "$HOME",
        "$(whoami)",
        "`whoami`",
        "line\nbreak",
        #"back\slash"#,
        "semi;colon && exit 9 | true",
        "glob*?[a]",
        "-flag",
        "ñandú 🍎"
    ]

    @Test func leavesSafeWordsUnquoted() {
        #expect("/usr/bin/mdutil".shellQuoted == "/usr/bin/mdutil")
        #expect("local,system,user".shellQuoted == "local,system,user")
        #expect("-HUP".shellQuoted == "-HUP")
    }

    @Test func quotesEmptyWords() {
        #expect("".shellQuoted == "''")
    }

    @Test func wrapsSpecialCharactersInSingleQuotes() {
        #expect("with space".shellQuoted == "'with space'")
        #expect("$HOME".shellQuoted == "'$HOME'")
        #expect("`id`".shellQuoted == "'`id`'")
        #expect(#"a "b""#.shellQuoted == #"'a "b"'"#)
        #expect("a\nb".shellQuoted == "'a\nb'")
    }

    @Test func escapesSingleQuotes() {
        #expect("it's".shellQuoted == #"'it'\''s'"#)
    }

    /// The real shell must read every quoted word back exactly as it was.
    @Test(arguments: trickyWords)
    func shellReadsQuotedWordsBackLiterally(word: String) async throws {
        let check = #"[ "$1" = "#.appending(word.shellQuoted).appending(" ]")

        try await CommandRunner().run(URL(filePath: "/bin/sh"), arguments: ["-c", check, "sh", word])
    }

    @Test func buildsACommandLineFromExecutableAndArguments() {
        let command = ShellCommand("/usr/bin/tool", "-v", "My Folder", "it's")

        #expect(command.commandLine == #"/usr/bin/tool -v 'My Folder' 'it'\''s'"#)
    }
}
