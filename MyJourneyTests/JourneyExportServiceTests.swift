import ImageIO
import UIKit
import XCTest
@testable import MyJourney

final class JourneyExportServiceTests: XCTestCase {
    func testGIFUsesPixelDimensionsAndFreeWatermarkChangesRenderedFrames() async throws {
        let journeyID = UUID()
        let image = makeImage(size: CGSize(width: 341, height: 768), color: .systemIndigo)
        let imageStore = ExportImageStore(image: image)
        let service = JourneyExportService(imageStore: imageStore)
        let entry = JourneyEntryMetadata(journeyID: journeyID, imageFilename: "frame.jpg")
        let freeJourney = Journey(id: journeyID, name: "Free Test", preferredCamera: .back, defaultOverlayOpacity: 0.45)
        let premiumJourney = Journey(id: journeyID, name: "Premium Test", preferredCamera: .back, defaultOverlayOpacity: 0.45)

        let freeAsset = try await service.exportTimeline(
            journey: freeJourney,
            entries: [entry],
            options: .default,
            format: .gif,
            includesFreeWatermark: true
        )
        let premiumAsset = try await service.exportTimeline(
            journey: premiumJourney,
            entries: [entry],
            options: .default,
            format: .gif,
            includesFreeWatermark: false
        )
        defer {
            try? FileManager.default.removeItem(at: freeAsset.fileURL)
            try? FileManager.default.removeItem(at: premiumAsset.fileURL)
        }

        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(
                try XCTUnwrap(CGImageSourceCreateWithURL(freeAsset.fileURL as CFURL, nil)),
                0,
                nil
            ) as? [CFString: Any]
        )
        XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, 341)
        XCTAssertEqual(properties[kCGImagePropertyPixelHeight] as? Int, 768)
        XCTAssertNotEqual(try Data(contentsOf: freeAsset.fileURL), try Data(contentsOf: premiumAsset.fileURL))
    }

    func testFreeWatermarkCopyIsStable() {
        XCTAssertEqual(FreeWatermark.text, "Made with My Journey · FREE")
    }

    func testStoreKitCatalogOffersOneTimeWatermarkRemovalForOneNinetyNine() throws {
        let configurationURL = try XCTUnwrap(
            Bundle(for: JourneyExportServiceTests.self).url(
                forResource: "Products",
                withExtension: "storekit"
            )
        )
        let data = try Data(contentsOf: configurationURL)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let products = try XCTUnwrap(object["products"] as? [[String: Any]])
        let product = try XCTUnwrap(products.first)

        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(product["productID"] as? String, StoreKitMonetizationService.removeWatermarkProductID)
        XCTAssertEqual(product["displayPrice"] as? String, "1.99")
        XCTAssertEqual(product["type"] as? String, "NonConsumable")
    }

    @MainActor
    func testPremiumEntitlementControlsWatermarkState() {
        let freeService = StoreKitMonetizationService(debugPremiumOverride: false)
        let premiumService = StoreKitMonetizationService(debugPremiumOverride: true)

        XCTAssertFalse(freeService.currentState.hasPremium)
        XCTAssertTrue(premiumService.currentState.hasPremium)
    }

    private func makeImage(size: CGSize, color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

private final class ExportImageStore: JourneyImageStoring {
    let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    func saveImage(_ image: UIImage, for journeyID: UUID, entryID: UUID) throws -> StoredJourneyImageAssets {
        StoredJourneyImageAssets(imageFilename: "frame.jpg", thumbnailFilename: nil)
    }

    func loadImage(journeyID: UUID, filename: String) -> UIImage? { image }
    func loadThumbnail(for journeyID: UUID, filename: String?) -> UIImage? { image }
    func loadPreview(journeyID: UUID, filename: String, maxDimension: CGFloat) -> UIImage? { image }
    func deleteAssets(for entries: [JourneyEntryMetadata]) throws {}
}
