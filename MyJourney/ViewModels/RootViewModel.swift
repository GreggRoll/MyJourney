import Combine
import Foundation

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var shouldShowOnboarding: Bool

    private var cancellables = Set<AnyCancellable>()

    init(settingsStore: SettingsStore) {
        self.shouldShowOnboarding = !settingsStore.settings.hasCompletedOnboarding

        settingsStore.$settings
            .map { !$0.hasCompletedOnboarding }
            .receive(on: RunLoop.main)
            .assign(to: &$shouldShowOnboarding)
    }
}
