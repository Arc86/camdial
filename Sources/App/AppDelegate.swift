//
//  AppDelegate.swift
//  WebcamSettings
//
//  Menu bar extra lifecycle, NSPopover, and detachable floating NSPanel window
//

import Cocoa
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var floatingWindow: NSPanel?
    private var isPinned: Bool = false

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Setup status item in system menu bar
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if let image = NSImage(systemSymbolName: "video.badge.waveform", accessibilityDescription: "CamDial") {
                image.isTemplate = true
                button.image = image
            } else if let image = NSImage(systemSymbolName: "video.fill", accessibilityDescription: "CamDial") {
                image.isTemplate = true
                button.image = image
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        self.statusItem = item

        // Setup Popover
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        pop.contentSize = NSSize(width: 360, height: 440)
        let hostingView = NSHostingView(rootView: ContentView(onPinToggle: { [weak self] in
            self?.togglePinMode()
        }))
        pop.contentViewController = NSViewController()
        pop.contentViewController?.view = hostingView
        self.popover = pop


    }

    @objc public func togglePopover() {
        if isPinned, let win = floatingWindow {
            if win.isVisible {
                win.orderOut(nil)
            } else {
                win.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            return
        }

        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    public func togglePinMode() {
        if isPinned {
            // Unpin: close floating window and restore popover
            floatingWindow?.close()
            floatingWindow = nil
            isPinned = false
            togglePopover()
        } else {
            // Pin: close popover and create floating utility panel
            popover?.performClose(nil)
            isPinned = true

            let panel = NSPanel(
                contentRect: NSRect(x: 200, y: 200, width: 360, height: 440),
                styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "CamDial"
            panel.level = .floating
            panel.isFloatingPanel = true
            panel.isMovableByWindowBackground = true
            panel.contentView = NSHostingView(rootView: ContentView(onPinToggle: { [weak self] in
                self?.togglePinMode()
            }))
            panel.center()
            panel.makeKeyAndOrderFront(nil)
            self.floatingWindow = panel
        }
    }
}
