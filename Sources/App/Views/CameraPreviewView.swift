//
//  CameraPreviewView.swift
//  WebcamSettings
//
//  Live video preview component using AVCaptureVideoPreviewLayer
//

import SwiftUI
import AVFoundation

public struct CameraPreviewView: NSViewRepresentable {
    public let captureDevice: AVCaptureDevice?
    public let isRunning: Bool
    /// Called with width / height once the session is running, since the session
    /// preset may switch the device to a different format than it had before.
    public var onAspectRatioChange: ((CGFloat) -> Void)?

    public init(captureDevice: AVCaptureDevice?, isRunning: Bool, onAspectRatioChange: ((CGFloat) -> Void)? = nil) {
        self.captureDevice = captureDevice
        self.isRunning = isRunning
        self.onAspectRatioChange = onAspectRatioChange
    }

    public func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.onAspectRatioChange = onAspectRatioChange
        view.updateSession(device: captureDevice, running: isRunning)
        return view
    }

    public func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.onAspectRatioChange = onAspectRatioChange
        nsView.updateSession(device: captureDevice, running: isRunning)
    }
}

public final class CameraPreviewNSView: NSView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDeviceID: String?
    var onAspectRatioChange: ((CGFloat) -> Void)?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    public override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }

    public func updateSession(device: AVCaptureDevice?, running: Bool) {
        guard running, let device = device else {
            stopSession()
            return
        }

        if captureSession != nil && currentDeviceID == device.uniqueID {
            if captureSession?.isRunning == false {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.captureSession?.startRunning()
                }
            }
            return
        }

        stopSession()
        startSession(with: device)
    }

    private func startSession(with device: AVCaptureDevice) {
        currentDeviceID = device.uniqueID

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let session = AVCaptureSession()
            session.sessionPreset = .high

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }

                DispatchQueue.main.async {
                    let layer = AVCaptureVideoPreviewLayer(session: session)
                    // Fit rather than fill: if the frame and format ever disagree, letterbox instead of cropping
                    layer.videoGravity = .resizeAspect
                    layer.frame = self.bounds
                    self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
                    self.layer?.addSublayer(layer)
                    self.previewLayer = layer
                }

                session.startRunning()
                self.captureSession = session

                let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
                if dims.width > 0, dims.height > 0 {
                    let ratio = CGFloat(dims.width) / CGFloat(dims.height)
                    DispatchQueue.main.async { self.onAspectRatioChange?(ratio) }
                }
            } catch {
                // Device might be in exclusive use or restricted
            }
        }
    }

    private func stopSession() {
        if let session = captureSession {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
        captureSession = nil
        currentDeviceID = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }
}
