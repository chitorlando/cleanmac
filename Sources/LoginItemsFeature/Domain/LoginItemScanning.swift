/// Lists the launchd items that start at login, at startup or in the background.
public protocol LoginItemScanning: Sendable {
    func scan() async -> [LoginItem]
}
