import SwiftUI

struct JourneyListView: View {
    @StateObject private var viewModel: JourneyListViewModel
    private let journeyStore: JourneyStore
    private let imageStore: JourneyImageStoring
    private let cameraAuthorizationService: CameraAuthorizationProviding
    private let exportService: JourneyExportServing
    private let monetizationService: MonetizationService

    @State private var activeSheet: JourneySheet?
    @State private var pendingDeletion: Journey?
    @State private var errorMessage: String?

    init(
        journeyStore: JourneyStore,
        settingsStore: SettingsStore,
        imageStore: JourneyImageStoring,
        cameraAuthorizationService: CameraAuthorizationProviding,
        exportService: JourneyExportServing,
        monetizationService: MonetizationService
    ) {
        self.journeyStore = journeyStore
        self.imageStore = imageStore
        self.cameraAuthorizationService = cameraAuthorizationService
        self.exportService = exportService
        self.monetizationService = monetizationService
        _viewModel = StateObject(
            wrappedValue: JourneyListViewModel(
                journeyStore: journeyStore,
                settingsStore: settingsStore,
                imageStore: imageStore
            )
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if let quickResumeJourney = viewModel.quickResumeJourney {
                    Section {
                        NavigationLink {
                            JourneyDetailView(
                                journeyID: quickResumeJourney.id,
                                journeyStore: journeyStore,
                                imageStore: imageStore,
                                cameraAuthorizationService: cameraAuthorizationService,
                                exportService: exportService,
                                monetizationService: monetizationService
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Quick Resume")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 14) {
                                    JourneyThumbnailView(
                                        image: viewModel.latestThumbnail(for: quickResumeJourney),
                                        placeholderSystemImage: "photo.on.rectangle.angled",
                                        size: CGSize(width: 64, height: 64)
                                    )

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(quickResumeJourney.name)
                                            .font(.headline)
                                        Text("\(viewModel.entryCount(for: quickResumeJourney)) entries")
                                            .foregroundStyle(.secondary)
                                        Text("Uses \(quickResumeJourney.preferredCamera.displayName)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Section("Journeys") {
                    if viewModel.journeys.isEmpty {
                        ContentUnavailableView(
                            "No Journeys Yet",
                            systemImage: "square.stack.3d.up.slash",
                            description: Text("Create your first journey to start building a consistent photo routine.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.journeys) { journey in
                            NavigationLink {
                                JourneyDetailView(
                                    journeyID: journey.id,
                                    journeyStore: journeyStore,
                                    imageStore: imageStore,
                                    cameraAuthorizationService: cameraAuthorizationService,
                                    exportService: exportService,
                                    monetizationService: monetizationService
                                )
                            } label: {
                                JourneyRowView(
                                    journey: journey,
                                    entryCount: viewModel.entryCount(for: journey),
                                    thumbnail: viewModel.latestThumbnail(for: journey)
                                )
                            }
                            .accessibilityElement(children: .combine)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    pendingDeletion = journey
                                }

                                Button("Edit") {
                                    activeSheet = .edit(journey)
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Journey")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .create
                    } label: {
                        Label("New Journey", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .create:
                    JourneyEditorView(
                        viewModel: JourneyEditorViewModel(mode: .create),
                        onSave: { editor in
                            if journeyStore.createJourney(
                                name: editor.name.trimmingCharacters(in: .whitespacesAndNewlines),
                                preferredCamera: editor.preferredCamera,
                                defaultOverlayOpacity: editor.defaultOverlayOpacity
                            ) == nil {
                                errorMessage = journeyStore.persistenceErrorMessage
                            }
                        }
                    )
                case .edit(let journey):
                    JourneyEditorView(
                        viewModel: JourneyEditorViewModel(mode: .edit(journey)),
                        onSave: { editor in
                            if !journeyStore.updateJourney(
                                id: journey.id,
                                name: editor.name.trimmingCharacters(in: .whitespacesAndNewlines),
                                preferredCamera: editor.preferredCamera,
                                defaultOverlayOpacity: editor.defaultOverlayOpacity
                            ) {
                                errorMessage = journeyStore.persistenceErrorMessage
                            }
                        }
                    )
                }
            }
            .confirmationDialog(
                "Delete \(pendingDeletion?.name ?? "this journey")?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Journey", role: .destructive) {
                    if let journey = pendingDeletion,
                       !journeyStore.deleteJourney(id: journey.id) {
                        errorMessage = journeyStore.persistenceErrorMessage
                    }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeletion = nil
                }
            } message: {
                Text("This removes the journey and all of its photos from this device. This cannot be undone.")
            }
            .alert("Couldn’t Save Changes", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .onAppear {
                errorMessage = journeyStore.persistenceErrorMessage
            }
        }
    }
}

private enum JourneySheet: Identifiable {
    case create
    case edit(Journey)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let journey):
            return "edit-\(journey.id.uuidString)"
        }
    }
}

private struct JourneyRowView: View {
    let journey: Journey
    let entryCount: Int
    let thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            JourneyThumbnailView(
                image: thumbnail,
                placeholderSystemImage: "photo",
                size: CGSize(width: 58, height: 58)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(journey.name)
                    .font(.headline)
                Text("\(entryCount) entries")
                    .foregroundStyle(.secondary)
                Text("Updated \(journey.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct JourneyThumbnailView: View {
    let image: UIImage?
    let placeholderSystemImage: String
    let size: CGSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.quaternary)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: placeholderSystemImage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
