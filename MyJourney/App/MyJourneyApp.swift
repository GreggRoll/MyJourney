import SwiftUI

@main
struct MyJourneyApp: App {
    @StateObject private var container = AppContainer.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: RootViewModel(
                    settingsStore: container.settingsStore
                ),
                container: container
            )
        }
    }
}
