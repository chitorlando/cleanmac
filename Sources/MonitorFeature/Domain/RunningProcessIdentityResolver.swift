import AppKit
import Darwin

/// `ProcessIdentityResolving` that names apps as the Dock does and falls back to the executable.
///
/// `NSRunningApplication` is safe to use from any thread.
public struct RunningProcessIdentityResolver: ProcessIdentityResolving {
    public init() {}

    public func identity(of pid: Int32) -> ProcessIdentity? {
        if let app = NSRunningApplication(processIdentifier: pid), let bundleURL = app.bundleURL {
            return ProcessIdentity(name: app.localizedName, iconURL: bundleURL)
        }
        return executableURL(of: pid).map { ProcessIdentity(name: nil, iconURL: $0) }
    }

    private func executableURL(of pid: Int32) -> URL? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return URL(filePath: String(nullTerminated: buffer))
    }
}
