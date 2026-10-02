//
//  ContentView.swift
//  WebcamSettings
//
//  Main application view hosting camera selector, live preview, tabs, and controls
//

import SwiftUI
import AVFoundation

public struct ContentView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @State private var selectedTab: Int = 0
    @State private var isPreviewVisible: Bool = false
    public var onPinToggle: (() -> Void)?

    public init(onPinToggle: (() -> Void)? = nil) {
        self.onPinToggle = onPinToggle
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header: Camera Selector & Utility Actions
            HStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 13))

                if deviceManager.devices.isEmpty {
                    Text("No Webcams Detected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Picker("", selection: Binding(
                        get: { deviceManager.selectedDevice?.id ?? "" },
                        set: { newID in deviceManager.selectDevice(id: newID) }
                    )) {
                        ForEach(deviceManager.devices) { dev in
                            HStack {
                                Text(dev.name)
                                if dev.isExternal {
                                    Text("(USB)").foregroundColor(.secondary)
                                } else {
                                    Text("(Built-in)").foregroundColor(.secondary)
                                }
                            }
                            .tag(dev.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }

                Button(action: { deviceManager.refreshDevices() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help("Refresh connected cameras")

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPreviewVisible.toggle()
                    }
                }) {
                    Image(systemName: isPreviewVisible ? "video.slash" : "video.badge.waveform")
                        .font(.system(size: 12))
                        .foregroundColor(isPreviewVisible ? .accentColor : .primary)
                }
                .buttonStyle(.borderless)
                .help(isPreviewVisible ? "Hide Video Preview" : "Show Live Video Preview")

                if let onPin = onPinToggle {
                    Button(action: onPin) {
                        Image(systemName: "pin")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Detach into floating window")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Optional Live Video Preview
            if isPreviewVisible {
                ZStack {
                    if let avDev = deviceManager.selectedDevice?.avDevice {
                        CameraPreviewView(captureDevice: avDev, isRunning: isPreviewVisible)
                            .frame(height: 125)
                            .cornerRadius(8)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    } else {
                        Rectangle()
                            .fill(Color.black.opacity(0.8))
                            .frame(height: 125)
                            .overlay(
                                Text("Preview unavailable for this camera")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            )
                            .cornerRadius(8)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                }
                .background(Color(NSColor.underPageBackgroundColor))
                Divider()
            }

            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Picture").tag(0)
                Text("Exposure").tag(1)
                Text("Optics").tag(2)
                Text("Presets").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            Divider()

            // Tab Content (flexibly fills available space with internal scrolling)
            Group {
                switch selectedTab {
                case 0:
                    PictureSettingsView(device: deviceManager.selectedDevice)
                case 1:
                    ExposureSettingsView(device: deviceManager.selectedDevice)
                case 2:
                    OpticsSettingsView(device: deviceManager.selectedDevice)
                case 3:
                    PresetsView(device: deviceManager.selectedDevice)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer
            HStack {
                if let dev = deviceManager.selectedDevice {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text(dev.isExternal ? "Hardware UVC Connected" : "AVFoundation Camera")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 7, height: 7)
                    Text("No Camera Selected")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Reset") {
                    CameraViewModel.shared.resetToDefaults()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .help("Reset current camera to defaults")

                Text("•").foregroundColor(.secondary).font(.system(size: 9))

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 360, height: 440)
    }
}
