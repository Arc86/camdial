//
//  ExposureSettingsView.swift
//  WebcamSettings
//
//  Lighting & Exposure controls: Auto Exposure, Shutter Time, Gain, Anti-Flicker
//

import SwiftUI

public struct ExposureSettingsView: View {
    @ObservedObject var vm = CameraViewModel.shared

    public init(device: CameraDevice? = nil) {}

    public var body: some View {
        SettingsTabContainer {
            if let uvc = vm.activeDevice?.uvcDevice {
                // Auto Exposure Toggle + Manual Shutter Time
                if uvc.exposureTime.isCapable {
                    ControlSliderRow(
                        title: "Exposure",
                        icon: "camera.metering.matrix",
                        value: Binding(get: { vm.exposureTime }, set: { vm.setExposureTime($0) }),
                        range: Double(uvc.exposureTime.minimum)...Double(uvc.exposureTime.maximum),
                        step: Double(max(1, uvc.exposureTime.resolution)),
                        unit: "",
                        defaultValue: Double(uvc.exposureTime.defaultValue),
                        isCapable: true,
                        autoBinding: uvc.autoExposure.isCapable ? Binding(
                            get: { vm.autoExposure },
                            set: { vm.setAutoExposure($0) }
                        ) : nil
                    )
                }

                // Sensor Gain (ISO / sensitivity)
                if uvc.gain.isCapable {
                    ControlSliderRow(
                        title: "Gain",
                        icon: "rays",
                        value: Binding(get: { vm.gain }, set: { vm.setGain($0) }),
                        range: Double(uvc.gain.minimum)...Double(uvc.gain.maximum),
                        step: Double(uvc.gain.resolution),
                        defaultValue: Double(uvc.gain.defaultValue),
                        isCapable: true
                    )
                }

                // Anti-Flicker / Power Line Frequency
                if uvc.powerLineFrequency.isCapable {
                    HStack(spacing: 6) {
                        SettingRowLabel(title: "Anti-Flicker", icon: "waveform.path.ecg")

                        Picker("", selection: Binding(
                            get: { vm.powerLineFreq },
                            set: { vm.setPowerLineFrequency($0) }
                        )) {
                            Text("Off").tag(0)
                            Text("50 Hz").tag(1)
                            Text("60 Hz").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.small)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help("Match your mains frequency: 50 Hz in Europe/Asia, 60 Hz in the Americas")
                    }
                    .padding(.vertical, 2)
                }
            } else {
                Text("No direct UVC exposure controls for this camera.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }
}
