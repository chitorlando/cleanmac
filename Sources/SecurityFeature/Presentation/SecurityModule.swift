import CleanMacCore
import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the security review for the app shell.
@MainActor
public final class SecurityModule: FeatureModule {
    public let id = "security"
    public let title = String(localized: "Security", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "checkmark.shield.fill"
    public let theme = FeatureTheme.security
    public let section = FeatureSection.applications

    private let viewModel: SecurityViewModel

    public init(viewModel: SecurityViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(SecurityView(viewModel: viewModel, theme: theme))
    }
}

public extension SecurityModule {
    /// Module that reads this Mac's real settings, apps and launchd folders.
    static func live() -> SecurityModule {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let reader = LocalDirectoryReader()
        let inspector = SecurityFrameworkSignatureInspector()
        let reviewer = SecurityReviewer(
            protections: ProtectionReader(),
            appFinder: ApplicationFolderAppFinder(
                folders: [URL(filePath: "/Applications"), home.appending(path: "Applications")],
                reader: reader
            ),
            signatureChecker: AppSignatureChecker(inspector: inspector, gatekeeper: SystemPolicyGatekeeper()),
            persistence: PersistenceScanner(
                folders: LaunchFolder.standard(home: home),
                reader: reader,
                attributor: LoginItemAttributor(appLocator: LaunchServicesAppLocator(), reader: reader),
                inspector: inspector
            )
        )
        return SecurityModule(viewModel: SecurityViewModel(reviewer: reviewer))
    }
}
