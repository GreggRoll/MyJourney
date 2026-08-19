import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var errorMessage: String?

    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func completeOnboarding() {
        settingsStore.setOnboardingCompleted()
        errorMessage = settingsStore.persistenceErrorMessage
    }

    func clearError() {
        errorMessage = nil
    }
}
