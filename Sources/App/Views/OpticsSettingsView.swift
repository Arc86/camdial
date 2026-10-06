//
//  OpticsSettingsView.swift
//  WebcamSettings
//
//  Focus and Zoom controls for cameras with motorized or digital optics
//

import SwiftUI

public struct OpticsSettingsView: View {
    @ObservedObject var vm = CameraViewModel.shared

    public init(device: CameraDevice? = nil) {}

    public var body: some View {
        SettingsTabContainer {
            if let uvc = vm.activeDevice?.uvcDevice {
                // Focus
                if uvc.focus.isCapable {
                    ControlSliderRow(
                        title: "Focus",
                        icon: "scope",
                        value: Binding(get: { vm.focus }, set: { vm.setFocus($0) }),
                        range: Double(uvc.focus.minimum)...Double(uvc.focus.maximum),
                        step: Double(uvc.focus.resolution),
                        defaultValue: Double(uvc.focus.defaultValue),
                        isCapable: true,
                        autoBinding: uvc.autoFocus.isCapable ? Binding(
                            get: { vm.autoFocus },
                            set: { vm.setAutoFocus($0) }
                        ) : nil
                    )
                }

                // Zoom
                if uvc.zoom.isCapable {
                    ControlSliderRow(
                        title: "Zoom",
                        icon: "plus.magnifyingglass",
                        value: Binding(get: { vm.zoom }, set: { vm.setZoom($0) }),
                        range: Double(uvc.zoom.minimum)...Double(uvc.zoom.maximum),
                        step: Double(uvc.zoom.resolution),
                        defaultValue: Double(uvc.zoom.defaultValue),
                        isCapable: true
                    )
                }

                if !uvc.focus.isCapable && !uvc.zoom.isCapable {
                    Text("This camera has a fixed-focus lens and does not expose motorized focus or zoom controls.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                }
            } else {
                Text("No direct UVC focus or zoom controls for this camera.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }
}
