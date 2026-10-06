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
    @State private var contentHeight: CGFloat = 0
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        // A single ScrollView sized to the measured content keeps one stable view
        // identity, so controls aren't rebuilt (losing focus or an in-flight slider
        // drag) when the content crosses the height limit.
        ScrollView {
            VStack(spacing: 10) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .top)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
                }
            )
        }
        .frame(height: min(contentHeight, maxHeight))
        .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
