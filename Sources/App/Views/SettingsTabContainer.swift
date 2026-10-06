//
//  SettingsTabContainer.swift
//  WebcamSettings
//
//  Tab content wrapper: sizes to its controls, and only scrolls when they
//  exceed the maximum height that ContentView allows for tab content
//

import SwiftUI

public struct SettingsTabContainer<Content: View>: View {
    @Environment(\.settingsContentMaxHeight) private var maxHeight
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        // A ScrollView's ideal height is its content's height, so the window sizes to the
        // controls and only starts scrolling once they exceed maxHeight. No measurement
        // round-trip (which briefly collapsed the window on every tab switch), and one
        // stable view identity so controls aren't rebuilt at the limit.
        ScrollView {
            VStack(spacing: 10) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxHeight: maxHeight)
    }
}

private struct SettingsContentMaxHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 440
}

extension EnvironmentValues {
    /// Tallest the tab content may get before it scrolls instead of growing the window.
    var settingsContentMaxHeight: CGFloat {
        get { self[SettingsContentMaxHeightKey.self] }
        set { self[SettingsContentMaxHeightKey.self] = newValue }
    }
}
