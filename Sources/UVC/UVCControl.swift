//
//  UVCControl.swift
//  WebcamSettings
//
//  Low-level hardware control implementations for UVC registers
//

import Foundation
import IOKit
import IOKit.usb

public typealias USBInterfacePointer = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface190>>

public enum UVCError: Error {
    case invalidUnitId
    case requestError(kern_return_t)
    case notSupported
}

open class UVCControl {
    public let interface: USBInterfacePointer
    public let uvcSize: Int
    public let uvcSelector: Int
    public let uvcUnit: Int
    public let uvcInterface: Int
    open var isCapable: Bool = false

    public init(interface: USBInterfacePointer,
                size: Int,
                selector: UVCSelector,
                unit: Int,
                interfaceNumber: Int) {
        self.interface = interface
        self.uvcSize = size
        self.uvcSelector = selector.rawSelector
        self.uvcUnit = unit
        self.uvcInterface = interfaceNumber
    }

    public func getData(for type: UVCRequestCode, length: Int) -> Int? {
        let requestType = usbMakeRequestType(direction: kUSBIn, type: kUSBClass, recipient: kUSBInterface)
        do {
            return try performRequest(type: type, length: length, requestType: requestType)
        } catch {
            return nil
        }
    }

    public func setData(value: Int, length: Int) -> Bool {
        let requestType = usbMakeRequestType(direction: kUSBOut, type: kUSBClass, recipient: kUSBInterface)
        do {
            _ = try performRequest(type: .setCurrent, length: length, requestType: requestType, value: value)
            return true
        } catch {
            return false
        }
    }

    open func checkCapability() {
        guard uvcUnit > 0 else {
            isCapable = false
            return
        }
        // Inquire UVC GET_INFO (0x86)
        if let info = getData(for: .getInfo, length: 1), info > 0 {
            isCapable = true
        } else if getData(for: .getCurrent, length: uvcSize) != nil {
            isCapable = true
        } else {
            isCapable = false
        }
    }

    private func performRequest(type: UVCRequestCode,
                                length: Int,
                                requestType: UInt8,
                                value: Int = 0) throws -> Int {
        guard uvcUnit > 0 else {
            throw UVCError.invalidUnitId
        }

        var buffer: UInt32 = UInt32(truncatingIfNeeded: value)
        let kr: kern_return_t = withUnsafeMutablePointer(to: &buffer) { ptr in
            var request = IOUSBDevRequest(
                bmRequestType: requestType,
                bRequest: type.rawValue,
                wValue: UInt16(uvcSelector << 8),
                wIndex: UInt16(uvcUnit << 8) | UInt16(uvcInterface),
                wLength: UInt16(length),
                pData: UnsafeMutableRawPointer(ptr),
                wLenDone: 0
            )

            var res = interface.pointee.pointee.ControlRequest(interface, 0, &request)
            if res != kIOReturnSuccess {
                request.wIndex = UInt16(uvcUnit << 8)
                res = interface.pointee.pointee.ControlRequest(interface, 0, &request)
            }
            if res != kIOReturnSuccess {
                _ = interface.pointee.pointee.USBInterfaceOpen(interface)
                request.wIndex = UInt16(uvcUnit << 8) | UInt16(uvcInterface)
                res = interface.pointee.pointee.ControlRequest(interface, 0, &request)
            }
            return res
        }

        guard kr == kIOReturnSuccess else {
            throw UVCError.requestError(kr)
        }

        // Handle sign extension if length is less than 4 bytes
        if length == 1 {
            return Int(UInt8(truncatingIfNeeded: buffer))
        } else if length == 2 {
            return Int(UInt16(truncatingIfNeeded: buffer))
        } else {
            return Int(buffer)
        }
    }

    private func usbMakeRequestType(direction: Int, type: Int, recipient: Int) -> UInt8 {
        return UInt8((direction & kUSBRqDirnMask) << kUSBRqDirnShift) |
               UInt8((type & kUSBRqTypeMask) << kUSBRqTypeShift) |
               UInt8(recipient & kUSBRqRecipientMask)
    }
}

// MARK: - Integer Control (Sliders: Brightness, Contrast, Exposure, etc.)

public final class UVCIntControl: UVCControl {
    public private(set) var minimum: Int = 0
    public private(set) var maximum: Int = 100
    public private(set) var defaultValue: Int = 50
    public private(set) var resolution: Int = 1
    public var isSigned: Bool = false
    private var _current: Int = 50

    public var current: Int {
        get { return _current }
        set {
            let clamped = max(minimum, min(maximum, newValue))
            if setIntValue(clamped) {
                _current = clamped
            }
        }
    }

    public init(interface: USBInterfacePointer,
                size: Int,
                selector: UVCSelector,
                unit: Int,
                interfaceNumber: Int,
                isSigned: Bool = false) {
        self.isSigned = isSigned
        super.init(interface: interface, size: size, selector: selector, unit: unit, interfaceNumber: interfaceNumber)
        configure()
    }

    private func getIntValue(for type: UVCRequestCode) -> Int? {
        guard let raw = getData(for: type, length: uvcSize) else { return nil }
        if isSigned {
            if uvcSize == 1 {
                return Int(Int8(bitPattern: UInt8(truncatingIfNeeded: raw)))
            } else if uvcSize == 2 {
                return Int(Int16(bitPattern: UInt16(truncatingIfNeeded: raw)))
            }
        }
        return raw
    }

    private func setIntValue(_ val: Int) -> Bool {
        let wireVal: Int
        if isSigned {
            if uvcSize == 1 {
                wireVal = Int(UInt8(bitPattern: Int8(truncatingIfNeeded: val)))
            } else if uvcSize == 2 {
                wireVal = Int(UInt16(bitPattern: Int16(truncatingIfNeeded: val)))
            } else {
                wireVal = val
            }
        } else {
            wireVal = val
        }
        return setData(value: wireVal, length: uvcSize)
    }

    public func configure() {
        checkCapability()
        guard isCapable else { return }

        // Auto-detect signed 16-bit negative minimums (e.g. 0xFFC0 = -64)
        if let rawMin = getData(for: .getMinimum, length: uvcSize) {
            if uvcSize == 2 && rawMin > 32767 {
                isSigned = true
            }
        }

        if let minVal = getIntValue(for: .getMinimum) {
            minimum = minVal
        }
        if let maxVal = getIntValue(for: .getMaximum) {
            maximum = maxVal
        }
        if let defVal = getIntValue(for: .getDefault) {
            defaultValue = defVal
        }
        if let resVal = getData(for: .getResolution, length: uvcSize), resVal > 0 {
            resolution = resVal
        }
        if let curVal = getIntValue(for: .getCurrent) {
            _current = curVal
        }

        if minimum >= maximum {
            isCapable = false
        }
    }

    public func refresh() {
        if let curVal = getIntValue(for: .getCurrent) {
            _current = curVal
        }
    }

    public func resetToDefault() {
        current = defaultValue
    }
}

// MARK: - Boolean Control (Auto Switches: Auto Exposure, Auto WB, Auto Focus)

public final class UVCBoolControl: UVCControl {
    public private(set) var defaultValue: Bool = false
    private var _isEnabled: Bool = false

    public var isEnabled: Bool {
        get { return _isEnabled }
        set {
            let val = newValue ? 1 : 0
            if setData(value: val, length: uvcSize) {
                _isEnabled = newValue
            }
        }
    }

    public override init(interface: USBInterfacePointer,
                         size: Int,
                         selector: UVCSelector,
                         unit: Int,
                         interfaceNumber: Int) {
        super.init(interface: interface, size: size, selector: selector, unit: unit, interfaceNumber: interfaceNumber)
        configure()
    }

    public func configure() {
        checkCapability()
        guard isCapable else { return }

        if let defVal = getData(for: .getDefault, length: uvcSize) {
            defaultValue = (defVal != 0)
        }
        if let curVal = getData(for: .getCurrent, length: uvcSize) {
            _isEnabled = (curVal != 0)
        }
    }

    public func refresh() {
        if let curVal = getData(for: .getCurrent, length: uvcSize) {
            _isEnabled = (curVal != 0)
        }
    }

    public func resetToDefault() {
        isEnabled = defaultValue
    }
}

// MARK: - Exposure Mode Control (UVC CT_AE_MODE_CONTROL Bitmap)

public final class UVCExposureModeControl: UVCControl {
    public enum Mode: Int {
        case manual = 1
        case auto = 2
        case shutterPriority = 4
        case aperturePriority = 8
    }

    public private(set) var defaultValue: Mode = .aperturePriority
    private var _currentMode: Mode = .aperturePriority
    public private(set) var supportedModes: [Mode] = []

    public var currentMode: Mode {
        get { return _currentMode }
        set {
            if setData(value: newValue.rawValue, length: uvcSize) {
                _currentMode = newValue
            }
        }
    }

    public var isAuto: Bool {
        get {
            return _currentMode == .aperturePriority || _currentMode == .auto
        }
        set {
            if newValue {
                let target: Mode = supportedModes.contains(.aperturePriority) ? .aperturePriority : .auto
                currentMode = target
            } else {
                currentMode = .manual
            }
        }
    }

    public override init(interface: USBInterfacePointer,
                         size: Int = 1,
                         selector: UVCSelector = UVCCameraTerminalControl.autoExposureMode,
                         unit: Int,
                         interfaceNumber: Int) {
        super.init(interface: interface, size: size, selector: selector, unit: unit, interfaceNumber: interfaceNumber)
        configure()
    }

    public func configure() {
        checkCapability()
        guard isCapable else { return }

        if let res = getData(for: .getResolution, length: uvcSize) {
            supportedModes = []
            if (res & 1) != 0 { supportedModes.append(.manual) }
            if (res & 2) != 0 { supportedModes.append(.auto) }
            if (res & 4) != 0 { supportedModes.append(.shutterPriority) }
            if (res & 8) != 0 { supportedModes.append(.aperturePriority) }
        } else {
            supportedModes = [.manual, .aperturePriority]
        }

        if let defVal = getData(for: .getDefault, length: uvcSize), let mode = Mode(rawValue: defVal) {
            defaultValue = mode
        }
        if let curVal = getData(for: .getCurrent, length: uvcSize), let mode = Mode(rawValue: curVal) {
            _currentMode = mode
        }
    }

    public func refresh() {
        if let curVal = getData(for: .getCurrent, length: uvcSize), let mode = Mode(rawValue: curVal) {
            _currentMode = mode
        }
    }

    public func resetToDefault() {
        currentMode = defaultValue
    }
}
