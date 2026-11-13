import CleanMacCore
import Combine
import Foundation

/// Drives the permissions onboarding: shows it when it's due, keeps the status of each
/// permission up to date and sends the user to the right place to grant it.
///
/// Every permission is optional, so the user can always continue without them.
@MainActor
public final class PermissionsViewModel: ObservableObject {
    public static let defaultPollInterval: Duration = .milliseconds(1_500)

    @Published public private(set) var isPresented = false
    @Published public private(set) var hasFullDiskAccess = false
    @Published public private(set) var finderAutomation = PermissionStatus.notDetermined

    private let fullDiskAccess: any FullDiskAccessChecking
    private let finder: any FinderAutomationAuthorizing
    private let settings: any PermissionSettingsOpening
    private let store: any OnboardingStoring
    private let pollInterval: Duration

    public init(
        fullDiskAccess: any FullDiskAccessChecking,
        finder: any FinderAutomationAuthorizing,
        settings: any PermissionSettingsOpening,
        store: any OnboardingStoring,
        pollInterval: Duration = defaultPollInterval
    ) {
        self.fullDiskAccess = fullDiskAccess
        self.finder = finder
        self.settings = settings
        self.store = store
        self.pollInterval = pollInterval
    }

    /// A quiet reminder is shown elsewhere while Full Disk Access is off.
    public var showsFullDiskAccessNotice: Bool { !hasFullDiskAccess }

    // MARK: Presenting

    /// Reads the permissions and opens the onboarding if it's due. See `OnboardingPolicy`.
    public func prepareForLaunch() async {
        await refresh()
        isPresented = OnboardingPolicy.showsAtLaunch(
            isCompleted: store.isCompleted,
            hadFullDiskAccess: store.hadFullDiskAccess,
            hasFullDiskAccess: hasFullDiskAccess
        )
    }

    /// Opens the onboarding again, from the menu or the reminder.
    public func present() {
        isPresented = true
        Task { await refresh() }
    }

    /// Closes the onboarding, by continuing or skipping, and doesn't open it at launch again.
    public func finish() {
        store.isCompleted = true
        isPresented = false
    }

    // MARK: Status

    /// Reads both permissions again. Neither read ever asks the user.
    public func refresh() async {
        await refreshFullDiskAccess()
        finderAutomation = finder.status()
    }

    /// Checks Full Disk Access every `pollInterval` until it's on or the calling task is
    /// cancelled, so the onboarding turns green as soon as the user grants it.
    public func watchFullDiskAccess() async {
        while !Task.isCancelled, !hasFullDiskAccess {
            await refreshFullDiskAccess()
            guard !hasFullDiskAccess else { return }
            try? await Task.sleep(for: pollInterval)
        }
    }

    // MARK: Actions

    public func openFullDiskAccessSettings() {
        settings.open(.fullDiskAccess)
    }

    public func openAutomationSettings() {
        settings.open(.automation)
    }

    /// Shows the system's question about controlling Finder, if it wasn't answered before.
    public func allowFinderAutomation() async {
        finderAutomation = await finder.requestAccess()
    }

    private func refreshFullDiskAccess() async {
        let checker = fullDiskAccess
        let granted = await Task.detached(priority: .utility) { checker.hasFullDiskAccess() }.value
        hasFullDiskAccess = granted
        if granted {
            store.hadFullDiskAccess = true
        }
    }
}

public extension PermissionsViewModel {
    /// Onboarding for this Mac, remembered in the user defaults.
    static func live() -> PermissionsViewModel {
        PermissionsViewModel(
            fullDiskAccess: ProtectedFileFullDiskAccessChecker(),
            finder: FinderAutomationAuthorizer(),
            settings: SystemSettingsOpener(),
            store: UserDefaultsOnboardingStore()
        )
    }
}
