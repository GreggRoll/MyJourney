import Foundation

@MainActor
final class JourneyEditorViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Journey)
    }

    @Published var name: String
    @Published var preferredCamera: JourneyCameraPreference
    @Published var defaultOverlayOpacity: Double

    let mode: Mode

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            self.name = ""
            self.preferredCamera = .front
            self.defaultOverlayOpacity = 0.45
        case .edit(let journey):
            self.name = journey.name
            self.preferredCamera = journey.preferredCamera
            self.defaultOverlayOpacity = journey.defaultOverlayOpacity
        }
    }

    var navigationTitle: String {
        switch mode {
        case .create:
            return "New Journey"
        case .edit:
            return "Edit Journey"
        }
    }

    var primaryActionTitle: String {
        switch mode {
        case .create:
            return "Create Journey"
        case .edit:
            return "Save Changes"
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
