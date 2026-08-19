import SwiftUI

struct JourneyDetailView: View {
    @StateObject private var viewModel: JourneyDetailViewModel
    private let cameraAuthorizationService: CameraAuthorizationProviding

    @State private var isShowingCamera = false
    @State private var isShowingCompare = false
    @State private var isShowingExport = false

    init(
        journeyID: UUID,
        journeyStore: JourneyStore,
        imageStore: JourneyImageStoring,
        cameraAuthorizationService: CameraAuthorizationProviding,
        exportService: JourneyExportServing,
        monetizationService: MonetizationService
    ) {
        _viewModel = StateObject(
            wrappedValue: JourneyDetailViewModel(
                journeyID: journeyID,
                journeyStore: journeyStore,
                imageStore: imageStore,
                exportService: exportService,
                monetizationService: monetizationService
            )
        )
        self.cameraAuthorizationService = cameraAuthorizationService
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                previewCard

                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.journey.name)
                        .font(.largeTitle.bold())
                    Label("\(viewModel.entryCount) entries", systemImage: "square.stack.3d.up")
                    Label(viewModel.journey.preferredCamera.displayName, systemImage: "camera.rotate")
                    Label(
                        "Default overlay \(viewModel.journey.defaultOverlayOpacity.formatted(.percent.precision(.fractionLength(0))))",
                        systemImage: "square.on.square.squareshape.controlhandles"
                    )
                }

                HStack(spacing: 12) {
                    actionButton(
                        title: "Open Camera",
                        systemImage: "camera",
                        style: .filled
                    ) {
                        isShowingCamera = true
                    }

                    actionButton(
                        title: "Compare",
                        systemImage: "book",
                        style: .outline
                    ) {
                        isShowingCompare = true
                    }
                    .disabled(viewModel.entryCount < 2)
                    .accessibilityIdentifier("compareButton")

                    actionButton(
                        title: "Export",
                        systemImage: "square.and.arrow.up",
                        style: .outline
                    ) {
                        isShowingExport = true
                    }
                    .disabled(viewModel.entryCount == 0)
                }

                comparisonCard

                VStack(alignment: .leading, spacing: 14) {
                    Text("Timeline")
                        .font(.title2.bold())

                    if viewModel.timelineEntries.isEmpty {
                        ContentUnavailableView(
                            "No Timeline Yet",
                            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                            description: Text("Capture your first entry to start the journey timeline.")
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.timelineEntries) { entry in
                                JourneyTimelineRow(entry: entry)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Journey")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraCaptureView(
                viewModel: viewModel.makeCaptureViewModel(
                    authorizationService: cameraAuthorizationService,
                    onCaptureSaved: {
                        isShowingCamera = false
                    }
                )
            )
        }
        .sheet(isPresented: $isShowingCompare) {
            JourneyCompareView(viewModel: viewModel.makeCompareViewModel())
        }
        .sheet(isPresented: $isShowingExport) {
            JourneyExportView(viewModel: viewModel.makeExportViewModel())
        }
    }

    private var previewCard: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.quaternary)
            .frame(height: 320)
            .overlay {
                if let latestImage = viewModel.latestImage {
                    Image(uiImage: latestImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 36))
                        Text("No captures yet")
                            .font(.headline)
                        Text("Open the camera to create the first frame for this journey.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .clipped()
    }

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare")
                .font(.title3.bold())

            if let firstEntry = viewModel.firstEntry, let latestEntry = viewModel.latestEntry {
                HStack(spacing: 12) {
                    JourneySnapshotCard(title: "First", entry: firstEntry)
                    JourneySnapshotCard(title: "Latest", entry: latestEntry)
                }

                Text("Compare opens with first vs latest by default, and you can choose two entries inside the compare screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Once you have entries, My Journey can compare the first and latest side by side.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(
        title: String,
        systemImage: String,
        style: ActionButtonStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(background(for: style))
                .foregroundStyle(style == .filled ? Color(.systemBackground) : Color.primary)
                .overlay {
                    if style == .outline {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.quaternary, lineWidth: 1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func background(for style: ActionButtonStyle) -> some View {
        switch style {
        case .filled:
            Color.primary
        case .outline:
            Color(.secondarySystemBackground)
        }
    }
}

private enum ActionButtonStyle {
    case filled
    case outline
}

private struct JourneySnapshotCard: View {
    let title: String
    let entry: JourneyTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image = entry.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.quaternary)
                    .frame(height: 120)
            }

            Text(title)
                .font(.headline)
            Text(entry.title)
                .font(.subheadline)
            Text(entry.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct JourneyTimelineRow: View {
    let entry: JourneyTimelineEntry

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let image = entry.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 76, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.headline)
                Text(entry.subtitle)
                    .foregroundStyle(.secondary)
                Text("Saved locally")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))
    }
}
