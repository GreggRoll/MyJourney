import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(settingsStore: SettingsStore) {
        _viewModel = StateObject(
            wrappedValue: OnboardingViewModel(settingsStore: settingsStore)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 16) {
                Text("My Journey")
                    .font(.system(size: 40, weight: .bold, design: .rounded))

                Text("Private progress photos that stay on your device.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "lock.shield",
                    title: "Local-first by design",
                    subtitle: "No accounts, no sync, no surprise uploads."
                )
                OnboardingFeatureRow(
                    icon: "camera.macro",
                    title: "Consistent journeys",
                    subtitle: "Save camera and overlay defaults for each routine."
                )
                OnboardingFeatureRow(
                    icon: "clock.arrow.circlepath",
                    title: "Quickly resume",
                    subtitle: "Jump back into your latest journey with one tap."
                )
            }

            Spacer()

            Button {
                viewModel.completeOnboarding()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .accessibilityIdentifier("onboardingContinueButton")

            Text("Your photos stay in this app’s local storage. Capture, compare, and export whenever you’re ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .alert("Couldn’t Save", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }
}

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .frame(width: 34, height: 34)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
