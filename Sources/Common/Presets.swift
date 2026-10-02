//
//  Presets.swift
//  WebcamSettings
//
//  Preset and profile management with built-in presets and persistent storage
//

import Foundation

public struct CameraPreset: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let isBuiltIn: Bool
    public var values: [String: Int]
    public var booleans: [String: Bool]

    public init(name: String, isBuiltIn: Bool = false, values: [String: Int], booleans: [String: Bool] = [:]) {
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.values = values
        self.booleans = booleans
    }
}

public final class PresetManager {
    public static let shared = PresetManager()

    private let userDefaultsKey = "com.willem.CamDial.savedPresets"
    private let autoRestorePrefix = "com.willem.CamDial.deviceState."

    public private(set) var presets: [CameraPreset] = []

    public static let builtInPresets: [CameraPreset] = [
        CameraPreset(
            name: "Factory Default",
            isBuiltIn: true,
            values: [:],
            booleans: ["whiteBalanceAuto": true, "autoExposure": true, "autoFocus": true]
        ),
        CameraPreset(
            name: "Side Light / Window Compensation",
            isBuiltIn: true,
            values: [
                "brightness": 160,
                "contrast": 105,
                "backlight": 2,
                "saturation": 125,
                "sharpness": 128,
                "whiteBalance": 5400
            ],
            booleans: ["whiteBalanceAuto": false, "autoExposure": true, "autoFocus": true]
        ),
        CameraPreset(
            name: "Natural Daylight",
            isBuiltIn: true,
            values: ["whiteBalance": 5500, "brightness": 138, "contrast": 135, "saturation": 145, "sharpness": 135],
            booleans: ["whiteBalanceAuto": false, "autoExposure": true, "autoFocus": true]
        ),
        CameraPreset(
            name: "Warm Studio",
            isBuiltIn: true,
            values: ["whiteBalance": 3400, "brightness": 140, "contrast": 130, "saturation": 140, "sharpness": 130],
            booleans: ["whiteBalanceAuto": false, "autoExposure": true, "autoFocus": true]
        ),
        CameraPreset(
            name: "Night / Low Light",
            isBuiltIn: true,
            values: ["brightness": 175, "contrast": 115, "saturation": 130, "sharpness": 110, "backlight": 2],
            booleans: ["whiteBalanceAuto": true, "autoExposure": true, "autoFocus": true]
        ),
        CameraPreset(
            name: "Vibrant & Crisp",
            isBuiltIn: true,
            values: ["whiteBalance": 5000, "brightness": 130, "contrast": 155, "saturation": 165, "sharpness": 160],
            booleans: ["whiteBalanceAuto": false, "autoExposure": true, "autoFocus": true]
        ),
        CameraPreset(
            name: "Black & White",
            isBuiltIn: true,
            values: ["saturation": 0, "contrast": 155, "brightness": 135, "sharpness": 145],
            booleans: ["whiteBalanceAuto": true, "autoExposure": true, "autoFocus": true]
        )
    ]

    private init() {
        loadPresets()
    }

    public func loadPresets() {
        presets = PresetManager.builtInPresets

        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([CameraPreset].self, from: data) {
            // Append custom user presets
            presets.append(contentsOf: saved.filter { !$0.isBuiltIn })
        }
    }

    public func saveCustomPreset(name: String, values: [String: Int], booleans: [String: Bool]) {
        // Remove existing custom preset with same name if any
        presets.removeAll { $0.name == name && !$0.isBuiltIn }
        let newPreset = CameraPreset(name: name, isBuiltIn: false, values: values, booleans: booleans)
        presets.append(newPreset)
        persistCustomPresets()
    }

    public func deletePreset(named name: String) {
        presets.removeAll { $0.name == name && !$0.isBuiltIn }
        persistCustomPresets()
    }

    private func persistCustomPresets() {
        let custom = presets.filter { !$0.isBuiltIn }
        if let data = try? JSONEncoder().encode(custom) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // Auto-restore last known device settings
    public func saveDeviceLastState(deviceID: String, settings: [String: Any]) {
        let key = autoRestorePrefix + deviceID
        UserDefaults.standard.set(settings, forKey: key)
    }

    public func loadDeviceLastState(deviceID: String) -> [String: Any]? {
        let key = autoRestorePrefix + deviceID
        return UserDefaults.standard.dictionary(forKey: key)
    }
}
