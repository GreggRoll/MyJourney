import Foundation
import UIKit

@MainActor
struct SampleJourneySeeder {
    private let journeyStore: JourneyStore
    private let imageStore: JourneyImageStoring

    init(
        journeyStore: JourneyStore,
        imageStore: JourneyImageStoring
    ) {
        self.journeyStore = journeyStore
        self.imageStore = imageStore
    }

    func seedUITestJourney() {
        let journeyName = "Jennifer's Body"
        let legacyJourneyName = "Jenifer's body"

        guard
            journeyStore.journey(named: journeyName) == nil,
            journeyStore.journey(named: legacyJourneyName) == nil
        else {
            return
        }

        guard let journey = journeyStore.createJourney(
            name: journeyName,
            preferredCamera: .back,
            defaultOverlayOpacity: 0.45
        ) else { return }

        for index in 0..<5 {
            let createdAt = Calendar(identifier: .gregorian).date(
                byAdding: .day,
                value: index * 7,
                to: Date(timeIntervalSince1970: 1_735_732_800)
            ) ?? .now
            let entryID = UUID()

            do {
                let storedAssets = try imageStore.saveImage(
                    fixtureImage(index: index),
                    for: journey.id,
                    entryID: entryID
                )

                let metadata = JourneyEntryMetadata(
                    id: entryID,
                    journeyID: journey.id,
                    createdAt: createdAt,
                    updatedAt: createdAt,
                    imageFilename: storedAssets.imageFilename,
                    thumbnailFilename: storedAssets.thumbnailFilename
                )

                if !journeyStore.addEntryMetadata(metadata) {
                    try? imageStore.deleteAssets(for: [metadata])
                }
            } catch {
                continue
            }
        }
    }

    private func fixtureImage(index: Int) -> UIImage {
        let filenames = [
            "body_01_01_25",
            "body_01_08_25",
            "body_01_22_25",
            "body_01_29_25",
            "body_02_05_25"
        ]

        if filenames.indices.contains(index),
           let imageURL = Bundle.main.url(
               forResource: filenames[index],
               withExtension: "png",
               subdirectory: "JenifersBody"
           ),
           let image = UIImage(contentsOfFile: imageURL.path) {
            return image
        }

        let size = CGSize(width: 720, height: 1_280)
        let colors: [(UIColor, UIColor)] = [
            (.systemIndigo, .systemPurple),
            (.systemBlue, .systemTeal),
            (.systemTeal, .systemGreen),
            (.systemOrange, .systemPink),
            (.systemPink, .systemPurple)
        ]

        return UIGraphicsImageRenderer(size: size).image { context in
            let pair = colors[index % colors.count]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: [pair.0.cgColor, pair.1.cgColor] as CFArray,
                locations: [0, 1]
            )
            if let gradient {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 58, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            let title = "UI Test Entry \(index + 1)" as NSString
            title.draw(
                in: CGRect(x: 30, y: size.height / 2 - 45, width: size.width - 60, height: 90),
                withAttributes: attributes
            )
        }
    }
}
