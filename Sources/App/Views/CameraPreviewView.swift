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

    public init(captureDevice: AVCaptureDevice?, isRunning: Bool) {
        self.captureDevice = captureDevice
        self.isRunning = isRunning
    }

    public func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.updateSession(device: captureDevice, running: isRunning)
        return view
    }

    public func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.updateSession(device: captureDevice, running: isRunning)
    }
}

public final class CameraPreviewNSView: NSView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDeviceID: String?

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
                    layer.videoGravity = .resizeAspectFill
                    layer.frame = self.bounds
                    self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
                    self.layer?.addSublayer(layer)
                    self.previewLayer = layer
                }

                session.startRunning()
                self.captureSession = session
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
