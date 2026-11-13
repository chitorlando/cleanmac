import OnboardingFeature

final class InMemoryOnboardingStore: OnboardingStoring {
    var isCompleted = false
    var hadFullDiskAccess = false
}
