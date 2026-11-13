import CleanMacCore
import OnboardingFeature
import Testing

@MainActor
struct PermissionsViewModelTests {
    private let fullDiskAccess = FakeFullDiskAccess()
    private let finder = FakeFinderAutomation()
    private let settings = RecordingSettingsOpener()
    private let store = InMemoryOnboardingStore()

    private func makeViewModel(pollInterval: Duration = .milliseconds(5)) -> PermissionsViewModel {
        PermissionsViewModel(
            fullDiskAccess: fullDiskAccess,
            finder: finder,
            settings: settings,
            store: store,
            pollInterval: pollInterval
        )
    }

    @Test func opensOnTheFirstLaunch() {
        let viewModel = makeViewModel()

        viewModel.prepareForLaunch()

        #expect(viewModel.isPresented)
        #expect(viewModel.isFirstRun)
        #expect(!viewModel.hasFullDiskAccess)
        #expect(viewModel.finderAutomation == .notDetermined)
    }

    @Test func staysClosedOnceFinished() {
        let viewModel = makeViewModel()
        viewModel.prepareForLaunch()

        viewModel.finish()
        let next = makeViewModel()
        next.prepareForLaunch()

        #expect(!viewModel.isPresented)
        #expect(!next.isPresented)
        #expect(store.isCompleted)
    }

    @Test func comesBackWhenFullDiskAccessIsLost() {
        fullDiskAccess.grant()
        let first = makeViewModel()
        first.prepareForLaunch()
        first.finish()

        fullDiskAccess.revoke()
        let next = makeViewModel()
        next.prepareForLaunch()

        #expect(store.hadFullDiskAccess)
        #expect(next.isPresented)
        #expect(next.showsFullDiskAccessNotice)
    }

    @Test(.timeLimit(.minutes(1)))
    func turnsGreenOnceTheUserGrantsFullDiskAccess() async {
        let viewModel = makeViewModel()
        let watch = Task { await viewModel.watchFullDiskAccess() }
        while fullDiskAccess.checks < 2 {
            try? await Task.sleep(for: .milliseconds(5))
        }

        fullDiskAccess.grant()
        await watch.value

        #expect(viewModel.hasFullDiskAccess)
        #expect(!viewModel.showsFullDiskAccessNotice)
        #expect(store.hadFullDiskAccess)
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsWatchingWhenCancelled() async {
        let viewModel = makeViewModel()
        let watch = Task { await viewModel.watchFullDiskAccess() }
        while fullDiskAccess.checks < 1 {
            try? await Task.sleep(for: .milliseconds(5))
        }

        watch.cancel()
        await watch.value
        let checks = fullDiskAccess.checks
        try? await Task.sleep(for: .milliseconds(30))

        #expect(fullDiskAccess.checks == checks)
    }

    @Test func asksAboutFinderOnlyWhenTheUserAllows() async {
        let viewModel = makeViewModel()
        await viewModel.refresh()
        #expect(finder.requests == 0)

        await viewModel.allowFinderAutomation()

        #expect(finder.requests == 1)
        #expect(viewModel.finderAutomation == .granted)
    }

    @Test func opensTheMatchingSettings() {
        let viewModel = makeViewModel()

        viewModel.openFullDiskAccessSettings()
        viewModel.openAutomationSettings()

        #expect(settings.opened == [.fullDiskAccess, .automation])
    }

    @Test func opensAgainFromTheMenu() {
        let viewModel = makeViewModel()

        viewModel.present()

        #expect(viewModel.isPresented)
    }
}
