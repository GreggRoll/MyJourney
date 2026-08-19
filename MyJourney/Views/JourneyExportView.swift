import SwiftUI

struct JourneyExportView: View {
    @StateObject private var viewModel: JourneyExportViewModel
    @State private var sharedURL: URL?

    init(viewModel: JourneyExportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Playback") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Total Duration")
                            Spacer()
                            Text("\(viewModel.options.totalDuration, specifier: "%.1f")s")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $viewModel.options.totalDuration, in: 1...8, step: 0.5)
                            .accessibilityLabel("Total duration")
                            .accessibilityValue(String(format: "%.1f seconds", viewModel.options.totalDuration))
                    }
                }

                Section("Overlay") {
                    Toggle("Include date", isOn: $viewModel.options.includesDateOverlay)
                    Toggle("Include entry number", isOn: $viewModel.options.includesEntryNumberOverlay)
                }

                Section("Export") {
                    Button("Export GIF") {
                        viewModel.export(format: .gif)
                    }
                    .disabled(!viewModel.canExport)

                    Button("Export MP4") {
                        viewModel.export(format: .mp4)
                    }
                    .disabled(!viewModel.canExport)

                    if !viewModel.isPremium {
                        Label(
                            "Free GIF exports include a large “\(FreeWatermark.text)” watermark. MP4 exports are never watermarked.",
                            systemImage: "seal"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                    if viewModel.isExporting {
                        ProgressView("Rendering export…")
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: viewModel.lastExportedAsset) { _, asset in
            sharedURL = asset?.fileURL
        }
        .sheet(item: Binding(
            get: {
                sharedURL.map(ShareableFile.init(url:))
            },
            set: { shareable in
                sharedURL = shareable?.url
            }
        )) { shareable in
            ShareSheet(items: [shareable.url])
                .onDisappear {
                    viewModel.clearSharedAsset()
                }
        }
    }
}

private struct ShareableFile: Identifiable {
    let id = UUID()
    let url: URL
}
