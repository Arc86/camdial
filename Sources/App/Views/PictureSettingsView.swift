//
//  PictureSettingsView.swift
//  WebcamSettings
//
//  Picture controls: Brightness, Contrast, Saturation, Sharpness, White Balance
//

import SwiftUI

public struct PictureSettingsView: View {
    @ObservedObject var vm = CameraViewModel.shared

    public init(device: CameraDevice? = nil) {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let uvc = vm.activeDevice?.uvcDevice {
                    // Brightness
                    if uvc.brightness.isCapable {
                        ControlSliderRow(
                            title: "Brightness",
                            icon: "sun.min",
                            value: Binding(get: { vm.brightness }, set: { vm.setBrightness($0) }),
                            range: Double(uvc.brightness.minimum)...Double(uvc.brightness.maximum),
                            step: Double(uvc.brightness.resolution),
                            defaultValue: Double(uvc.brightness.defaultValue),
                            isCapable: true
                        )
                    }

                    // Contrast
                    if uvc.contrast.isCapable {
                        ControlSliderRow(
                            title: "Contrast",
                            icon: "circle.lefthalf.filled",
                            value: Binding(get: { vm.contrast }, set: { vm.setContrast($0) }),
                            range: Double(uvc.contrast.minimum)...Double(uvc.contrast.maximum),
                            step: Double(uvc.contrast.resolution),
                            defaultValue: Double(uvc.contrast.defaultValue),
                            isCapable: true
                        )
                    }

                    // Saturation
                    if uvc.saturation.isCapable {
                        ControlSliderRow(
                            title: "Saturation",
                            icon: "paintpalette",
                            value: Binding(get: { vm.saturation }, set: { vm.setSaturation($0) }),
                            range: Double(uvc.saturation.minimum)...Double(uvc.saturation.maximum),
                            step: Double(uvc.saturation.resolution),
                            defaultValue: Double(uvc.saturation.defaultValue),
                            isCapable: true
                        )
                    }

                    // Sharpness
                    if uvc.sharpness.isCapable {
                        ControlSliderRow(
                            title: "Sharpness",
                            icon: "triangle",
                            value: Binding(get: { vm.sharpness }, set: { vm.setSharpness($0) }),
                            range: Double(uvc.sharpness.minimum)...Double(uvc.sharpness.maximum),
                            step: Double(uvc.sharpness.resolution),
                            defaultValue: Double(uvc.sharpness.defaultValue),
                            isCapable: true
                        )
                    }

                    // White Balance (Auto switch + Color Temperature Kelvin slider)
                    if uvc.whiteBalance.isCapable {
                        ControlSliderRow(
                            title: "White Balance",
                            icon: "thermometer.sun",
                            value: Binding(get: { vm.whiteBalance }, set: { vm.setWhiteBalance($0) }),
                            range: Double(uvc.whiteBalance.minimum)...Double(uvc.whiteBalance.maximum),
                            step: Double(uvc.whiteBalance.resolution),
                            unit: "K",
                            defaultValue: Double(uvc.whiteBalance.defaultValue),
                            isCapable: true,
                            autoBinding: uvc.whiteBalanceAuto.isCapable ? Binding(
                                get: { vm.whiteBalanceAuto },
                                set: { vm.setWhiteBalanceAuto($0) }
                            ) : nil
                        )
                    }

                    // Hue (if supported)
                    if uvc.hue.isCapable {
                        ControlSliderRow(
                            title: "Hue",
                            icon: "eyedropper",
                            value: Binding(get: { vm.hue }, set: { vm.setHue($0) }),
                            range: Double(uvc.hue.minimum)...Double(uvc.hue.maximum),
                            step: Double(uvc.hue.resolution),
                            defaultValue: Double(uvc.hue.defaultValue),
                            isCapable: true
                        )
                    }

                    // Gamma (if supported)
                    if uvc.gamma.isCapable {
                        ControlSliderRow(
                            title: "Gamma",
                            icon: "circle.circle",
                            value: Binding(get: { vm.gamma }, set: { vm.setGamma($0) }),
                            range: Double(uvc.gamma.minimum)...Double(uvc.gamma.maximum),
                            step: Double(uvc.gamma.resolution),
                            defaultValue: Double(uvc.gamma.defaultValue),
                            isCapable: true
                        )
                    }

                    // Backlight Compensation
                    if uvc.backlightCompensation.isCapable {
                        ControlSliderRow(
                            title: "Backlight Comp.",
                            icon: "sun.dust",
                            value: Binding(get: { vm.backlight }, set: { vm.setBacklight($0) }),
                            range: Double(uvc.backlightCompensation.minimum)...Double(uvc.backlightCompensation.maximum),
                            step: Double(uvc.backlightCompensation.resolution),
                            defaultValue: Double(uvc.backlightCompensation.defaultValue),
                            isCapable: true
                        )
                    }
                } else {
                    Text("No direct UVC picture controls for this camera.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                }
            }
            .padding()
        }
    }
}
