//
//  UVCInterface.swift
//  WebcamSettings
//
//  IOKit USB descriptor parsing and interface query helpers
//

import Foundation
import IOKit
import IOKit.usb

// Standard IOKit Plugin and USB UUIDs
public struct UVCUUIDs {
    public static let kIOCFPlugInInterfaceID: CFUUID = CFUUIDGetConstantUUIDWithBytes(
        kCFAllocatorDefault,
        0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4,
        0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F
    )

    public static let kIOUSBDeviceUserClientTypeID: CFUUID = CFUUIDGetConstantUUIDWithBytes(
        kCFAllocatorDefault,
        0x9d, 0xc7, 0xb7, 0x80, 0x9e, 0xc0, 0x11, 0xD4,
        0xa5, 0x4f, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61
    )

    public static let kIOUSBInterfaceUserClientTypeID: CFUUID = CFUUIDGetConstantUUIDWithBytes(
        kCFAllocatorDefault,
        0x2d, 0x97, 0x86, 0xc6, 0x9e, 0xf3, 0x11, 0xD4,
        0xad, 0x51, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61
    )

    public static let kIOUSBDeviceInterfaceID: CFUUID = CFUUIDGetConstantUUIDWithBytes(
        kCFAllocatorDefault,
        0x5c, 0x81, 0x87, 0xd0, 0x9e, 0xf3, 0x11, 0xD4,
        0x8b, 0x45, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61
    )

    public static let kIOUSBInterfaceInterfaceID190: CFUUID = CFUUIDGetConstantUUIDWithBytes(
        kCFAllocatorDefault,
        0x8f, 0xdb, 0x84, 0x55, 0x74, 0xa6, 0x11, 0xD6,
        0x97, 0xb1, 0x00, 0x30, 0x65, 0xd3, 0x60, 0x8e
    )
}

public struct UVCDescriptorInfo {
    public let processingUnitID: Int
    public let cameraTerminalID: Int
    public let interfaceID: Int

    public init(processingUnitID: Int, cameraTerminalID: Int, interfaceID: Int) {
        self.processingUnitID = processingUnitID
        self.cameraTerminalID = cameraTerminalID
        self.interfaceID = interfaceID
    }
}

public final class UVCInterfaceParser {

    public static func parseConfigurationDescriptor(
        _ configPtr: IOUSBConfigurationDescriptorPtr
    ) -> UVCDescriptorInfo {
        var processingUnitID = -1
        var cameraTerminalID = -1
        var interfaceID = -1

        let totalLength = Int(configPtr.pointee.wTotalLength)
        let headerLength = Int(configPtr.pointee.bLength)
        guard totalLength > headerLength else {
            return UVCDescriptorInfo(processingUnitID: -1, cameraTerminalID: -1, interfaceID: -1)
        }

        var offset = headerLength
        let basePtr = UnsafeMutableRawPointer(configPtr)

        var inVideoControl = false

        while offset + 2 <= totalLength {
            let descLen = Int(basePtr.load(fromByteOffset: offset, as: UInt8.self))
            guard descLen >= 2, offset + descLen <= totalLength else { break }

            let descType = basePtr.load(fromByteOffset: offset + 1, as: UInt8.self)

            // Look for Interface Descriptor (0x04)
            if descType == kUSBInterfaceDesc && descLen >= 9 {
                let ifaceClass = basePtr.load(fromByteOffset: offset + 5, as: UInt8.self)
                let ifaceSubClass = basePtr.load(fromByteOffset: offset + 6, as: UInt8.self)
                let ifaceNum = basePtr.load(fromByteOffset: offset + 2, as: UInt8.self)

                if ifaceClass == UInt8(UVCConstants.classVideo) &&
                   ifaceSubClass == UInt8(UVCConstants.subclassVideoControl) {
                    interfaceID = Int(ifaceNum)
                    inVideoControl = true
                } else {
                    inVideoControl = false
                }
            }
            // Look for Class-Specific Interface Descriptor (0x24) ONLY within Video Control interface
            else if inVideoControl && descType == UVCConstants.descriptorTypeInterface && descLen >= 3 {
                let subType = basePtr.load(fromByteOffset: offset + 2, as: UInt8.self)
                if subType == UVCConstants.DescriptorSubtype.processingUnit.rawValue && descLen >= 5 {
                    let unitID = basePtr.load(fromByteOffset: offset + 3, as: UInt8.self)
                    processingUnitID = Int(unitID)
                } else if subType == UVCConstants.DescriptorSubtype.inputTerminal.rawValue && descLen >= 4 {
                    let termID = basePtr.load(fromByteOffset: offset + 3, as: UInt8.self)
                    cameraTerminalID = Int(termID)
                }
            }

            offset += descLen
        }

        return UVCDescriptorInfo(
            processingUnitID: processingUnitID,
            cameraTerminalID: cameraTerminalID,
            interfaceID: interfaceID
        )
    }

    public static func createPluginInterface(for service: io_service_t, uuid: CFUUID) -> UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>>? {
        var plugInInterface: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
        var score: Int32 = 0
        let kr = IOCreatePlugInInterfaceForService(
            service,
            uuid,
            UVCUUIDs.kIOCFPlugInInterfaceID,
            &plugInInterface,
            &score
        )
        guard kr == kIOReturnSuccess, let validPtr = plugInInterface, validPtr.pointee != nil else {
            return nil
        }
        return validPtr.withMemoryRebound(to: UnsafeMutablePointer<IOCFPlugInInterface>.self, capacity: 1) { $0 }
    }
}
