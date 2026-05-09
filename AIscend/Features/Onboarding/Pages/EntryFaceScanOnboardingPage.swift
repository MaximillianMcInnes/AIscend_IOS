//
//  EntryFaceScanOnboardingPage.swift
//  AIscend
//

import AVFoundation
import SwiftUI
import Vision

struct EntryFaceScanOnboardingPage: View {
    let onSkip: () -> Void
    let onComplete: () -> Void

    @StateObject private var scanner = EntryHeadScanCameraModel()
    @State private var hasStartedScan = false
    @State private var scanSweep = false

    var body: some View {
        EntryOnboardingPageContainer(
            title: hasStartedScan ? "Scan your head" : "Optional head scan",
            subtitle: hasStartedScan
                ? "Use the front camera and slowly turn left, then right. AIScend uses Apple on-device face detection for this calibration."
                : "You can scan now using the front camera, or skip this and build your plan without a head scan."
        ) {
            VStack(spacing: 20) {
                if hasStartedScan {
                    scanExperience
                } else {
                    preflightChoice
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.46, dampingFraction: 0.86), value: hasStartedScan)
            .onDisappear {
                scanner.stop()
            }
        }
    }

    private var preflightChoice: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                EntryOnboardingStyle.panelStrong,
                                EntryOnboardingStyle.purple.opacity(0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 18) {
                    Image(systemName: "faceid")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(EntryOnboardingStyle.purpleSoft)
                        .frame(width: 112, height: 112)
                        .background(Circle().fill(EntryOnboardingStyle.purple.opacity(0.16)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))

                    VStack(spacing: 10) {
                        Text("Apple face detection")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("The camera opens only if you start the scan. Face guidance runs on device for this onboarding step.")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(EntryOnboardingStyle.mutedText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(24)
            }
            .frame(height: 310)
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            VStack(spacing: 12) {
                Button {
                    EntryOnboardingHaptics.advance()
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        hasStartedScan = true
                    }
                    scanner.start()
                    startSweep()
                } label: {
                    EntryOnboardingPrimaryButtonLabel(
                        title: "Start head scan",
                        isActive: true,
                        progress: 0.92
                    )
                }
                .buttonStyle(EntryOnboardingTactileButtonStyle())

                Button {
                    EntryOnboardingHaptics.tap()
                    onSkip()
                } label: {
                    Text("Skip head scan")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.08)))
                        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(EntryOnboardingTactileButtonStyle())
            }
        }
    }

    private var scanExperience: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.black.opacity(0.62))

                if scanner.status == .scanning || scanner.status == .complete {
                    EntryHeadScanCameraPreview(session: scanner.session)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .overlay(cameraOverlay)
                } else {
                    scanPlaceholder
                }
            }
            .frame(height: 420)
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(scanner.faceIsVisible ? EntryOnboardingStyle.purpleSoft.opacity(0.7) : Color.white.opacity(0.10), lineWidth: 1)
            )

            VStack(spacing: 12) {
                EntryScanCueRow(
                    symbol: scanner.faceIsVisible ? "face.smiling.fill" : "camera.viewfinder",
                    title: scanner.guidanceText
                )

                HStack(spacing: 10) {
                    scanMarker(title: "Left", isActive: scanner.leftSideCaptured)
                    scanMarker(title: "Face", isActive: scanner.faceIsVisible)
                    scanMarker(title: "Right", isActive: scanner.rightSideCaptured)
                }
            }

            if scanner.status == .complete {
                Button {
                    EntryOnboardingHaptics.success()
                    onComplete()
                } label: {
                    EntryOnboardingPrimaryButtonLabel(
                        title: "Build my routine",
                        isActive: true,
                        progress: 0.96
                    )
                }
                .buttonStyle(EntryOnboardingTactileButtonStyle())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button {
                    EntryOnboardingHaptics.tap()
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.07)))
                }
                .buttonStyle(EntryOnboardingTactileButtonStyle())
            }
        }
        .onChange(of: scanner.status) { _, status in
            if status == .complete {
                EntryOnboardingHaptics.success()
            }
        }
    }

    private var cameraOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(EntryOnboardingStyle.purpleSoft.opacity(scanner.faceIsVisible ? 0.95 : 0.34), lineWidth: 3)
                .frame(width: 214, height: 282)
                .shadow(color: EntryOnboardingStyle.purple.opacity(scanner.faceIsVisible ? 0.34 : 0), radius: 18)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            EntryOnboardingStyle.purpleSoft.opacity(0.82),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 238, height: 4)
                .offset(y: scanSweep ? 128 : -128)
                .opacity(scanner.status == .complete ? 0.15 : 0.95)

            VStack {
                HStack {
                    Image(systemName: "faceid")
                        .font(.system(size: 20, weight: .bold))
                    Text(scanner.progressLabel)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(14)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.34))
                        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
                )
                .padding(16)

                Spacer()
            }
        }
    }

    private var scanPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: scanner.status == .denied ? "camera.fill.badge.ellipsis" : "camera.viewfinder")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(EntryOnboardingStyle.purpleSoft)

            Text(scanner.guidanceText)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 20)

            if scanner.status == .denied || scanner.status == .unavailable {
                Button {
                    EntryOnboardingHaptics.tap()
                    onSkip()
                } label: {
                    Text("Skip head scan")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .background(Capsule(style: .continuous).fill(EntryOnboardingStyle.purple.opacity(0.26)))
                }
                .buttonStyle(EntryOnboardingTactileButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scanMarker(title: String, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .bold))

            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
        }
        .foregroundStyle(isActive ? .black : .white.opacity(0.72))
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(
            Capsule(style: .continuous)
                .fill(isActive ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.09))
        )
        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
        .animation(.smooth(duration: 0.22), value: isActive)
    }

    private func startSweep() {
        scanSweep = false
        withAnimation(.linear(duration: 1.75).repeatForever(autoreverses: true)) {
            scanSweep = true
        }
    }
}

private enum EntryHeadScanStatus: Equatable {
    case idle
    case requestingAccess
    case scanning
    case complete
    case denied
    case unavailable
}

private final class EntryHeadScanCameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var status: EntryHeadScanStatus = .idle
    @Published var faceIsVisible = false
    @Published var leftSideCaptured = false
    @Published var rightSideCaptured = false

    private let sessionQueue = DispatchQueue(label: "uk.co.aiscend.onboarding.head-scan.session")
    private let visionQueue = DispatchQueue(label: "uk.co.aiscend.onboarding.head-scan.vision")
    private var didConfigureSession = false
    private var lastObservationTime = Date.distantPast

    var guidanceText: String {
        switch status {
        case .idle:
            return "Ready when you are."
        case .requestingAccess:
            return "Waiting for camera permission..."
        case .denied:
            return "Camera access is off. You can enable it in Settings or skip this scan."
        case .unavailable:
            return "No front camera is available here. You can skip and keep going."
        case .complete:
            return "Head scan complete."
        case .scanning:
            if !faceIsVisible {
                return "Place your face inside the frame."
            }

            if !leftSideCaptured {
                return "Slowly turn your head left."
            }

            if !rightSideCaptured {
                return "Now slowly turn your head right."
            }

            return "Finishing scan..."
        }
    }

    var progressLabel: String {
        let completed = [faceIsVisible, leftSideCaptured, rightSideCaptured].filter { $0 }.count
        return "\(completed)/3"
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            status = .requestingAccess
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    granted ? self.startSession() : self.markDenied()
                }
            }
        case .denied, .restricted:
            markDenied()
        @unknown default:
            markDenied()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else {
                return
            }

            self.session.stopRunning()
        }
    }

    private func startSession() {
        status = .scanning

        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }

            guard self.configureSessionIfNeeded() else {
                DispatchQueue.main.async {
                    self.status = .unavailable
                }
                return
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    private func configureSessionIfNeeded() -> Bool {
        guard !didConfigureSession else {
            return true
        }

        session.beginConfiguration()
        session.sessionPreset = .high
        defer {
            session.commitConfiguration()
        }

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else {
            return false
        }

        session.addInput(input)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)

        guard session.canAddOutput(videoOutput) else {
            return false
        }

        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        didConfigureSession = true
        return true
    }

    private func markDenied() {
        status = .denied
    }

    private func handle(observation: VNFaceObservation?) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.status == .scanning else {
                return
            }

            guard let observation else {
                self.faceIsVisible = false
                return
            }

            if !self.faceIsVisible {
                EntryOnboardingHaptics.selection()
            }

            self.faceIsVisible = true
            let yaw = observation.yaw?.doubleValue ?? 0

            if yaw < -0.18, !self.leftSideCaptured {
                self.leftSideCaptured = true
                EntryOnboardingHaptics.advance()
            }

            if yaw > 0.18, !self.rightSideCaptured {
                self.rightSideCaptured = true
                EntryOnboardingHaptics.advance()
            }

            if self.leftSideCaptured && self.rightSideCaptured {
                self.status = .complete
                self.stop()
            }
        }
    }
}

extension EntryHeadScanCameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard Date().timeIntervalSince(lastObservationTime) > 0.14 else {
            return
        }

        lastObservationTime = Date()
        let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            let face = (request.results as? [VNFaceObservation])?.first
            self?.handle(observation: face)
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            handle(observation: nil)
            return
        }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        try? handler.perform([request])
    }
}

private struct EntryHeadScanCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

private struct EntryScanCueRow: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(EntryOnboardingStyle.purpleSoft)
                .frame(width: 38, height: 38)
                .background(Circle().fill(EntryOnboardingStyle.purple.opacity(0.13)))

            Text(title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(EntryOnboardingStyle.panelStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    EntryFaceScanOnboardingPage(onSkip: {}, onComplete: {})
        .background(Color.black)
}
