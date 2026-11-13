import CleanMacUI
import SwiftUI

/// Full-window welcome that explains the permissions CleanMac uses and sends the user to grant
/// them. Each one is optional, so the user can always continue or skip.
public struct PermissionsOnboardingView: View {
    @ObservedObject private var viewModel: PermissionsViewModel
    private let theme = FeatureTheme.neutral

    public init(viewModel: PermissionsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        FeatureScreen(theme: theme) {
            VStack(spacing: 24) {
                OnboardingHeader(isFirstRun: viewModel.isFirstRun, theme: theme)
                HStack(alignment: .top, spacing: 20) {
                    FullDiskAccessCard(viewModel: viewModel, theme: theme)
                    FinderAutomationCard(viewModel: viewModel, theme: theme)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 820)
                OnboardingFooter(theme: theme) { viewModel.finish() }
                    .frame(maxWidth: 820)
            }
            .frame(minWidth: 600)
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
