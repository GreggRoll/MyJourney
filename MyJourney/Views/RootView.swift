import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: RootViewModel
    @ObservedObject private var container: AppContainer

    init(viewModel: RootViewModel, container: AppContainer) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
    }

    var body: some View {
        Group {
            if viewModel.shouldShowOnboarding {
                OnboardingView(settingsStore: container.settingsStore)
            } else {
                TabView {
                    JourneyListView(
                        journeyStore: container.journeyStore,
                        settingsStore: container.settingsStore,
                        imageStore: container.imageStore,
                        cameraAuthorizationService: container.cameraAuthorizationService,
                        exportService: container.exportService,
                        monetizationService: container.monetizationService
                    )
                    .tabItem {
                        Label("Journeys", systemImage: "square.stack.3d.up")
                    }

                    SettingsView(
                        settingsStore: container.settingsStore,
                        monetizationService: container.monetizationService,
                        photoReminderNotificationService: container.photoReminderNotificationService
                    )
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        }
        .task {
            await container.monetizationService.start()
            await container.syncPhotoReminderSchedule()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else {
                return
            }

            Task {
                await container.monetizationService.refreshEntitlements()
                await container.syncPhotoReminderSchedule()
            }
        }
    }
}
