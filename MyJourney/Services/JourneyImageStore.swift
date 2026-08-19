import Foundation
import ImageIO
import UIKit

struct StoredJourneyImageAssets {
    let imageFilename: String
    let thumbnailFilename: String?
}

protocol JourneyImageStoring {
    func saveImage(_ image: UIImage, for journeyID: UUID, entryID: UUID) throws -> StoredJourneyImageAssets
    func loadImage(journeyID: UUID, filename: String) -> UIImage?
    func loadThumbnail(for journeyID: UUID, filename: String?) -> UIImage?
    func loadPreview(journeyID: UUID, filename: String, maxDimension: CGFloat) -> UIImage?
    func deleteAssets(for entries: [JourneyEntryMetadata]) throws
}

enum JourneyImageStoreError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        "The image could not be saved locally."
    }
}

final class JourneyImageStore: JourneyImageStoring {
    private let fileManager: FileManager
    private let previewCache = NSCache<NSString, UIImage>()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        previewCache.countLimit = 40
        previewCache.totalCostLimit = 48 * 1_024 * 1_024
    }

    func saveImage(_ image: UIImage, for journeyID: UUID, entryID: UUID) throws -> StoredJourneyImageAssets {
        try ensureBaseDirectoryExists()

        let imageFilename = "\(entryID.uuidString).jpg"
        let thumbnailFilename = "\(entryID.uuidString)-thumb.jpg"
        let imageURL = imageURL(for: journeyID, filename: imageFilename)
        let thumbnailURL = thumbnailURL(for: journeyID, filename: thumbnailFilename)

        guard let imageData = image.jpegData(compressionQuality: 0.92) else {
            throw JourneyImageStoreError.encodingFailed
        }

        let thumbnailImage = scaledImage(from: image, maxDimension: 480)
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            throw JourneyImageStoreError.encodingFailed
        }

        try ensureDirectoryExists(at: imageURL.deletingLastPathComponent())
        try ensureDirectoryExists(at: thumbnailURL.deletingLastPathComponent())

        try imageData.write(to: imageURL, options: .atomic)
        try thumbnailData.write(to: thumbnailURL, options: .atomic)

        return StoredJourneyImageAssets(
            imageFilename: imageFilename,
            thumbnailFilename: thumbnailFilename
        )
    }

    func loadImage(journeyID: UUID, filename: String) -> UIImage? {
        let url = imageURL(for: journeyID, filename: filename)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return UIImage(data: data)
    }

    func loadThumbnail(for journeyID: UUID, filename: String?) -> UIImage? {
        guard let filename else {
            return nil
        }

        let url = thumbnailURL(for: journeyID, filename: filename)
        return cachedDownsampledImage(at: url, maxDimension: 480)
    }

    func loadPreview(journeyID: UUID, filename: String, maxDimension: CGFloat) -> UIImage? {
        cachedDownsampledImage(
            at: imageURL(for: journeyID, filename: filename),
            maxDimension: maxDimension
        )
    }

    func deleteAssets(for entries: [JourneyEntryMetadata]) throws {
        for entry in entries {
            let imageURL = imageURL(for: entry.journeyID, filename: entry.imageFilename)
            if fileManager.fileExists(atPath: imageURL.path) {
                try fileManager.removeItem(at: imageURL)
            }

            if let thumbnailFilename = entry.thumbnailFilename {
                let thumbnailURL = thumbnailURL(for: entry.journeyID, filename: thumbnailFilename)
                if fileManager.fileExists(atPath: thumbnailURL.path) {
                    try fileManager.removeItem(at: thumbnailURL)
                }
            }
        }
    }

    private func scaledImage(from image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        let maxSide = max(originalSize.width, originalSize.height)

        guard maxSide > maxDimension else {
            return image
        }

        let scaleRatio = maxDimension / maxSide
        let scaledSize = CGSize(
            width: originalSize.width * scaleRatio,
            height: originalSize.height * scaleRatio
        )

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }

    private func cachedDownsampledImage(at url: URL, maxDimension: CGFloat) -> UIImage? {
        let key = "\(url.path)#\(Int(maxDimension))" as NSString
        if let cachedImage = previewCache.object(forKey: key) {
            return cachedImage
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxDimension))
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let image = UIImage(cgImage: cgImage)
        previewCache.setObject(
            image,
            forKey: key,
            cost: cgImage.bytesPerRow * cgImage.height
        )
        return image
    }

    private func imageURL(for journeyID: UUID, filename: String) -> URL {
        imagesDirectory(for: journeyID).appendingPathComponent(filename, isDirectory: false)
    }

    private func thumbnailURL(for journeyID: UUID, filename: String) -> URL {
        thumbnailsDirectory(for: journeyID).appendingPathComponent(filename, isDirectory: false)
    }

    private func journeyDirectory(for journeyID: UUID) -> URL {
        baseDirectory.appendingPathComponent(journeyID.uuidString, isDirectory: true)
    }

    private func imagesDirectory(for journeyID: UUID) -> URL {
        journeyDirectory(for: journeyID).appendingPathComponent("images", isDirectory: true)
    }

    private func thumbnailsDirectory(for journeyID: UUID) -> URL {
        journeyDirectory(for: journeyID).appendingPathComponent("thumbnails", isDirectory: true)
    }

    private var baseDirectory: URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return root
            .appendingPathComponent("MyJourney", isDirectory: true)
            .appendingPathComponent("JourneyAssets", isDirectory: true)
    }

    private func ensureBaseDirectoryExists() throws {
        try ensureDirectoryExists(at: baseDirectory)
    }

    private func ensureDirectoryExists(at url: URL) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
