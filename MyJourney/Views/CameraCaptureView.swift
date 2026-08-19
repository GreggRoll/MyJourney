@preconcurrency import AVFoundation
import AVKit
import SwiftUI
import UIKit

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: JourneyCaptureViewModel

    init(viewModel: JourneyCaptureViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = CameraLayoutMetrics(
                size: proxy.size,
                safeAreaInsets: proxy.safeAreaInsets
            )

            ZStack {
                Color.black.ignoresSafeArea()

                CameraPreviewRepresentable(
                    session: viewModel.cameraController.session,
                    isHardwareCaptureEnabled: viewModel.canCapture,
                    onHardwareCapture: viewModel.capturePhoto
                )
                .ignoresSafeArea()

                if let overlayImage = viewModel.latestReferenceImage {
                    Image(uiImage: overlayImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .opacity(viewModel.overlayOpacity)
                        .allowsHitTesting(false)
                } else {
                    VStack {
                        Spacer()

                        Text("No previous image yet")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())

                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 40)
                }

                if viewModel.isGridEnabled {
                    CameraGridOverlay()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                cameraChrome(metrics: metrics)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color.black)
        .task {
            viewModel.handleAppear()
        }
        .onDisappear {
            viewModel.handleDisappear()
        }
    }

    private func cameraChrome(metrics: CameraLayoutMetrics) -> some View {
        VStack(spacing: metrics.verticalSpacing) {
            HStack {
                closeButton(metrics: metrics)

                Spacer(minLength: metrics.horizontalSpacing)

                journeyBadge(metrics: metrics)
            }

            Spacer(minLength: 0)

            countdownText(metrics: metrics)

            controlsCard(metrics: metrics)
        }
        .padding(.horizontal, metrics.sidePadding)
        .padding(.top, metrics.topPadding)
        .padding(.bottom, metrics.bottomPadding)
        .frame(width: metrics.size.width, height: metrics.size.height)
    }

    private func closeButton(metrics: CameraLayoutMetrics) -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: metrics.closeIconSize, weight: .semibold))
                .frame(width: metrics.closeButtonSize, height: metrics.closeButtonSize)
                .foregroundStyle(.white)
                .background(.black.opacity(0.45), in: Circle())
        }
        .accessibilityLabel("Close Camera")
    }

    private func journeyBadge(metrics: CameraLayoutMetrics) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel.journey.name)
                .font(metrics.badgeTitleFont)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(viewModel.journey.preferredCamera.displayName)
                .font(metrics.badgeSubtitleFont)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, metrics.badgeHorizontalPadding)
        .padding(.vertical, metrics.badgeVerticalPadding)
        .frame(maxWidth: metrics.badgeMaxWidth, alignment: .trailing)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func countdownText(metrics: CameraLayoutMetrics) -> some View {
        if let countdownValue = viewModel.countdownValue {
            Text("\(countdownValue)")
                .font(.system(size: metrics.countdownFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 12)
                .allowsHitTesting(false)
        }
    }

    private func controlsCard(metrics: CameraLayoutMetrics) -> some View {
        VStack(spacing: metrics.controlSpacing) {
            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .font(metrics.statusFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            switch viewModel.permissionState {
            case .ready:
                captureControls(metrics: metrics)
            case .checking:
                ProgressView("Preparing camera…")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            case .denied:
                PermissionMessageView(
                    title: "Camera access is off",
                    message: "Enable camera access in Settings to capture journey photos.",
                    actionTitle: "Open Settings",
                    action: openSettings
                )
            case .restricted:
                PermissionMessageView(
                    title: "Camera access is restricted",
                    message: "This device currently restricts camera usage.",
                    actionTitle: nil,
                    action: nil
                )
            case .unavailable(let message):
                PermissionMessageView(
                    title: "Camera unavailable",
                    message: message,
                    actionTitle: "Try Again",
                    action: viewModel.requestPermissionAgain
                )
            }
        }
        .padding(metrics.cardPadding)
        .frame(width: metrics.cardWidth)
        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: metrics.cardCornerRadius))
    }

    @ViewBuilder
    private func captureControls(metrics: CameraLayoutMetrics) -> some View {
        if metrics.usesCompactCameraControls {
            HStack(alignment: .bottom, spacing: metrics.horizontalSpacing) {
                VStack(spacing: metrics.compactControlSpacing) {
                    opacityControl(metrics: metrics)
                    toggleControls(metrics: metrics)
                }
                .frame(maxWidth: .infinity)

                shutterButton(metrics: metrics)
            }
        } else {
            VStack(spacing: metrics.controlSpacing) {
                opacityControl(metrics: metrics)
                toggleControls(metrics: metrics)
                shutterButton(metrics: metrics)
                    .padding(.top, 2)
            }
        }
    }

    private func opacityControl(metrics: CameraLayoutMetrics) -> some View {
        VStack(spacing: metrics.compactControlSpacing) {
            HStack {
                Text("Overlay Opacity")
                    .font(metrics.labelFont)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: metrics.horizontalSpacing)

                Text(viewModel.opacityPercentageText)
                    .font(metrics.valueFont.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }

            Slider(value: $viewModel.overlayOpacity, in: 0...1)
                .accessibilityLabel("Reference overlay opacity")
                .accessibilityValue(viewModel.opacityPercentageText)
                .tint(.white)
        }
    }

    private func toggleControls(metrics: CameraLayoutMetrics) -> some View {
        HStack(spacing: metrics.toggleSpacing) {
            Toggle("Grid", isOn: $viewModel.isGridEnabled)
                .toggleStyle(.button)
                .frame(maxWidth: .infinity)

            Toggle("3s Timer", isOn: $viewModel.isTimerEnabled)
                .toggleStyle(.button)
                .frame(maxWidth: .infinity)
        }
        .font(metrics.toggleFont)
        .controlSize(metrics.usesCompactCameraControls ? .small : .regular)
        .tint(.white.opacity(0.2))
        .foregroundStyle(.white)
    }

    private func shutterButton(metrics: CameraLayoutMetrics) -> some View {
        Button {
            viewModel.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: metrics.shutterSize, height: metrics.shutterSize)

                Circle()
                    .stroke(.black.opacity(0.2), lineWidth: 2)
                    .frame(width: metrics.shutterRingSize, height: metrics.shutterRingSize)
            }
        }
        .disabled(!viewModel.canCapture)
        .accessibilityLabel("Take Photo")
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }
}

private struct CameraLayoutMetrics {
    let size: CGSize
    let safeAreaInsets: EdgeInsets

    private var usableHeight: CGFloat {
        max(1, size.height - safeAreaInsets.top - safeAreaInsets.bottom)
    }

    private var scale: CGFloat {
        min(1, max(0.78, min(size.width / 393, usableHeight / 760)))
    }

    var usesCompactCameraControls: Bool {
        usableHeight < 700 || size.width < 370
    }

    var sidePadding: CGFloat {
        min(16, max(10, size.width * 0.04))
    }

    var topPadding: CGFloat {
        safeAreaInsets.top + (usesCompactCameraControls ? 6 : 10)
    }

    var bottomPadding: CGFloat {
        safeAreaInsets.bottom + (usesCompactCameraControls ? 8 : 12)
    }

    var horizontalSpacing: CGFloat {
        usesCompactCameraControls ? 8 : 12
    }

    var verticalSpacing: CGFloat {
        usesCompactCameraControls ? 8 : 12
    }

    var controlSpacing: CGFloat {
        usesCompactCameraControls ? 10 : 14
    }

    var compactControlSpacing: CGFloat {
        usesCompactCameraControls ? 6 : 8
    }

    var toggleSpacing: CGFloat {
        usesCompactCameraControls ? 6 : 10
    }

    var cardPadding: CGFloat {
        usesCompactCameraControls ? 12 : 16
    }

    var cardCornerRadius: CGFloat {
        usesCompactCameraControls ? 18 : 22
    }

    var cardWidth: CGFloat {
        max(1, min(520, size.width - (sidePadding * 2)))
    }

    var closeButtonSize: CGFloat {
        max(42, 44 * scale)
    }

    var closeIconSize: CGFloat {
        max(15, 17 * scale)
    }

    var badgeMaxWidth: CGFloat {
        max(140, size.width - (sidePadding * 2) - closeButtonSize - horizontalSpacing)
    }

    var badgeHorizontalPadding: CGFloat {
        usesCompactCameraControls ? 10 : 14
    }

    var badgeVerticalPadding: CGFloat {
        usesCompactCameraControls ? 8 : 10
    }

    var shutterSize: CGFloat {
        if usesCompactCameraControls {
            return max(58, 66 * scale)
        }

        return max(66, 72 * scale)
    }

    var shutterRingSize: CGFloat {
        shutterSize - max(8, 10 * scale)
    }

    var countdownFontSize: CGFloat {
        usesCompactCameraControls ? 56 : 72
    }

    var badgeTitleFont: Font {
        usesCompactCameraControls ? .subheadline.weight(.semibold) : .headline
    }

    var badgeSubtitleFont: Font {
        usesCompactCameraControls ? .caption2 : .caption
    }

    var labelFont: Font {
        usesCompactCameraControls ? .caption : .subheadline
    }

    var valueFont: Font {
        usesCompactCameraControls ? .caption2 : .caption
    }

    var toggleFont: Font {
        usesCompactCameraControls ? .caption : .subheadline
    }

    var statusFont: Font {
        usesCompactCameraControls ? .caption : .subheadline
    }
}

private struct PermissionMessageView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(message)
                .foregroundStyle(.white.opacity(0.8))

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    let isHardwareCaptureEnabled: Bool
    let onHardwareCapture: @MainActor () -> Void

    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.previewLayer.session = session
        previewView.previewLayer.videoGravity = .resizeAspectFill
        previewView.configureHardwareCapture(
            isEnabled: isHardwareCaptureEnabled,
            handler: onHardwareCapture
        )
        return previewView
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
        uiView.configureHardwareCapture(
            isEnabled: isHardwareCaptureEnabled,
            handler: onHardwareCapture
        )
        if let connection = uiView.previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }
}

private final class PreviewView: UIView {
    private var captureEventInteraction: UIInteraction?
    private var onHardwareCapture: (@MainActor () -> Void)?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }

        return layer
    }

    func configureHardwareCapture(
        isEnabled: Bool,
        handler: @escaping @MainActor () -> Void
    ) {
        onHardwareCapture = handler

        guard #available(iOS 17.2, *) else {
            return
        }

        if captureEventInteraction == nil {
            let interaction = AVCaptureEventInteraction { [weak self] event in
                guard event.phase == .ended else {
                    return
                }

                Task { @MainActor in
                    self?.onHardwareCapture?()
                }
            }

            addInteraction(interaction)
            captureEventInteraction = interaction
        }

        (captureEventInteraction as? AVCaptureEventInteraction)?.isEnabled = isEnabled
    }
}

private struct CameraGridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let horizontalStep = rect.height / 3
        let verticalStep = rect.width / 3

        for index in 1..<3 {
            let horizontalY = horizontalStep * CGFloat(index)
            path.move(to: CGPoint(x: rect.minX, y: horizontalY))
            path.addLine(to: CGPoint(x: rect.maxX, y: horizontalY))

            let verticalX = verticalStep * CGFloat(index)
            path.move(to: CGPoint(x: verticalX, y: rect.minY))
            path.addLine(to: CGPoint(x: verticalX, y: rect.maxY))
        }

        return path
    }
}
