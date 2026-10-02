//
//  Models.swift
//  WebcamSettings
//
//  Shared data models for controls, ranges, and categories
//

import Foundation

public enum ControlCategory: String, CaseIterable, Identifiable {
    case picture = "Picture"
    case exposure = "Exposure"
    case optics = "Focus & Zoom"

    public var id: String { self.rawValue }

    public var iconName: String {
        switch self {
        case .picture: return "slider.horizontal.3"
        case .exposure: return "sun.max"
        case .optics: return "camera.aperture"
        }
    }
}

public struct CameraControlModel: Identifiable {
    public let id: String
    public let name: String
    public let category: ControlCategory
    public let minValue: Int
    public let maxValue: Int
    public let step: Int
    public let defaultValue: Int
    public var currentValue: Int
    public let unit: String
    public var isAutoCapable: Bool
    public var isAutoEnabled: Bool
    public var isAvailable: Bool

    public init(id: String,
                name: String,
                category: ControlCategory,
                minValue: Int,
                maxValue: Int,
                step: Int = 1,
                defaultValue: Int,
                currentValue: Int,
                unit: String = "",
                isAutoCapable: Bool = false,
                isAutoEnabled: Bool = false,
                isAvailable: Bool = true) {
        self.id = id
        self.name = name
        self.category = category
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = max(1, step)
        self.defaultValue = defaultValue
        self.currentValue = currentValue
        self.unit = unit
        self.isAutoCapable = isAutoCapable
        self.isAutoEnabled = isAutoEnabled
        self.isAvailable = isAvailable
    }
}
