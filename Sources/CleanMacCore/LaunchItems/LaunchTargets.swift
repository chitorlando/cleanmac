import Foundation

/// What a job hands to a known interpreter or launcher to run, such as the script of
/// `/bin/bash /path/script.sh` or the app of `/usr/bin/open -a /Applications/Example.app`.
///
/// Only command lines that leave no doubt are read, since a wrong answer marks a working item
/// as orphaned: the target must be an absolute path, and any option that isn't known to take no
/// value leaves the command line unread. Inline code, as in `sh -c "…"`, and relative paths
/// never count.
public enum LaunchTargets {
    /// Options of POSIX shells that take no value and don't change what is run.
    private static let shellFlags: Set<String> = ["-l", "-e", "-u", "-x"]

    /// Programs that run the script named by their first operand, by name, with the options
    /// they may get before it. They're the shells and scripting languages launchd jobs use
    /// most, and none of them looks the script up anywhere else when its path is absolute.
    private static let scriptRunners: [String: Set<String>] = [
        "sh": shellFlags, "bash": shellFlags, "zsh": shellFlags, "dash": shellFlags, "ksh": shellFlags,
        "python": ["-u", "-B", "-O"],
        "ruby": ["-w"],
        "perl": ["-w"],
        "node": [],
        "osascript": []
    ]

    /// Node also tries a path with other extensions added, so only a path that already
    /// names a script is known to be what it runs.
    private static let nodeScriptExtensions: Set<String> = ["js", "mjs", "cjs"]

    /// Options of `open` that take no value.
    private static let openFlags: Set<String> = [
        "-g", "-j", "-n", "-W", "-F", "--background", "--hide", "--new", "--wait-apps", "--fresh"
    ]

    /// Absolute paths of what `program` is asked to run by `arguments`, which don't include
    /// the program's own name. Empty when the program isn't a known interpreter or launcher,
    /// or its command line leaves any doubt.
    public static func paths(program: String, arguments: [String]) -> [String] {
        let name = runnerName(of: program)
        switch name {
        case "env":
            return targetsOfEnv(arguments)
        case "open":
            return targetsOfOpen(arguments)
        default:
            guard let flags = scriptRunners[name] else { return [] }
            return script(in: arguments, after: flags, runBy: name).map { [$0] } ?? []
        }
    }

    /// The program's file name in lowercase, with every version of Python, such as
    /// "python3" and "python3.12", named "python".
    private static func runnerName(of program: String) -> String {
        let name = (program as NSString).lastPathComponent.lowercased()
        let python = "python"
        if name.hasPrefix(python), name.dropFirst(python.count).allSatisfy({ $0.isNumber || $0 == "." }) {
            return python
        }
        return name
    }

    private static func script(in arguments: [String], after flags: Set<String>, runBy name: String) -> String? {
        guard let script = arguments.drop(while: { flags.contains($0) }).first, script.hasPrefix("/") else { return nil }
        if name == "node", !nodeScriptExtensions.contains((script as NSString).pathExtension.lowercased()) {
            return nil
        }
        return script
    }

    /// `env NAME=value… utility arguments…` runs the utility, which may be an interpreter itself.
    private static func targetsOfEnv(_ arguments: [String]) -> [String] {
        let command = arguments.drop { $0.contains("=") && !$0.hasPrefix("-") }
        guard let utility = command.first, !utility.hasPrefix("-") else { return [] }
        let ownPath = utility.hasPrefix("/") ? [utility] : []
        return ownPath + paths(program: utility, arguments: Array(command.dropFirst()))
    }

    /// `open` fails without the app given by path to `-a`, and without the only file it opens.
    /// An app given by name is looked up by Launch Services, so it can't be checked.
    private static func targetsOfOpen(_ arguments: [String]) -> [String] {
        var targets: [String] = []
        var files: [String] = []
        var remaining = arguments[...]
        while let argument = remaining.popFirst(), argument != "--args" {
            if argument == "-a" {
                guard let app = remaining.popFirst() else { return [] }
                if app.hasPrefix("/"), app.lowercased().hasSuffix(".app") {
                    targets.append(app)
                }
            } else if argument.hasPrefix("-") {
                guard openFlags.contains(argument) else { return [] }
            } else {
                files.append(argument)
            }
        }
        if files.count == 1, files[0].hasPrefix("/") {
            targets.append(files[0])
        }
        return targets
    }
}
