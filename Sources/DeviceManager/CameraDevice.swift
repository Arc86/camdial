//
//  CameraDevice.swift
//  WebcamSettings
//
//  Unified camera device abstraction wrapping UVC hardware and AVFoundation
//

import Foundation
import AVFoundation

public final class CameraDevice: Identifiable, ObservableObject {
    public let id: String
    public let name: String
    public let isExternal: Bool
    public let uvcDevice: UVCDevice?
    public let avDevice: AVCaptureDevice?

    public var isUVCControllable: Bool {
        return uvcDevice != nil
    }

    public init(uvcDevice: UVCDevice, avDevice: AVCaptureDevice? = nil) {
        self.uvcDevice = uvcDevice
        self.avDevice = avDevice
        self.id = "uvc_\(uvcDevice.vendorID)_\(uvcDevice.productID)_\(uvcDevice.locationID)"
        self.name = uvcDevice.name
        self.isExternal = true
    }

    public init(avDevice: AVCaptureDevice) {
        self.uvcDevice = nil
        self.avDevice = avDevice
        self.id = avDevice.uniqueID
        self.name = avDevice.localizedName
        self.isExternal = avDevice.deviceType == .external
    }

    public func resetToDefaults() {
        if let uvc = uvcDevice {
            uvc.resetAllToDefaults()
        }
    }

    public func applyPreset(_ preset: CameraPreset) {
        if let uvc = uvcDevice {
            if preset.isBuiltIn && preset.name == "Factory Default" {
                uvc.resetAllToDefaults()
                return
            }

            var dict: [String: Any] = [:]
            for (k, v) in preset.values {
                dict[k] = v
            }
            for (k, v) in preset.booleans {
                dict[k] = v
            }
            uvc.applySettings(dict)
        }
    }
}
