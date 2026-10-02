//
//  CameraViewModel.swift
//  WebcamSettings
//
//  Reactive view model bridging camera hardware state and SwiftUI controls
//

import SwiftUI
import Combine

public final class CameraViewModel: ObservableObject {
    public static let shared = CameraViewModel()

    @Published public var activeDevice: CameraDevice?

    // Picture Properties
    @Published public var brightness: Double = 128
    @Published public var contrast: Double = 128
    @Published public var saturation: Double = 128
    @Published public var sharpness: Double = 128
    @Published public var whiteBalance: Double = 4500
    @Published public var whiteBalanceAuto: Bool = true
    @Published public var hue: Double = 0
    @Published public var gamma: Double = 100
    @Published public var backlight: Double = 0
    @Published public var powerLineFreq: Int = 1

    // Lighting & Exposure Properties
    @Published public var autoExposure: Bool = true
    @Published public var exposureTime: Double = 156
    @Published public var gain: Double = 32

    // Focus & Zoom Properties
    @Published public var autoFocus: Bool = true
    @Published public var focus: Double = 50
    @Published public var zoom: Double = 100

    private var cancellables = Set<AnyCancellable>()
    private var autoPollingTimer: AnyCancellable?
    public var isUserDragging: Bool = false

    private init() {
        DeviceManager.shared.$selectedDevice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dev in
                self?.attachDevice(dev)
            }
            .store(in: &cancellables)

        startAutoPolling()
    }

    private func startAutoPolling() {
        autoPollingTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pollAutoValues()
            }
    }

    public func pollAutoValues() {
        guard let uvc = activeDevice?.uvcDevice, !isUserDragging else { return }

        // Live track auto White Balance Kelvin value
        if whiteBalanceAuto && uvc.whiteBalance.isCapable {
            uvc.whiteBalance.refresh()
            let liveWB = Double(uvc.whiteBalance.current)
            if abs(liveWB - whiteBalance) >= 5 {
                whiteBalance = liveWB
            }
        }

        // Live track auto Exposure (shutter time & sensor gain)
        if autoExposure {
            if uvc.exposureTime.isCapable {
                uvc.exposureTime.refresh()
                let liveExp = Double(uvc.exposureTime.current)
                if abs(liveExp - exposureTime) >= 1 {
                    exposureTime = liveExp
                }
            }
            if uvc.gain.isCapable {
                uvc.gain.refresh()
                let liveGain = Double(uvc.gain.current)
                if abs(liveGain - gain) >= 1 {
                    gain = liveGain
                }
            }
        }

        // Live track auto Focus distance
        if autoFocus && uvc.focus.isCapable {
            uvc.focus.refresh()
            let liveFocus = Double(uvc.focus.current)
            if abs(liveFocus - focus) >= 1 {
                focus = liveFocus
            }
        }
    }

    public func attachDevice(_ device: CameraDevice?) {
        self.activeDevice = device
        syncFromDevice()
    }

    public func syncFromDevice() {
        guard let uvc = activeDevice?.uvcDevice else { return }
        uvc.refreshAll()

        brightness = Double(uvc.brightness.current)
        contrast = Double(uvc.contrast.current)
        saturation = Double(uvc.saturation.current)
        sharpness = Double(uvc.sharpness.current)
        whiteBalance = Double(uvc.whiteBalance.current)
        whiteBalanceAuto = uvc.whiteBalanceAuto.isEnabled
        hue = Double(uvc.hue.current)
        gamma = Double(uvc.gamma.current)
        backlight = Double(uvc.backlightCompensation.current)
        powerLineFreq = uvc.powerLineFrequency.current

        autoExposure = uvc.autoExposure.isAuto
        exposureTime = Double(uvc.exposureTime.current)
        gain = Double(uvc.gain.current)

        autoFocus = uvc.autoFocus.isEnabled
        focus = Double(uvc.focus.current)
        zoom = Double(uvc.zoom.current)
    }

    // MARK: - Actions

    public func setBrightness(_ val: Double) {
        brightness = val
        guard let uvc = activeDevice?.uvcDevice, uvc.brightness.isCapable else { return }
        uvc.brightness.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setContrast(_ val: Double) {
        contrast = val
        guard let uvc = activeDevice?.uvcDevice, uvc.contrast.isCapable else { return }
        uvc.contrast.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setSaturation(_ val: Double) {
        saturation = val
        guard let uvc = activeDevice?.uvcDevice, uvc.saturation.isCapable else { return }
        uvc.saturation.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setSharpness(_ val: Double) {
        sharpness = val
        guard let uvc = activeDevice?.uvcDevice, uvc.sharpness.isCapable else { return }
        uvc.sharpness.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setWhiteBalance(_ val: Double) {
        whiteBalance = val
        guard let uvc = activeDevice?.uvcDevice, uvc.whiteBalance.isCapable else { return }
        if whiteBalanceAuto {
            whiteBalanceAuto = false
            if uvc.whiteBalanceAuto.isCapable {
                uvc.whiteBalanceAuto.isEnabled = false
            }
        }
        uvc.whiteBalance.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setWhiteBalanceAuto(_ isAuto: Bool) {
        whiteBalanceAuto = isAuto
        guard let uvc = activeDevice?.uvcDevice, uvc.whiteBalanceAuto.isCapable else { return }
        uvc.whiteBalanceAuto.isEnabled = isAuto
        if isAuto {
            uvc.whiteBalance.refresh()
            whiteBalance = Double(uvc.whiteBalance.current)
        } else if uvc.whiteBalance.isCapable {
            uvc.whiteBalance.current = Int(whiteBalance)
        }
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setHue(_ val: Double) {
        hue = val
        guard let uvc = activeDevice?.uvcDevice, uvc.hue.isCapable else { return }
        uvc.hue.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setGamma(_ val: Double) {
        gamma = val
        guard let uvc = activeDevice?.uvcDevice, uvc.gamma.isCapable else { return }
        uvc.gamma.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setBacklight(_ val: Double) {
        backlight = val
        guard let uvc = activeDevice?.uvcDevice, uvc.backlightCompensation.isCapable else { return }
        uvc.backlightCompensation.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setPowerLineFrequency(_ freq: Int) {
        powerLineFreq = freq
        guard let uvc = activeDevice?.uvcDevice, uvc.powerLineFrequency.isCapable else { return }
        uvc.powerLineFrequency.current = freq
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setAutoExposure(_ isAuto: Bool) {
        autoExposure = isAuto
        guard let uvc = activeDevice?.uvcDevice, uvc.autoExposure.isCapable else { return }
        uvc.autoExposure.isAuto = isAuto
        if isAuto {
            uvc.exposureTime.refresh()
            uvc.gain.refresh()
            exposureTime = Double(uvc.exposureTime.current)
            gain = Double(uvc.gain.current)
        } else {
            if uvc.exposureTime.isCapable { uvc.exposureTime.current = Int(exposureTime) }
            if uvc.gain.isCapable { uvc.gain.current = Int(gain) }
        }
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setExposureTime(_ val: Double) {
        exposureTime = val
        guard let uvc = activeDevice?.uvcDevice, uvc.exposureTime.isCapable else { return }
        if autoExposure {
            autoExposure = false
            if uvc.autoExposure.isCapable {
                uvc.autoExposure.isAuto = false
            }
        }
        uvc.exposureTime.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setGain(_ val: Double) {
        gain = val
        guard let uvc = activeDevice?.uvcDevice, uvc.gain.isCapable else { return }
        if autoExposure {
            autoExposure = false
            if uvc.autoExposure.isCapable {
                uvc.autoExposure.isAuto = false
            }
        }
        uvc.gain.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setAutoFocus(_ isAuto: Bool) {
        autoFocus = isAuto
        guard let uvc = activeDevice?.uvcDevice, uvc.autoFocus.isCapable else { return }
        uvc.autoFocus.isEnabled = isAuto
        if isAuto {
            uvc.focus.refresh()
            focus = Double(uvc.focus.current)
        } else if uvc.focus.isCapable {
            uvc.focus.current = Int(focus)
        }
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setFocus(_ val: Double) {
        focus = val
        guard let uvc = activeDevice?.uvcDevice, uvc.focus.isCapable else { return }
        if autoFocus {
            autoFocus = false
            if uvc.autoFocus.isCapable {
                uvc.autoFocus.isEnabled = false
            }
        }
        uvc.focus.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func setZoom(_ val: Double) {
        zoom = val
        guard let uvc = activeDevice?.uvcDevice, uvc.zoom.isCapable else { return }
        uvc.zoom.current = Int(val)
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func applyPreset(_ preset: CameraPreset) {
        guard let dev = activeDevice else { return }
        dev.applyPreset(preset)
        syncFromDevice()
        DeviceManager.shared.saveCurrentDeviceState()
    }

    public func resetToDefaults() {
        guard let dev = activeDevice else { return }
        dev.resetToDefaults()
        syncFromDevice()
        DeviceManager.shared.saveCurrentDeviceState()
    }
}
