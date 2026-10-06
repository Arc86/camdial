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
    @State private var selectedTab: SettingsTab = .picture
    @State private var isPreviewVisible: Bool = false
    /// Aspect ratio reported by the running capture session (its preset can change the format).
    @State private var sessionAspectRatio: CGFloat?
    public var onPinToggle: (() -> Void)?

    private static let width: CGFloat = 400
    private static let previewInset: CGFloat = 12
    /// Header, tab bar, footer and dividers: everything around the tab content and preview.
    private static let chromeHeight: CGFloat = 150
    private static let maxContentHeight: CGFloat = 440

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
            .environment(\.settingsContentMaxHeight, contentMaxHeight)
                }

                Button(action: { deviceManager.refreshDevices() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help("Refresh connected cameras")

                Button(action: {
                    // No withAnimation: the window animates its own resize, and a SwiftUI
                    // animation of the preview insertion on a different curve makes it stutter
                    isPreviewVisible.toggle()
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

            // Optional Live Video Preview, shown at the camera's native aspect ratio
            if isPreviewVisible {
                Group {
                    if let avDev = deviceManager.selectedDevice?.avDevice {
                        CameraPreviewView(captureDevice: avDev, isRunning: isPreviewVisible) { ratio in
                            sessionAspectRatio = ratio
                        }
                    } else {
                        Color.black.opacity(0.8)
                            .overlay(
                                Text("Preview unavailable for this camera")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                }
                // Explicit size: an .aspectRatio(.fit) frame is flexible and gets squeezed
                // narrower whenever the window offers less height than the ideal
                .frame(width: previewWidth, height: previewWidth / previewAspectRatio)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, Self.previewInset)
                .padding(.top, 10)
            }

            SettingsTabBar(selection: $selectedTab)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            // Tab Content (sizes to its controls; scrolls past contentMaxHeight)
            Group {
                switch selectedTab {
                case .picture:
                    PictureSettingsView(device: deviceManager.selectedDevice)
                case .exposure:
                    ExposureSettingsView(device: deviceManager.selectedDevice)
                case .optics:
                    OpticsSettingsView(device: deviceManager.selectedDevice)
                case .presets:
                    PresetsView(device: deviceManager.selectedDevice)
                }
            }
            .frame(maxWidth: .infinity)
            .environment(\.settingsContentMaxHeight, contentMaxHeight)

            // Absorbs slack while the window animates to a taller size, keeping the
            // header pinned to the top and the footer to the bottom edge
            Spacer(minLength: 0)

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
        // Height follows the content, so each tab (and the preview) gets exactly the room it needs
        .frame(width: Self.width)
        // Opaque backing so the popover's glass material doesn't wash out the controls
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var previewAspectRatio: CGFloat {
        sessionAspectRatio ?? deviceAspectRatio
    }

    private var previewWidth: CGFloat {
        Self.width - 2 * Self.previewInset
    }

    private var previewHeight: CGFloat {
        isPreviewVisible ? previewWidth / previewAspectRatio + 10 : 0
    }

    /// Keeps the whole window on screen: tab content gets whatever height the screen
    /// has left after the chrome and preview, up to maxContentHeight, then scrolls.
    private var contentMaxHeight: CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let available = screenHeight - Self.chromeHeight - previewHeight - 40
        return max(160, min(Self.maxContentHeight, available))
    }

    /// Width / height of the camera's current video format (16:9 if unknown).
    private var deviceAspectRatio: CGFloat {
        guard let format = deviceManager.selectedDevice?.avDevice?.activeFormat else { return 16.0 / 9.0 }
        let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        guard dims.width > 0, dims.height > 0 else { return 16.0 / 9.0 }
        return CGFloat(dims.width) / CGFloat(dims.height)
    }
}
