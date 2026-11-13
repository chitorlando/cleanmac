import OnboardingFeature
import Testing

struct OnboardingPolicyTests {
    @Test func showsOnTheFirstLaunch() {
        #expect(OnboardingPolicy.showsAtLaunch(isCompleted: false, hadFullDiskAccess: false, hasFullDiskAccess: false))
        #expect(OnboardingPolicy.showsAtLaunch(isCompleted: false, hadFullDiskAccess: false, hasFullDiskAccess: true))
    }

    @Test func staysClosedOnceDone() {
        #expect(!OnboardingPolicy.showsAtLaunch(isCompleted: true, hadFullDiskAccess: false, hasFullDiskAccess: false))
        #expect(!OnboardingPolicy.showsAtLaunch(isCompleted: true, hadFullDiskAccess: true, hasFullDiskAccess: true))
    }

    @Test func comesBackWhenFullDiskAccessWasLost() {
        #expect(OnboardingPolicy.showsAtLaunch(isCompleted: true, hadFullDiskAccess: true, hasFullDiskAccess: false))
    }
}
