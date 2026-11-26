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
    /// Module that reads this Mac's real settings and checks the apps of its application folders.
    static func live() -> SecurityModule {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let reviewer = SecurityReviewer(
            protections: ProtectionReader(),
            appFinder: ApplicationFolderAppFinder(folders: [
                URL(filePath: "/Applications"),
                home.appending(path: "Applications")
            ]),
            signatureChecker: AppSignatureChecker(
                inspector: SecurityFrameworkSignatureInspector(),
                gatekeeper: SystemPolicyGatekeeper()
            )
        )
        return SecurityModule(viewModel: SecurityViewModel(reviewer: reviewer))
    }
}
