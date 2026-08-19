#!/usr/bin/env swift

import AppKit
import Foundation

struct MarketingScreen {
    let inputName: String
    let outputName: String
    let eyebrow: String
    let headline: String
    let subheadline: String
    let startColor: NSColor
    let endColor: NSColor
}

enum DeviceKind: String, CaseIterable {
    case iphone
    case ipad

    var size: CGSize {
        switch self {
        case .iphone: CGSize(width: 1_290, height: 2_796)
        case .ipad: CGSize(width: 2_064, height: 2_752)
        }
    }

    var screenWidth: CGFloat {
        switch self {
        case .iphone: 920
        case .ipad: 1_880
        }
    }

    var screenAspectRatio: CGFloat {
        switch self {
        case .iphone: 1_290 / 2_796
        case .ipad: 2_064 / 2_752
        }
    }

    var screenTop: CGFloat {
        switch self {
        case .iphone: 650
        case .ipad: 430
        }
    }

    var frameInset: CGFloat {
        switch self {
        case .iphone: 18
        case .ipad: 20
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .iphone: 70
        case .ipad: 54
        }
    }
}

let screens: [MarketingScreen] = [
    MarketingScreen(
        inputName: "03_compare.png",
        outputName: "01_see_every_change.png",
        eyebrow: "COMPARE",
        headline: "See every change",
        subheadline: "Slide between your first and latest photo.",
        startColor: NSColor(red: 0.24, green: 0.12, blue: 0.70, alpha: 1),
        endColor: NSColor(red: 0.93, green: 0.25, blue: 0.48, alpha: 1)
    ),
    MarketingScreen(
        inputName: "02_journey_detail.png",
        outputName: "02_make_progress_a_habit.png",
        eyebrow: "CONSISTENCY",
        headline: "Make progress a habit",
        subheadline: "Consistent framing. A timeline that keeps you going.",
        startColor: NSColor(red: 0.00, green: 0.34, blue: 0.88, alpha: 1),
        endColor: NSColor(red: 0.10, green: 0.75, blue: 0.62, alpha: 1)
    ),
    MarketingScreen(
        inputName: "01_onboarding.png",
        outputName: "03_your_journey_stays_yours.png",
        eyebrow: "PRIVATE BY DESIGN",
        headline: "Your journey stays yours",
        subheadline: "No account. No sync. No surprise uploads.",
        startColor: NSColor(red: 0.06, green: 0.07, blue: 0.15, alpha: 1),
        endColor: NSColor(red: 0.34, green: 0.20, blue: 0.72, alpha: 1)
    )
]

let scriptURL = URL(fileURLWithPath: #filePath)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

func topRect(canvasHeight: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, x: CGFloat) -> CGRect {
    CGRect(x: x, y: canvasHeight - top - height, width: width, height: height)
}

func drawText(
    _ text: String,
    in rect: CGRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .center,
    tracking: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    (text as NSString).draw(
        in: rect,
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: tracking
        ]
    )
}

func sourceRect(for screen: MarketingScreen, device: DeviceKind, image: NSImage) -> CGRect {
    guard device == .ipad, screen.inputName == "01_onboarding.png" else {
        return CGRect(origin: .zero, size: image.size)
    }

    // The onboarding layout intentionally uses generous vertical space on iPad.
    // This close crop keeps the feature cards legible in the marketing composition.
    let cropHeight: CGFloat = 2_200
    let cropWidth = cropHeight * 0.75
    return CGRect(x: 0, y: 0, width: cropWidth, height: cropHeight)
}

func render(_ screen: MarketingScreen, for device: DeviceKind) throws {
    let canvasSize = device.size
    let inputURL = projectRoot
        .appendingPathComponent("AppStoreScreenshots/raw")
        .appendingPathComponent(device.rawValue)
        .appendingPathComponent(screen.inputName)
    let outputURL = projectRoot
        .appendingPathComponent("AppStoreScreenshots/final")
        .appendingPathComponent(device.rawValue)
        .appendingPathComponent(screen.outputName)

    guard let sourceImage = NSImage(contentsOf: inputURL) else {
        throw NSError(domain: "AppStoreScreenshots", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Could not open \(inputURL.path)"
        ])
    }

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "AppStoreScreenshots", code: 2)
    }

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "AppStoreScreenshots", code: 3)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer { NSGraphicsContext.restoreGraphicsState() }

    let context = graphicsContext.cgContext
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [screen.startColor.cgColor, screen.endColor.cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: canvasSize.height),
        end: CGPoint(x: canvasSize.width, y: 0),
        options: []
    )

    context.saveGState()
    context.setFillColor(NSColor.white.withAlphaComponent(0.10).cgColor)
    context.fillEllipse(in: CGRect(
        x: -canvasSize.width * 0.18,
        y: canvasSize.height * 0.53,
        width: canvasSize.width * 0.78,
        height: canvasSize.width * 0.78
    ))
    context.setFillColor(NSColor.white.withAlphaComponent(0.07).cgColor)
    context.fillEllipse(in: CGRect(
        x: canvasSize.width * 0.60,
        y: canvasSize.height * 0.66,
        width: canvasSize.width * 0.58,
        height: canvasSize.width * 0.58
    ))
    context.restoreGState()

    let horizontalInset: CGFloat = device == .iphone ? 72 : 120
    let eyebrowTop: CGFloat = device == .iphone ? 70 : 56
    let eyebrowHeight: CGFloat = device == .iphone ? 42 : 46
    let headlineTop: CGFloat = device == .iphone ? 130 : 105
    let headlineHeight: CGFloat = device == .iphone ? 135 : 130
    let subheadlineTop: CGFloat = device == .iphone ? 285 : 245
    let subheadlineHeight: CGFloat = device == .iphone ? 120 : 100

    drawText(
        screen.eyebrow,
        in: topRect(
            canvasHeight: canvasSize.height,
            top: eyebrowTop,
            width: canvasSize.width - horizontalInset * 2,
            height: eyebrowHeight,
            x: horizontalInset
        ),
        font: .systemFont(ofSize: device == .iphone ? 29 : 31, weight: .bold),
        color: .white.withAlphaComponent(0.82),
        tracking: 4
    )
    drawText(
        screen.headline,
        in: topRect(
            canvasHeight: canvasSize.height,
            top: headlineTop,
            width: canvasSize.width - horizontalInset * 2,
            height: headlineHeight,
            x: horizontalInset
        ),
        font: .systemFont(ofSize: device == .iphone ? 96 : 104, weight: .bold),
        color: .white
    )
    drawText(
        screen.subheadline,
        in: topRect(
            canvasHeight: canvasSize.height,
            top: subheadlineTop,
            width: canvasSize.width - horizontalInset * 2,
            height: subheadlineHeight,
            x: horizontalInset
        ),
        font: .systemFont(ofSize: device == .iphone ? 42 : 45, weight: .medium),
        color: .white.withAlphaComponent(0.90)
    )

    let screenWidth = device.screenWidth
    let screenHeight = screenWidth / device.screenAspectRatio
    let screenX = (canvasSize.width - screenWidth) / 2
    let screenY = canvasSize.height - device.screenTop - screenHeight
    let screenRect = CGRect(x: screenX, y: screenY, width: screenWidth, height: screenHeight)
    let frameRect = screenRect.insetBy(dx: -device.frameInset, dy: -device.frameInset)

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: device == .iphone ? -24 : -18),
        blur: device == .iphone ? 44 : 36,
        color: NSColor.black.withAlphaComponent(0.34).cgColor
    )
    NSColor.black.withAlphaComponent(0.88).setFill()
    NSBezierPath(
        roundedRect: frameRect,
        xRadius: device.cornerRadius + device.frameInset,
        yRadius: device.cornerRadius + device.frameInset
    ).fill()
    context.restoreGState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(
        roundedRect: screenRect,
        xRadius: device.cornerRadius,
        yRadius: device.cornerRadius
    ).addClip()
    sourceImage.draw(
        in: screenRect,
        from: sourceRect(for: screen, device: device, image: sourceImage),
        operation: .copy,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AppStoreScreenshots", code: 4)
    }
    try png.write(to: outputURL, options: .atomic)
    print("Created \(outputURL.path)")
}

do {
    for device in DeviceKind.allCases {
        for screen in screens {
            try render(screen, for: device)
        }
    }
} catch {
    fputs("Screenshot generation failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
