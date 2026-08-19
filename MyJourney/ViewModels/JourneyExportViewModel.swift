import Combine
import Foundation

@MainActor
final class JourneyExportViewModel: ObservableObject {
    @Published var options: JourneyExportOptions
    @Published private(set) var isExporting = false
    @Published private(set) var lastExportedAsset: JourneyExportedAsset?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isPremium: Bool

    private let journey: Journey
    private let entries: [JourneyEntryMetadata]
    private let exportService: JourneyExportServing
    private let monetizationService: MonetizationService
    private var cancellables = Set<AnyCancellable>()

    init(
        journey: Journey,
        entries: [JourneyEntryMetadata],
        exportService: JourneyExportServing,
        monetizationService: MonetizationService
    ) {
        self.journey = journey
        self.entries = entries.sorted(by: { $0.createdAt < $1.createdAt })
        self.exportService = exportService
        self.monetizationService = monetizationService
        self.isPremium = monetizationService.currentState.hasPremium
        self.options = .default

        monetizationService.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.isPremium = state.hasPremium
            }
            .store(in: &cancellables)
    }

    var canExport: Bool {
        entries.isEmpty == false && isExporting == false
    }

    func export(format: JourneyExportFormat) {
        Task {
            isExporting = true
            errorMessage = nil
            defer { isExporting = false }

            do {
                lastExportedAsset = try await exportService.exportTimeline(
                    journey: journey,
                    entries: entries,
                    options: options,
                    format: format,
                    includesFreeWatermark: format == .gif && !isPremium
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearSharedAsset() {
        lastExportedAsset = nil
    }
}
