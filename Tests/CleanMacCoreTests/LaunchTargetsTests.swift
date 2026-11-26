import CleanMacCore
import Foundation
import Testing

struct LaunchTargetsTests {
    private func targets(_ commandLine: String...) -> [String] {
        LaunchTargets.paths(program: commandLine[0], arguments: Array(commandLine.dropFirst()))
    }

    @Test func findsTheScriptAnInterpreterRuns() {
        #expect(targets("/bin/bash", "/Users/me/backup.sh") == ["/Users/me/backup.sh"])
        #expect(targets("/bin/sh", "-l", "-e", "/Users/me/backup.sh", "--all") == ["/Users/me/backup.sh"])
        #expect(targets("zsh", "/Users/me/backup.zsh") == ["/Users/me/backup.zsh"])
        #expect(targets("/opt/homebrew/bin/python3.12", "-u", "/opt/tool/main.py") == ["/opt/tool/main.py"])
        #expect(targets("/usr/bin/ruby", "/opt/tool/main.rb") == ["/opt/tool/main.rb"])
        #expect(targets("/usr/bin/perl", "-w", "/opt/tool/main.pl") == ["/opt/tool/main.pl"])
        #expect(targets("/usr/local/bin/node", "/opt/tool/server.js") == ["/opt/tool/server.js"])
        #expect(targets("/usr/bin/osascript", "/Users/me/open.scpt") == ["/Users/me/open.scpt"])
    }

    @Test func neverReadsInlineCode() {
        #expect(targets("/bin/sh", "-c", "/usr/bin/open -a /Applications/Example.app").isEmpty)
        #expect(targets("/bin/zsh", "-lc", "/Users/me/backup.sh").isEmpty)
        #expect(targets("/usr/bin/python3", "-c", "print(1)", "/Users/me/data").isEmpty)
        #expect(targets("/usr/bin/python3", "-m", "http.server").isEmpty)
        #expect(targets("/usr/bin/osascript", "-e", "beep").isEmpty)
    }

    @Test func leavesCommandLinesItCannotBeSureOfUnread() {
        #expect(targets("/bin/bash", "backup.sh").isEmpty)
        #expect(targets("/bin/bash", "~/backup.sh").isEmpty)
        #expect(targets("/bin/bash", "-o", "pipefail", "/Users/me/backup.sh").isEmpty)
        #expect(targets("/bin/bash", "--rcfile", "/Users/me/rc", "/Users/me/backup.sh").isEmpty)
        #expect(targets("/bin/bash").isEmpty)
        #expect(targets("/usr/local/bin/node", "--require", "/opt/hook.js", "/opt/tool/server.js").isEmpty)
        #expect(targets("/usr/local/bin/node", "/opt/tool/server").isEmpty)
        #expect(targets("/usr/bin/osascript", "-l", "JavaScript", "/Users/me/open.js").isEmpty)
    }

    @Test func ignoresProgramsThatAreNotInterpreters() {
        #expect(targets("/usr/local/bin/tool", "/etc/tool.conf").isEmpty)
        #expect(targets("/Applications/Example.app/Contents/MacOS/Example", "/Users/me/file").isEmpty)
        #expect(targets("/usr/local/bin/pythonista", "/opt/tool/main.py").isEmpty)
    }

    @Test func findsWhatEnvRuns() {
        #expect(targets("/usr/bin/env", "python3", "/opt/tool/main.py") == ["/opt/tool/main.py"])
        #expect(targets("/usr/bin/env", "LANG=C", "PATH=/usr/bin:/bin", "/opt/tool/run") == ["/opt/tool/run"])
        #expect(targets("/usr/bin/env", "/bin/bash", "/Users/me/backup.sh") == ["/bin/bash", "/Users/me/backup.sh"])
        #expect(targets("/usr/bin/env", "-i", "/opt/tool/run").isEmpty)
        #expect(targets("/usr/bin/env", "-S", "bash /Users/me/backup.sh").isEmpty)
        #expect(targets("/usr/bin/env", "LANG=C").isEmpty)
    }

    @Test func findsTheAppOrFileOpenIsGiven() {
        #expect(targets("/usr/bin/open", "-a", "/Applications/Example.app") == ["/Applications/Example.app"])
        #expect(targets("/usr/bin/open", "-g", "-a", "/Applications/Example.app", "--args", "/tmp/x") == ["/Applications/Example.app"])
        #expect(targets("/usr/bin/open", "/Applications/Example.app") == ["/Applications/Example.app"])
        #expect(targets("/usr/bin/open", "-a", "Safari", "/Users/me/page.html") == ["/Users/me/page.html"])
    }

    @Test func leavesOpenUnreadWhenItIsNotPlain() {
        #expect(targets("/usr/bin/open", "-a", "Example").isEmpty)
        #expect(targets("/usr/bin/open", "-a", "/Applications/Example").isEmpty)
        #expect(targets("/usr/bin/open", "-b", "com.example.app").isEmpty)
        #expect(targets("/usr/bin/open", "-u", "/Users/me/page.html").isEmpty)
        #expect(targets("/usr/bin/open", "https://example.com").isEmpty)
        #expect(targets("/usr/bin/open", "/Users/me/a.txt", "/Users/me/b.txt").isEmpty)
        #expect(targets("/usr/bin/open", "-a").isEmpty)
    }
}
