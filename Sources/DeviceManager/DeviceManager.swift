//
//  DeviceManager.swift
//  WebcamSettings
//
//  Monitors connected webcams, handles hotplugging and camera selection
//

import Foundation
import AVFoundation

public final class DeviceManager: ObservableObject {
    public static let shared = DeviceManager()

    @Published public var devices: [CameraDevice] = []
    @Published public var selectedDevice: CameraDevice?

    private var notificationObservers: [Any] = []

    public init() {
        refreshDevices()
        setupNotifications()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private var isRefreshing = false
    private var refreshWorkItem: DispatchWorkItem?

    public func refreshDevices() {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        // 1. Discover UVC cameras via IOKit
        let uvcCameras = UVCDiscovery.discoverDevices()

        // 2. Discover AVFoundation video devices
        var deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        if #available(macOS 14.0, *) {
            deviceTypes.append(.external)
            deviceTypes.append(.continuityCamera)
        } else {
            deviceTypes.append(.externalUnknown)
        }

        let avDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        let avDevices = avDiscovery.devices

        var unifiedList: [CameraDevice] = []

        // Pair UVC devices with AVFoundation devices when possible
        for uvc in uvcCameras {
            let matchedAV = avDevices.first { av in
                // Match by modelID containing VID/PID
                if av.modelID.contains("\(uvc.vendorID)") && av.modelID.contains("\(uvc.productID)") {
                    return true
                }
                // Match by locationID hex in uniqueID
                let locHex = String(uvc.locationID, radix: 16)
                if av.uniqueID.lowercased().contains(locHex.lowercased()) {
                    return true
                }
                // Match by name
                if av.localizedName.lowercased() == uvc.name.lowercased() {
                    return true
                }
                return false
            }

            let camDevice = CameraDevice(uvcDevice: uvc, avDevice: matchedAV)
            unifiedList.append(camDevice)

            // Auto-restore last known settings
            if let saved = PresetManager.shared.loadDeviceLastState(deviceID: camDevice.id) {
                uvc.applySettings(saved)
            }
        }

        // Add remaining AVFoundation devices (built-in, continuity, or virtual) not already mapped
        for av in avDevices {
            let alreadyMapped = unifiedList.contains { $0.avDevice?.uniqueID == av.uniqueID }
            if !alreadyMapped {
                unifiedList.append(CameraDevice(avDevice: av))
            }
        }

        DispatchQueue.main.async {
            self.devices = unifiedList

            // Select previous device if still available, or default to first external webcam, or first device
            if let current = self.selectedDevice, unifiedList.contains(where: { $0.id == current.id }) {
                self.selectedDevice = unifiedList.first(where: { $0.id == current.id })
            } else {
                self.selectedDevice = unifiedList.first(where: { $0.isExternal }) ?? unifiedList.first
            }
        }
    }

    private func setupNotifications() {
        let scheduleDebouncedRefresh = { [weak self] in
            self?.refreshWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.refreshDevices()
            }
            self?.refreshWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: item)
        }

        let connectObs = NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.wasConnectedNotification,
            object: nil,
            queue: .main
        ) { _ in
            scheduleDebouncedRefresh()
        }

        let disconnectObs = NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification,
            object: nil,
            queue: .main
        ) { _ in
            scheduleDebouncedRefresh()
        }

        notificationObservers = [connectObs, disconnectObs]
    }

    public func selectDevice(id: String) {
        if let dev = devices.first(where: { $0.id == id }) {
            selectedDevice = dev
        }
    }

    public func saveCurrentDeviceState() {
        guard let dev = selectedDevice, let uvc = dev.uvcDevice else { return }
        let state = uvc.dumpSettings()
        PresetManager.shared.saveDeviceLastState(deviceID: dev.id, settings: state)
    }
}
