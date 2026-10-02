//
//  main.swift
//  camdial CLI
//
//  Command-line interface for scripting and adjusting webcam hardware settings
//

import Foundation
import IOKit

func printUsage() {
    print("""
    camdial - macOS Webcam Hardware Settings Utility

    USAGE:
      camdial list
      camdial get [--camera <name|id>]
      camdial set [--camera <name|id>] [OPTIONS]
      camdial reset [--camera <name|id>]
      camdial preset list
      camdial preset apply <preset_name> [--camera <name|id>]

    OPTIONS for 'set':
      --brightness <int>           Set brightness
      --contrast <int>             Set contrast
      --saturation <int>           Set color saturation
      --sharpness <int>            Set sharpness
      --white-balance <kelvin>     Set white balance temperature (Kelvin, e.g. 4500)
      --white-balance-auto <bool>  Enable/disable auto white balance (true/false)
      --exposure <int>             Set absolute exposure time
      --exposure-auto <bool>       Enable/disable auto exposure (true/false)
      --gain <int>                 Set sensor gain (ISO sensitivity)
      --focus <int>                Set manual focus distance
      --focus-auto <bool>          Enable/disable auto focus (true/false)
      --zoom <int>                 Set zoom factor
      --anti-flicker <0|50|60>     Set anti-flicker frequency (0=Off, 50=50Hz, 60=60Hz)

    EXAMPLES:
      camdial list
      camdial get
      camdial set --brightness 130 --saturation 140 --white-balance-auto false --white-balance 5200
      camdial preset apply "Natural Daylight"
      camdial reset
    """)
}

func findTargetCamera(named query: String?) -> UVCDevice? {
    let devices = UVCDiscovery.discoverDevices()
    if devices.isEmpty {
        return nil
    }
    guard let query = query, !query.isEmpty else {
        return devices.first
    }
    return devices.first {
        $0.name.lowercased().contains(query.lowercased()) ||
        String($0.vendorID) == query ||
        String($0.productID) == query
    } ?? devices.first
}

func runCLI() {
    let args = CommandLine.arguments
    guard args.count > 1 else {
        printUsage()
        return
    }

    let command = args[1]
    if command == "--help" || command == "-h" || command == "help" {
        printUsage()
        return
    }

    var cameraQuery: String? = nil
    var i = 2
    while i < args.count {
        if args[i] == "--camera" && i + 1 < args.count {
            cameraQuery = args[i + 1]
            i += 2
        } else {
            i += 1
        }
    }

    switch command {
    case "list":
        let devices = UVCDiscovery.discoverDevices()
        print("Discovered \(devices.count) UVC Hardware Webcams:")
        if devices.isEmpty {
            print("  (No external UVC webcams currently detected via USB)")
        }
        for (idx, dev) in devices.enumerated() {
            print("  [\(idx)] \(dev.name)")
            print("      Vendor ID:  0x\(String(dev.vendorID, radix: 16)) (\(dev.vendorID))")
            print("      Product ID: 0x\(String(dev.productID, radix: 16)) (\(dev.productID))")
            print("      Location:   0x\(String(dev.locationID, radix: 16))")
            print("      PU ID:      \(dev.descriptorInfo.processingUnitID)")
            print("      CT ID:      \(dev.descriptorInfo.cameraTerminalID)")
            print("      IF ID:      \(dev.descriptorInfo.interfaceID)")
        }

    case "get":
        guard let dev = findTargetCamera(named: cameraQuery) else {
            print("Error: No UVC webcam found.")
            exit(1)
        }
        dev.refreshAll()
        print("Camera: \(dev.name)")
        print("------------------------------------------------------------")

        func printControl(_ name: String, _ c: UVCIntControl, unit: String = "") {
            guard c.isCapable else { return }
            let paddedName = name.padding(toLength: 22, withPad: " ", startingAt: 0)
            let unitStr = unit.isEmpty ? "" : " " + unit
            print("  \(paddedName): \(c.current)  (min: \(c.minimum), max: \(c.maximum), default: \(c.defaultValue))\(unitStr)")
        }

        func printBool(_ name: String, _ c: UVCBoolControl) {
            guard c.isCapable else { return }
            let paddedName = name.padding(toLength: 22, withPad: " ", startingAt: 0)
            let status = c.isEnabled ? "Auto / Enabled" : "Manual / Disabled"
            print("  \(paddedName): \(status)")
        }

        print("Picture Controls:")
        printControl("Brightness", dev.brightness)
        printControl("Contrast", dev.contrast)
        printControl("Saturation", dev.saturation)
        printControl("Sharpness", dev.sharpness)
        printBool("Auto White Balance", dev.whiteBalanceAuto)
        printControl("White Balance Temp", dev.whiteBalance, unit: "K")
        printControl("Hue", dev.hue)
        printControl("Gamma", dev.gamma)
        printControl("Backlight Comp.", dev.backlightCompensation)
        printControl("Anti-Flicker Freq.", dev.powerLineFrequency)

        print("\nExposure & Lighting:")
        if dev.autoExposure.isCapable {
            let paddedName = "Auto Exposure".padding(toLength: 22, withPad: " ", startingAt: 0)
            let status = dev.autoExposure.isAuto ? "Auto / Enabled" : "Manual / Disabled"
            print("  \(paddedName): \(status)")
        }
        printControl("Exposure Time", dev.exposureTime)
        printControl("Sensor Gain", dev.gain)

        print("\nFocus & Optics:")
        printBool("Auto Focus", dev.autoFocus)
        printControl("Focus Distance", dev.focus)
        printControl("Zoom", dev.zoom)
        print("------------------------------------------------------------")

    case "set":
        guard let dev = findTargetCamera(named: cameraQuery) else {
            print("Error: No UVC webcam found.")
            exit(1)
        }

        var idx = 2
        var modified = false
        while idx < args.count {
            let key = args[idx]
            guard idx + 1 < args.count else { break }
            let val = args[idx + 1]

            switch key {
            case "--brightness":
                if let v = Int(val) { dev.brightness.current = v; print("Set Brightness -> \(v)"); modified = true }
            case "--contrast":
                if let v = Int(val) { dev.contrast.current = v; print("Set Contrast -> \(v)"); modified = true }
            case "--saturation":
                if let v = Int(val) { dev.saturation.current = v; print("Set Saturation -> \(v)"); modified = true }
            case "--sharpness":
                if let v = Int(val) { dev.sharpness.current = v; print("Set Sharpness -> \(v)"); modified = true }
            case "--white-balance":
                if let v = Int(val) { dev.setManualWhiteBalance(kelvin: v); print("Set White Balance -> \(v) K (Auto WB turned off)"); modified = true }
            case "--white-balance-auto":
                let b = (val.lowercased() == "true" || val == "1")
                dev.whiteBalanceAuto.isEnabled = b
                print("Set Auto White Balance -> \(b)")
                modified = true
            case "--exposure":
                if let v = Int(val) { dev.setManualExposure(time: v); print("Set Exposure Time -> \(v) (Auto Exposure turned off)"); modified = true }
            case "--exposure-auto":
                let b = (val.lowercased() == "true" || val == "1")
                dev.autoExposure.isAuto = b
                print("Set Auto Exposure -> \(b)")
                modified = true
            case "--gain":
                if let v = Int(val) { dev.setManualGain(value: v); print("Set Sensor Gain -> \(v) (Auto Exposure turned off)"); modified = true }
            case "--focus":
                if let v = Int(val) { dev.setManualFocus(distance: v); print("Set Focus Distance -> \(v) (Auto Focus turned off)"); modified = true }
            case "--focus-auto":
                let b = (val.lowercased() == "true" || val == "1")
                dev.autoFocus.isEnabled = b
                print("Set Auto Focus -> \(b)")
                modified = true
            case "--zoom":
                if let v = Int(val) { dev.zoom.current = v; print("Set Zoom -> \(v)"); modified = true }
            case "--anti-flicker":
                if let v = Int(val) {
                    let code = (v == 50 ? 1 : (v == 60 ? 2 : 0))
                    dev.powerLineFrequency.current = code
                    print("Set Anti-Flicker -> \(v) Hz")
                    modified = true
                }
            default:
                break
            }
            idx += 2
        }

        if modified {
            let id = "uvc_\(dev.vendorID)_\(dev.productID)_\(dev.locationID)"
            PresetManager.shared.saveDeviceLastState(deviceID: id, settings: dev.dumpSettings())
            print("Successfully updated hardware settings for \(dev.name).")
        } else {
            print("No valid settings passed. Run with --help for options.")
        }

    case "reset":
        guard let dev = findTargetCamera(named: cameraQuery) else {
            print("Error: No UVC webcam found.")
            exit(1)
        }
        dev.resetAllToDefaults()
        let id = "uvc_\(dev.vendorID)_\(dev.productID)_\(dev.locationID)"
        PresetManager.shared.saveDeviceLastState(deviceID: id, settings: dev.dumpSettings())
        print("Reset all hardware registers on \(dev.name) to factory defaults.")

    case "preset":
        if args.count > 2 && args[2] == "list" {
            print("Available Presets:")
            for p in PresetManager.shared.presets {
                print("  • \(p.name)\(p.isBuiltIn ? " (Built-in)" : "")")
            }
        } else if args.count > 3 && args[2] == "apply" {
            let presetName = args[3]
            guard let preset = PresetManager.shared.presets.first(where: { $0.name.lowercased() == presetName.lowercased() }) else {
                print("Error: Preset '\(presetName)' not found.")
                exit(1)
            }
            guard let dev = findTargetCamera(named: cameraQuery) else {
                print("Error: No UVC webcam found.")
                exit(1)
            }
            var dict: [String: Any] = [:]
            preset.values.forEach { dict[$0.key] = $0.value }
            preset.booleans.forEach { dict[$0.key] = $0.value }
            dev.applySettings(dict)
            let id = "uvc_\(dev.vendorID)_\(dev.productID)_\(dev.locationID)"
            PresetManager.shared.saveDeviceLastState(deviceID: id, settings: dev.dumpSettings())
            print("Applied preset '\(preset.name)' to \(dev.name).")
        } else {
            printUsage()
        }

    default:
        print("Unknown command: \(command)")
        printUsage()
    }
}

runCLI()
