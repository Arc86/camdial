//
//  UVCConstants.swift
//  WebcamSettings
//
//  Standard USB Video Class (UVC 1.1 / 1.5) Protocol Definitions
//

import Foundation

public struct UVCConstants {
    public static let classVideo: UInt16 = 0x0E
    public static let subclassVideoControl: UInt16 = 0x01
    public static let descriptorTypeInterface: UInt8 = 0x24

    public enum DescriptorSubtype: UInt8 {
        case header = 0x01
        case inputTerminal = 0x02
        case outputTerminal = 0x03
        case selectorUnit = 0x04
        case processingUnit = 0x05
        case extensionUnit = 0x06
    }
}

public enum UVCRequestCode: UInt8 {
    case setCurrent = 0x01
    case getCurrent = 0x81
    case getMinimum = 0x82
    case getMaximum = 0x83
    case getResolution = 0x84
    case getLength = 0x85
    case getInfo = 0x86
    case getDefault = 0x87
}

public protocol UVCSelector {
    var rawSelector: Int { get }
}

public enum UVCProcessingUnitControl: Int, UVCSelector {
    case backlightCompensation = 0x01
    case brightness = 0x02
    case contrast = 0x03
    case gain = 0x04
    case powerLineFrequency = 0x05
    case hue = 0x06
    case saturation = 0x07
    case sharpness = 0x08
    case gamma = 0x09
    case whiteBalanceTemperature = 0x0A
    case whiteBalanceTemperatureAuto = 0x0B
    case whiteBalanceComponent = 0x0C
    case whiteBalanceComponentAuto = 0x0D
    case digitalMultiplier = 0x0E
    case digitalMultiplierLimit = 0x0F
    case hueAuto = 0x10
    case contrastAuto = 0x11

    public var rawSelector: Int { return self.rawValue }
}

public enum UVCCameraTerminalControl: Int, UVCSelector {
    case scanningMode = 0x01
    case autoExposureMode = 0x02
    case autoExposurePriority = 0x03
    case exposureTimeAbsolute = 0x04
    case exposureTimeRelative = 0x05
    case focusAbsolute = 0x06
    case focusRelative = 0x07
    case focusAuto = 0x08
    case irisAbsolute = 0x09
    case irisRelative = 0x0A
    case zoomAbsolute = 0x0B
    case zoomRelative = 0x0C
    case panTiltAbsolute = 0x0D
    case panTiltRelative = 0x0E
    case rollAbsolute = 0x0F
    case rollRelative = 0x10

    public var rawSelector: Int { return self.rawValue }
}

public enum PowerLineFrequencyMode: Int {
    case disabled = 0
    case hz50 = 1
    case hz60 = 2
    case auto = 3

    public var description: String {
        switch self {
        case .disabled: return "Disabled"
        case .hz50: return "50 Hz (Europe/Asia/Africa/AU)"
        case .hz60: return "60 Hz (Americas/Japan)"
        case .auto: return "Auto"
        }
    }
}

public enum AutoExposureMode: Int {
    case manual = 1
    case auto = 2
    case shutterPriority = 4
    case aperturePriority = 8

    public var isManual: Bool {
        return self == .manual
    }
}
