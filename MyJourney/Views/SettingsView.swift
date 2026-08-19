import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(
        settingsStore: SettingsStore,
        monetizationService: MonetizationService,
        photoReminderNotificationService: PhotoReminderNotificationServing
    ) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                settingsStore: settingsStore,
                monetizationService: monetizationService,
                photoReminderNotificationService: photoReminderNotificationService
            )
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle(
                        "Show most recent journey quick resume",
                        isOn: Binding(
                            get: { viewModel.settings.showQuickResume },
                            set: { viewModel.setQuickResumeEnabled($0) }
                        )
                    )
                }

                Section("Reminders") {
                    Toggle(
                        "Daily photo reminder",
                        isOn: Binding(
                            get: { viewModel.settings.isPhotoReminderEnabled },
                            set: { viewModel.setPhotoReminderEnabled($0) }
                        )
                    )

                    DatePicker(
                        "Reminder time",
                        selection: Binding(
                            get: { viewModel.photoReminderTime },
                            set: { viewModel.setPhotoReminderTime($0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!viewModel.settings.isPhotoReminderEnabled)

                    if viewModel.photoReminderAuthorizationStatus == .denied {
                        Button("Open iPhone Settings") {
                            viewModel.openSystemNotificationSettings()
                        }
                    }

                    if let statusMessage = viewModel.photoReminderStatusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if viewModel.monetizationState.hasPremium {
                        Label("Watermark removed", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)

                        Text("Compare and GIF exports are watermark-free on this Apple Account.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Remove the free watermark")
                                .font(.headline)
                            Text("One purchase removes the watermark from Compare and GIF exports forever.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            viewModel.purchasePremium()
                        } label: {
                            HStack {
                                Label("Remove Watermark", systemImage: "sparkles")
                                Spacer()
                                Text(viewModel.monetizationState.premiumDisplayPrice ?? "$1.99")
                            }
                        }
                        .disabled(viewModel.monetizationState.isLoading)
                    }

                    Button("Restore Purchases") {
                        viewModel.restorePurchases()
                    }
                    .disabled(viewModel.monetizationState.isLoading)

                    if viewModel.monetizationState.isLoading {
                        ProgressView("Contacting the App Store…")
                    }

                    if let statusMessage = viewModel.monetizationState.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("My Journey Premium")
                } footer: {
                    Text("The free version only watermarks Compare and GIF exports. MP4 exports and all other features stay free.")
                }

                Section("Support") {
                    NavigationLink("Privacy & About") {
                        PrivacyAboutView()
                    }
                }

                if let persistenceErrorMessage = viewModel.persistenceErrorMessage {
                    Section("Local Storage") {
                        Label(persistenceErrorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            await viewModel.handleAppear()
        }
    }
}
