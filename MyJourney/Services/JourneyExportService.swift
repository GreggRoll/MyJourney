import AVFoundation
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

enum JourneyExportServiceError: LocalizedError {
    case noEntries
    case couldNotCreateDestination
    case missingFrameImage
    case couldNotFinalizeGIF
    case couldNotCreateWriter
    case couldNotCreateWriterInput
    case couldNotCreatePixelBufferAdaptor
    case couldNotStartWriting
    case pixelBufferCreationFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .noEntries:
            return "Add at least one entry before exporting."
        case .couldNotCreateDestination, .couldNotFinalizeGIF:
            return "The GIF export could not be generated."
        case .missingFrameImage:
            return "One or more images could not be loaded for export."
        case .couldNotCreateWriter, .couldNotCreateWriterInput, .couldNotCreatePixelBufferAdaptor, .couldNotStartWriting, .pixelBufferCreationFailed, .exportFailed:
            return "The MP4 export could not be generated."
        }
    }
}

protocol JourneyExportServing {
    func exportTimeline(
        journey: Journey,
        entries: [JourneyEntryMetadata],
        options: JourneyExportOptions,
        format: JourneyExportFormat,
        includesFreeWatermark: Bool
    ) async throws -> JourneyExportedAsset
}

struct JourneyExportService: JourneyExportServing {
    private let imageStore: JourneyImageStoring
    private let fileManager: FileManager

    init(imageStore: JourneyImageStoring, fileManager: FileManager = .default) {
        self.imageStore = imageStore
        self.fileManager = fileManager
    }

    func exportTimeline(
        journey: Journey,
        entries: [JourneyEntryMetadata],
        options: JourneyExportOptions,
        format: JourneyExportFormat,
        includesFreeWatermark: Bool
    ) async throws -> JourneyExportedAsset {
        let orderedEntries = entries.sorted(by: { $0.createdAt < $1.createdAt })
        guard orderedEntries.isEmpty == false else {
            throw JourneyExportServiceError.noEntries
        }

        try ensureExportDirectoryExists()

        switch format {
        case .gif:
            let url = exportDirectory.appendingPathComponent(exportFilename(for: journey, format: .gif))
            try exportGIF(
                journey: journey,
                entries: orderedEntries,
                options: options,
                includesFreeWatermark: includesFreeWatermark,
                to: url
            )
            return JourneyExportedAsset(format: .gif, fileURL: url)
        case .mp4:
            let url = exportDirectory.appendingPathComponent(exportFilename(for: journey, format: .mp4))
            try await exportMP4(
                journey: journey,
                entries: orderedEntries,
                options: options,
                to: url
            )
            return JourneyExportedAsset(format: .mp4, fileURL: url)
        }
    }

    private func renderFrame(
        image: UIImage,
        entry: JourneyEntryMetadata,
        sequenceNumber: Int,
        options: JourneyExportOptions,
        includesFreeWatermark: Bool
    ) -> UIImage {
        let normalized = normalizedImage(image)
        let targetSize = scaledExportSize(for: normalized.size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        return renderer.image { context in
            normalized.draw(in: CGRect(origin: .zero, size: targetSize))

            let overlayText = overlayText(
                entry: entry,
                sequenceNumber: sequenceNumber,
                options: options
            )

            if overlayText.isEmpty == false {
                drawEntryOverlay(overlayText, in: targetSize)
            }

            if includesFreeWatermark {
                drawFreeWatermark(in: context.cgContext, targetSize: targetSize)
            }
        }
    }

    private func drawEntryOverlay(_ overlayText: String, in targetSize: CGSize) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let font = UIFont.systemFont(ofSize: max(18, targetSize.width * 0.04), weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let attributedText = NSAttributedString(string: overlayText, attributes: attributes)
        let inset: CGFloat = 24
        let maxTextSize = CGSize(width: targetSize.width - (inset * 2), height: targetSize.height)
        let textRect = attributedText.boundingRect(
            with: maxTextSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).integral

        let backgroundRect = CGRect(
            x: inset - 10,
            y: targetSize.height - textRect.height - inset - 10,
            width: textRect.width + 20,
            height: textRect.height + 20
        )

        UIColor.black.withAlphaComponent(0.55).setFill()
        UIBezierPath(roundedRect: backgroundRect, cornerRadius: 16).fill()

        attributedText.draw(
            with: CGRect(
                x: inset,
                y: backgroundRect.minY + 10,
                width: textRect.width,
                height: textRect.height
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private func drawFreeWatermark(in context: CGContext, targetSize: CGSize) {
        let font = UIFont.systemFont(ofSize: max(24, targetSize.width * 0.055), weight: .black)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .kern: max(0.8, targetSize.width * 0.0015)
        ]
        let attributedText = NSAttributedString(string: FreeWatermark.text.uppercased(), attributes: attributes)
        let textSize = attributedText.size()
        let horizontalPadding = max(18, targetSize.width * 0.035)
        let verticalPadding = max(12, targetSize.width * 0.022)
        let badgeSize = CGSize(
            width: min(textSize.width + horizontalPadding * 2, targetSize.width * 0.92),
            height: textSize.height + verticalPadding * 2
        )

        context.saveGState()
        context.translateBy(x: targetSize.width / 2, y: targetSize.height * 0.58)
        context.rotate(by: -7 * .pi / 180)

        let badgeRect = CGRect(
            x: -badgeSize.width / 2,
            y: -badgeSize.height / 2,
            width: badgeSize.width,
            height: badgeSize.height
        )
        UIColor.black.withAlphaComponent(0.7).setFill()
        UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeSize.height / 2).fill()
        UIColor.white.withAlphaComponent(0.75).setStroke()
        let outline = UIBezierPath(roundedRect: badgeRect.insetBy(dx: 1, dy: 1), cornerRadius: badgeSize.height / 2)
        outline.lineWidth = max(1, targetSize.width * 0.002)
        outline.stroke()

        attributedText.draw(
            in: CGRect(
                x: -textSize.width / 2,
                y: -textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
        )
        context.restoreGState()
    }

    private func overlayText(
        entry: JourneyEntryMetadata,
        sequenceNumber: Int,
        options: JourneyExportOptions
    ) -> String {
        var lines: [String] = []

        if options.includesDateOverlay {
            lines.append(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
        }

        if options.includesEntryNumberOverlay {
            lines.append("Entry \(sequenceNumber)")
        }

        return lines.joined(separator: "\n")
    }

    private func exportGIF(
        journey: Journey,
        entries: [JourneyEntryMetadata],
        options: JourneyExportOptions,
        includesFreeWatermark: Bool,
        to url: URL
    ) throws {
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, entries.count, nil) else {
            throw JourneyExportServiceError.couldNotCreateDestination
        }

        let perFrameDuration = max(options.totalDuration / Double(max(entries.count, 1)), 0.08)
        let gifProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ] as CFDictionary
        CGImageDestinationSetProperties(destination, gifProperties)

        for (index, entry) in entries.enumerated() {
            try autoreleasepool {
                guard let image = imageStore.loadImage(journeyID: journey.id, filename: entry.imageFilename) else {
                    throw JourneyExportServiceError.missingFrameImage
                }
                let frame = renderFrame(
                    image: image,
                    entry: entry,
                    sequenceNumber: index + 1,
                    options: options,
                    includesFreeWatermark: includesFreeWatermark
                )
                guard let cgImage = frame.cgImage else {
                    throw JourneyExportServiceError.missingFrameImage
                }

                let frameProperties = [
                    kCGImagePropertyGIFDictionary: [
                        kCGImagePropertyGIFDelayTime: perFrameDuration
                    ]
                ] as CFDictionary

                CGImageDestinationAddImage(destination, cgImage, frameProperties)
            }
        }

        guard CGImageDestinationFinalize(destination) else {
            throw JourneyExportServiceError.couldNotFinalizeGIF
        }
    }

    private func exportMP4(
        journey: Journey,
        entries: [JourneyEntryMetadata],
        options: JourneyExportOptions,
        to url: URL
    ) async throws {
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }

        guard
            let firstEntry = entries.first,
            let firstImage = imageStore.loadImage(journeyID: journey.id, filename: firstEntry.imageFilename)
        else { throw JourneyExportServiceError.missingFrameImage }

        let firstFrame = renderFrame(
            image: firstImage,
            entry: firstEntry,
            sequenceNumber: 1,
            options: options,
            includesFreeWatermark: false
        )

        let frameSize = firstFrame.size.integralSize

        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else {
            throw JourneyExportServiceError.couldNotCreateWriter
        }

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: frameSize.width,
            AVVideoHeightKey: frameSize.height
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: frameSize.width,
            kCVPixelBufferHeightKey as String: frameSize.height
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        guard writer.canAdd(input) else {
            throw JourneyExportServiceError.couldNotCreateWriterInput
        }

        writer.add(input)

        guard writer.startWriting() else {
            throw JourneyExportServiceError.couldNotStartWriting
        }

        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(seconds: max(options.totalDuration / Double(max(entries.count, 1)), 0.08), preferredTimescale: 600)
        var presentationTime = CMTime.zero

        for (index, entry) in entries.enumerated() {
            while input.isReadyForMoreMediaData == false {
                try await Task.sleep(for: .milliseconds(10))
            }

            guard
                let image = imageStore.loadImage(journeyID: journey.id, filename: entry.imageFilename),
                let cgImage = renderFrame(
                    image: image,
                    entry: entry,
                    sequenceNumber: index + 1,
                    options: options,
                    includesFreeWatermark: false
                ).cgImage,
                let pixelBuffer = pixelBuffer(from: cgImage, size: frameSize, attributes: attributes)
            else {
                throw JourneyExportServiceError.pixelBufferCreationFailed
            }

            adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
            presentationTime = CMTimeAdd(presentationTime, frameDuration)
        }

        input.markAsFinished()

        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }

        switch writer.status {
        case .completed:
            return
        default:
            throw writer.error ?? JourneyExportServiceError.exportFailed
        }
    }

    private func pixelBuffer(from cgImage: CGImage, size: CGSize, attributes: [String: Any]) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(pixelBuffer),
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            )
        else {
            return nil
        }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        return pixelBuffer
    }

    private func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private func scaledExportSize(for originalSize: CGSize) -> CGSize {
        let maxDimension: CGFloat = 1080
        let longestSide = max(originalSize.width, originalSize.height)

        guard longestSide > maxDimension else {
            return originalSize.integralSize
        }

        let scale = maxDimension / longestSide
        return CGSize(
            width: (originalSize.width * scale).rounded(.toNearestOrAwayFromZero),
            height: (originalSize.height * scale).rounded(.toNearestOrAwayFromZero)
        )
    }

    private func exportFilename(for journey: Journey, format: JourneyExportFormat) -> String {
        let safeName = journey.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        let timestamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        return "\(safeName.isEmpty ? "journey" : safeName)-\(timestamp).\(format.fileExtension)"
    }

    private var exportDirectory: URL {
        fileManager.temporaryDirectory.appendingPathComponent("MyJourneyExports", isDirectory: true)
    }

    private func ensureExportDirectoryExists() throws {
        try fileManager.createDirectory(
            at: exportDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}

private extension CGSize {
    var integralSize: CGSize {
        CGSize(width: max(1, round(width)), height: max(1, round(height)))
    }
}
