//
//  UVCDiscovery.swift
//  WebcamSettings
//
//  Discovers all connected USB Video Class cameras via IOKit
//

import Foundation
import IOKit
import IOKit.usb

public final class UVCDiscovery {

    public static func discoverDevices() -> [UVCDevice] {
        var devices: [UVCDevice] = []

        // In macOS 12+, kIOMainPortDefault is standard; fallback to 0 for compatibility
        let masterPort: mach_port_t
        if #available(macOS 12.0, *) {
            masterPort = kIOMainPortDefault
        } else {
            masterPort = 0
        }

        // Search for USB Devices
        for deviceClassName in ["IOUSBDevice", "IOUSBHostDevice"] {
            guard let matchingDict = IOServiceMatching(deviceClassName) as? [String: Any] else {
                continue
            }

            var iterator: io_iterator_t = 0
            let kr = IOServiceGetMatchingServices(masterPort, matchingDict as CFDictionary, &iterator)
            guard kr == KERN_SUCCESS else { continue }

            var usbService = IOIteratorNext(iterator)
            while usbService != 0 {
                if let uvcDev = inspectUSBService(usbService) {
                    // Check if already in list (avoid duplicates if both classes match)
                    if !devices.contains(where: { $0.locationID == uvcDev.locationID && $0.vendorID == uvcDev.vendorID && $0.productID == uvcDev.productID }) {
                        devices.append(uvcDev)
                    }
                }
                IOObjectRelease(usbService)
                usbService = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }

        return devices
    }

    private static func inspectUSBService(_ usbDevice: io_service_t) -> UVCDevice? {
        var propsRef: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(usbDevice, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = propsRef?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        let vendorID = (props["idVendor"] as? NSNumber)?.intValue ?? 0
        let productID = (props["idProduct"] as? NSNumber)?.intValue ?? 0
        let locationID = (props["locationID"] as? NSNumber)?.uint32Value ?? 0
        let name = (props["USB Product Name"] as? String) ??
                   (props["kUSBProductString"] as? String) ??
                   "USB Camera"

        // Protect monitors, USB-C hubs, and non-video devices from reset
        let deviceClass = (props["bDeviceClass"] as? NSNumber)?.intValue ?? 0
        var hasVideoInterface = (deviceClass == 14)

        if !hasVideoInterface {
            var childIter: io_iterator_t = 0
            if IORegistryEntryGetChildIterator(usbDevice, kIOServicePlane, &childIter) == KERN_SUCCESS {
                var child = IOIteratorNext(childIter)
                while child != 0 {
                    if let ifClassProp = IORegistryEntryCreateCFProperty(child, "bInterfaceClass" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber {
                        if ifClassProp.intValue == 14 {
                            hasVideoInterface = true
                        }
                    }
                    IOObjectRelease(child)
                    if hasVideoInterface { break }
                    child = IOIteratorNext(childIter)
                }
                IOObjectRelease(childIter)
            }
        }

        guard hasVideoInterface else {
            return nil
        }

        // Create plugin interface for USB Device
        guard let devicePlugin = UVCInterfaceParser.createPluginInterface(for: usbDevice, uuid: UVCUUIDs.kIOUSBDeviceUserClientTypeID) else {
            return nil
        }
        defer { _ = devicePlugin.pointee.pointee.Release(devicePlugin) }

        var devInterfacePtr: LPVOID?
        let queryDeviceResult = devicePlugin.pointee.pointee.QueryInterface(
            devicePlugin,
            CFUUIDGetUUIDBytes(UVCUUIDs.kIOUSBDeviceInterfaceID),
            &devInterfacePtr
        )
        guard queryDeviceResult == kIOReturnSuccess,
              let rawDev = devInterfacePtr else {
            return nil
        }
        let deviceInterface = rawDev.assumingMemoryBound(to: UnsafeMutablePointer<IOUSBDeviceInterface>.self)
        defer { _ = deviceInterface.pointee.pointee.Release(deviceInterface) }

        // Find Video Control interface
        var interfaceRequest = IOUSBFindInterfaceRequest(
            bInterfaceClass: UVCConstants.classVideo,
            bInterfaceSubClass: UVCConstants.subclassVideoControl,
            bInterfaceProtocol: UInt16(kIOUSBFindInterfaceDontCare),
            bAlternateSetting: UInt16(kIOUSBFindInterfaceDontCare)
        )

        var interfaceIterator: io_iterator_t = 0
        guard deviceInterface.pointee.pointee.CreateInterfaceIterator(
            deviceInterface,
            &interfaceRequest,
            &interfaceIterator
        ) == kIOReturnSuccess else {
            return nil
        }
        defer { IOObjectRelease(interfaceIterator) }

        let ifaceService = IOIteratorNext(interfaceIterator)
        guard ifaceService != 0 else { return nil }
        defer { IOObjectRelease(ifaceService) }

        // Get Configuration Descriptor to find Unit IDs
        var configDescPtr: IOUSBConfigurationDescriptorPtr?
        let configResult = deviceInterface.pointee.pointee.GetConfigurationDescriptorPtr(deviceInterface, 0, &configDescPtr)
        guard configResult == kIOReturnSuccess, let validConfigDesc = configDescPtr else {
            return nil
        }

        let descInfo = UVCInterfaceParser.parseConfigurationDescriptor(validConfigDesc)

        // Create plugin interface for USB Interface
        guard let ifacePlugin = UVCInterfaceParser.createPluginInterface(for: ifaceService, uuid: UVCUUIDs.kIOUSBInterfaceUserClientTypeID) else {
            return nil
        }

        var ifaceInterfacePtr: LPVOID?
        let queryIfaceResult = ifacePlugin.pointee.pointee.QueryInterface(
            ifacePlugin,
            CFUUIDGetUUIDBytes(UVCUUIDs.kIOUSBInterfaceInterfaceID190),
            &ifaceInterfacePtr
        )
        guard queryIfaceResult == kIOReturnSuccess,
              let rawIface = ifaceInterfacePtr else {
            _ = ifacePlugin.pointee.pointee.Release(ifacePlugin)
            return nil
        }

        let usbInterface = rawIface.assumingMemoryBound(to: UnsafeMutablePointer<IOUSBInterfaceInterface190>.self)

        return UVCDevice(
            name: name,
            vendorID: vendorID,
            productID: productID,
            locationID: locationID,
            interface: usbInterface,
            plugin: ifacePlugin,
            descriptorInfo: descInfo
        )
    }
}
