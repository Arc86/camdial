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
        IdealHeightCap(maxHeight: maxHeight) {
            ScrollView {
                VStack(spacing: 10) {
                    content
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
}

/// Sizes its child to min(ideal height, maxHeight), shrinking further only if offered less
/// (e.g. mid-way through the window's resize animation), but never growing past its ideal.
/// A plain `.frame(maxHeight:)` would grab any slack, leaving empty space under the controls.
private struct IdealHeightCap: Layout {
    var maxHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let ideal = child.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        let height = min(ideal.height, maxHeight, proposal.height ?? .infinity)
        return CGSize(width: proposal.width ?? ideal.width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
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
