import SwiftUI

struct JourneyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: JourneyEditorViewModel

    let onSave: (JourneyEditorViewModel) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Journey Name", text: $viewModel.name)

                    Picker("Preferred Camera", selection: $viewModel.preferredCamera) {
                        ForEach(JourneyCameraPreference.allCases) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }
                }

                Section("Overlay") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Default Opacity")
                            Spacer()
                            Text(viewModel.defaultOverlayOpacity, format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $viewModel.defaultOverlayOpacity, in: 0.1...0.9)
                            .accessibilityLabel("Default overlay opacity")
                            .accessibilityValue(viewModel.defaultOverlayOpacity.formatted(.percent.precision(.fractionLength(0))))
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.primaryActionTitle) {
                        onSave(viewModel)
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}
