//
//  UVCDevice.swift
//  WebcamSettings
//
//  High-level UVC hardware device representing all camera registers
//

import Foundation
import IOKit
import IOKit.usb

public final class UVCDevice {
    public let name: String
    public let vendorID: Int
    public let productID: Int
    public let locationID: UInt32
    public let descriptorInfo: UVCDescriptorInfo
    private let plugin: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>>?
    private let interface: USBInterfacePointer

    // Picture Controls (Processing Unit)
    public let brightness: UVCIntControl
    public let contrast: UVCIntControl
    public let saturation: UVCIntControl
    public let sharpness: UVCIntControl
    public let whiteBalance: UVCIntControl
    public let whiteBalanceAuto: UVCBoolControl
    public let hue: UVCIntControl
    public let gamma: UVCIntControl
    public let backlightCompensation: UVCIntControl
    public let powerLineFrequency: UVCIntControl

    // Lighting & Exposure Controls (Camera Terminal & Processing Unit)
    public let autoExposure: UVCExposureModeControl
    public let exposureTime: UVCIntControl
    public let gain: UVCIntControl

    // Optics & Focus (Camera Terminal)
    public let autoFocus: UVCBoolControl
    public let focus: UVCIntControl
    public let zoom: UVCIntControl

    public init(name: String,
                vendorID: Int,
                productID: Int,
                locationID: UInt32,
                interface: USBInterfacePointer,
                plugin: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>>? = nil,
                descriptorInfo: UVCDescriptorInfo) {
        self.name = name
        self.vendorID = vendorID
        self.productID = productID
        self.locationID = locationID
        self.interface = interface
        self.plugin = plugin
        self.descriptorInfo = descriptorInfo

        let puID = descriptorInfo.processingUnitID
        let ctID = descriptorInfo.cameraTerminalID
        let ifID = descriptorInfo.interfaceID

        // Processing Unit controls
        self.brightness = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.brightness,
            unit: puID, interfaceNumber: ifID,
            isSigned: true
        )
        self.contrast = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.contrast,
            unit: puID, interfaceNumber: ifID
        )
        self.saturation = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.saturation,
            unit: puID, interfaceNumber: ifID
        )
        self.sharpness = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.sharpness,
            unit: puID, interfaceNumber: ifID
        )
        self.whiteBalance = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.whiteBalanceTemperature,
            unit: puID, interfaceNumber: ifID
        )
        self.whiteBalanceAuto = UVCBoolControl(
            interface: interface, size: 1,
            selector: UVCProcessingUnitControl.whiteBalanceTemperatureAuto,
            unit: puID, interfaceNumber: ifID
        )
        self.hue = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.hue,
            unit: puID, interfaceNumber: ifID,
            isSigned: true
        )
        self.gamma = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.gamma,
            unit: puID, interfaceNumber: ifID
        )
        self.backlightCompensation = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.backlightCompensation,
            unit: puID, interfaceNumber: ifID
        )
        self.powerLineFrequency = UVCIntControl(
            interface: interface, size: 1,
            selector: UVCProcessingUnitControl.powerLineFrequency,
            unit: puID, interfaceNumber: ifID
        )
        self.gain = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCProcessingUnitControl.gain,
            unit: puID, interfaceNumber: ifID
        )

        // Camera Terminal controls
        self.autoExposure = UVCExposureModeControl(
            interface: interface, size: 1,
            selector: UVCCameraTerminalControl.autoExposureMode,
            unit: ctID, interfaceNumber: ifID
        )
        self.exposureTime = UVCIntControl(
            interface: interface, size: 4,
            selector: UVCCameraTerminalControl.exposureTimeAbsolute,
            unit: ctID, interfaceNumber: ifID
        )
        self.autoFocus = UVCBoolControl(
            interface: interface, size: 1,
            selector: UVCCameraTerminalControl.focusAuto,
            unit: ctID, interfaceNumber: ifID
        )
        self.focus = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCCameraTerminalControl.focusAbsolute,
            unit: ctID, interfaceNumber: ifID
        )
        self.zoom = UVCIntControl(
            interface: interface, size: 2,
            selector: UVCCameraTerminalControl.zoomAbsolute,
            unit: ctID, interfaceNumber: ifID
        )
    }

    deinit {
        _ = interface.pointee.pointee.Release(interface)
        if let plugin = plugin {
            _ = plugin.pointee.pointee.Release(plugin)
        }
    }

    public func setManualWhiteBalance(kelvin: Int) {
        if whiteBalanceAuto.isCapable && whiteBalanceAuto.isEnabled {
            whiteBalanceAuto.isEnabled = false
        }
        if whiteBalance.isCapable {
            whiteBalance.current = kelvin
        }
    }

    public func setManualExposure(time: Int) {
        if autoExposure.isCapable && autoExposure.isAuto {
            autoExposure.isAuto = false
        }
        if exposureTime.isCapable {
            exposureTime.current = time
        }
    }

    public func setManualGain(value: Int) {
        if autoExposure.isCapable && autoExposure.isAuto {
            autoExposure.isAuto = false
        }
        if gain.isCapable {
            gain.current = value
        }
    }

    public func setManualFocus(distance: Int) {
        if autoFocus.isCapable && autoFocus.isEnabled {
            autoFocus.isEnabled = false
        }
        if focus.isCapable {
            focus.current = distance
        }
    }

    public func refreshAll() {
        brightness.refresh()
        contrast.refresh()
        saturation.refresh()
        sharpness.refresh()
        whiteBalance.refresh()
        whiteBalanceAuto.refresh()
        hue.refresh()
        gamma.refresh()
        backlightCompensation.refresh()
        powerLineFrequency.refresh()
        gain.refresh()
        autoExposure.refresh()
        exposureTime.refresh()
        autoFocus.refresh()
        focus.refresh()
        zoom.refresh()
    }

    public func resetAllToDefaults() {
        if brightness.isCapable { brightness.resetToDefault() }
        if contrast.isCapable { contrast.resetToDefault() }
        if saturation.isCapable { saturation.resetToDefault() }
        if sharpness.isCapable { sharpness.resetToDefault() }
        if whiteBalanceAuto.isCapable { whiteBalanceAuto.resetToDefault() }
        if whiteBalance.isCapable { whiteBalance.resetToDefault() }
        if hue.isCapable { hue.resetToDefault() }
        if gamma.isCapable { gamma.resetToDefault() }
        if backlightCompensation.isCapable { backlightCompensation.resetToDefault() }
        if powerLineFrequency.isCapable { powerLineFrequency.resetToDefault() }
        if autoExposure.isCapable { autoExposure.resetToDefault() }
        if exposureTime.isCapable { exposureTime.resetToDefault() }
        if gain.isCapable { gain.resetToDefault() }
        if autoFocus.isCapable { autoFocus.resetToDefault() }
        if focus.isCapable { focus.resetToDefault() }
        if zoom.isCapable { zoom.resetToDefault() }
    }

    public func dumpSettings() -> [String: Any] {
        var dict: [String: Any] = [:]
        if brightness.isCapable { dict["brightness"] = brightness.current }
        if contrast.isCapable { dict["contrast"] = contrast.current }
        if saturation.isCapable { dict["saturation"] = saturation.current }
        if sharpness.isCapable { dict["sharpness"] = sharpness.current }
        if whiteBalanceAuto.isCapable { dict["whiteBalanceAuto"] = whiteBalanceAuto.isEnabled }
        if whiteBalance.isCapable { dict["whiteBalance"] = whiteBalance.current }
        if hue.isCapable { dict["hue"] = hue.current }
        if gamma.isCapable { dict["gamma"] = gamma.current }
        if backlightCompensation.isCapable { dict["backlight"] = backlightCompensation.current }
        if powerLineFrequency.isCapable { dict["powerLineFrequency"] = powerLineFrequency.current }
        if autoExposure.isCapable { dict["autoExposure"] = autoExposure.isAuto }
        if exposureTime.isCapable { dict["exposureTime"] = exposureTime.current }
        if gain.isCapable { dict["gain"] = gain.current }
        if autoFocus.isCapable { dict["autoFocus"] = autoFocus.isEnabled }
        if focus.isCapable { dict["focus"] = focus.current }
        if zoom.isCapable { dict["zoom"] = zoom.current }
        return dict
    }

    private func mapValue(_ val: Int, to control: UVCIntControl) -> Int {
        guard control.isCapable, control.maximum > control.minimum else { return val }
        if val >= control.minimum && val <= control.maximum {
            return val
        }
        let normalized = max(0.0, min(1.0, Double(val) / 255.0))
        let scaled = Double(control.minimum) + normalized * Double(control.maximum - control.minimum)
        return Int(scaled)
    }

    public func applySettings(_ dict: [String: Any]) {
        // 1. Picture adjustments
        if let val = dict["brightness"] as? Int, brightness.isCapable { brightness.current = mapValue(val, to: brightness) }
        if let val = dict["contrast"] as? Int, contrast.isCapable { contrast.current = mapValue(val, to: contrast) }
        if let val = dict["saturation"] as? Int, saturation.isCapable { saturation.current = mapValue(val, to: saturation) }
        if let val = dict["sharpness"] as? Int, sharpness.isCapable { sharpness.current = mapValue(val, to: sharpness) }
        if let val = dict["hue"] as? Int, hue.isCapable { hue.current = mapValue(val, to: hue) }
        if let val = dict["gamma"] as? Int, gamma.isCapable { gamma.current = mapValue(val, to: gamma) }
        if let val = dict["backlight"] as? Int, backlightCompensation.isCapable { backlightCompensation.current = val }
        if let val = dict["powerLineFrequency"] as? Int, powerLineFrequency.isCapable { powerLineFrequency.current = val }

        // 2. White Balance
        if let autoWB = dict["whiteBalanceAuto"] as? Bool, whiteBalanceAuto.isCapable {
            whiteBalanceAuto.isEnabled = autoWB
            if !autoWB, let wbVal = dict["whiteBalance"] as? Int, whiteBalance.isCapable {
                whiteBalance.current = wbVal
            }
        } else if let wbVal = dict["whiteBalance"] as? Int, whiteBalance.isCapable {
            setManualWhiteBalance(kelvin: wbVal)
        }

        // 3. Exposure & Gain
        if let autoExp = dict["autoExposure"] as? Bool, autoExposure.isCapable {
            autoExposure.isAuto = autoExp
            if !autoExp {
                if let expVal = dict["exposureTime"] as? Int, exposureTime.isCapable {
                    exposureTime.current = expVal
                }
                if let gainVal = dict["gain"] as? Int, gain.isCapable {
                    gain.current = gainVal
                }
            }
        } else {
            if let expVal = dict["exposureTime"] as? Int, exposureTime.isCapable {
                setManualExposure(time: expVal)
            }
            if let gainVal = dict["gain"] as? Int, gain.isCapable {
                setManualGain(value: gainVal)
            }
        }

        // 4. Focus & Zoom
        if let autoFoc = dict["autoFocus"] as? Bool, autoFocus.isCapable {
            autoFocus.isEnabled = autoFoc
            if !autoFoc, let focVal = dict["focus"] as? Int, focus.isCapable {
                focus.current = focVal
            }
        } else if let focVal = dict["focus"] as? Int, focus.isCapable {
            setManualFocus(distance: focVal)
        }

        if let val = dict["zoom"] as? Int, zoom.isCapable { zoom.current = val }
    }
}
