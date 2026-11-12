import CleanMacCore
import Foundation
import LoginItemsFeature

/// `LoginItemScanning` that returns fixed items.
struct StubLoginItemScanner: LoginItemScanning {
    let items: [LoginItem]

    func scan() async -> [LoginItem] { items }
}

/// Records how many times the Login Items settings were opened.
@MainActor
final class SpySettingsOpener: LoginItemsSettingsOpening {
    private(set) var openCount = 0

    func openLoginItemsSettings() {
        openCount += 1
    }
}

/// A login item for tests, identified by its label.
func loginItem(
    _ label: String,
    scope: LaunchScope = .currentUser,
    owner: String? = nil,
    isOrphaned: Bool = false
) -> LoginItem {
    let folder = scope == .currentUser ? "/home/Library/LaunchAgents" : "/Library/LaunchAgents"
    return LoginItem(
        item: CleanableItem(url: URL(filePath: "\(folder)/\(label).plist"), size: 4_096),
        job: LaunchJobDefinition(label: label, programPath: nil, runsAtLoad: true, keepsAlive: false, isDisabled: false),
        scope: scope,
        kind: .agent,
        owner: owner.map { LoginItemOwner(appURL: URL(filePath: "/Applications/\($0).app"), name: $0) },
        isOrphaned: isOrphaned
    )
}
