//
//  SettingsTabBar.swift
//  WebcamSettings
//
//  Unified icon + label tab bar with a sliding selection highlight
//

import SwiftUI

public enum SettingsTab: Int, CaseIterable, Identifiable {
    case picture, exposure, optics, presets

    public var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .picture: return "Picture"
        case .exposure: return "Exposure"
        case .optics: return "Optics"
        case .presets: return "Presets"
        }
    }

    var icon: String {
        switch self {
        case .picture: return "photo"
        case .exposure: return "sun.max"
        case .optics: return "camera.aperture"
        case .presets: return "rectangle.stack"
        }
    }
}

public struct SettingsTabBar: View {
    @Binding var selection: SettingsTab
    @Namespace private var highlight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(SettingsTab.allCases) { tab in
                let isSelected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))
                            .frame(height: 16)
                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    }
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.accentColor.opacity(0.14))
                                .matchedGeometryEffect(id: "highlight", in: highlight)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        // Animate only the highlight within the bar; a withAnimation around the selection
        // change would also animate the tab content swap and the window resize.
        // Reduce Motion: the highlight jumps instead of sliding.
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selection)
    }
}
