//
//  ControlSliderRow.swift
//  WebcamSettings
//
//  Standard slider row with live numeric readout, reset button, and seamless auto sync
//

import SwiftUI

public struct ControlSliderRow: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let defaultValue: Double
    let isCapable: Bool
    var autoBinding: Binding<Bool>?
    let onCommit: () -> Void

    public init(title: String,
                icon: String,
                value: Binding<Double>,
                range: ClosedRange<Double>,
                step: Double = 1.0,
                unit: String = "",
                defaultValue: Double,
                isCapable: Bool = true,
                autoBinding: Binding<Bool>? = nil,
                onCommit: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.defaultValue = defaultValue
        self.isCapable = isCapable
        self.autoBinding = autoBinding
        self.onCommit = onCommit
    }

    private var isAutoActive: Bool {
        return autoBinding?.wrappedValue ?? false
    }

    /// Shared column widths so labels, values and reset buttons line up across rows.
    static let labelWidth: CGFloat = 108
    static let valueWidth: CGFloat = 42

    public var body: some View {
        HStack(spacing: 6) {
            SettingRowLabel(title: title, icon: icon, isEnabled: isCapable)

            // Snap via the binding instead of `step:` — on macOS a stepped Slider draws
            // one tick mark per step, which renders as a dense dashed bar for UVC ranges.
            Slider(
                value: Binding(
                    get: { value },
                    set: { newValue in
                        let snapped = snap(newValue)
                        if snapped != value { value = snapped }
                    }
                ),
                in: range,
                onEditingChanged: { isEditing in
                    CameraViewModel.shared.isUserDragging = isEditing
                    if isEditing && isAutoActive {
                        autoBinding?.wrappedValue = false
                    }
                }
            )
            .controlSize(.small)
            .onChange(of: value) { _ in
                onCommit()
            }
            .disabled(!isCapable)
            .opacity(isCapable ? 1.0 : 0.4)

            if let auto = autoBinding {
                AutoPill(isOn: auto)
            }

            // No digit grouping: "5264 K" rather than a locale-dependent "5.264 K"
            Text("\(Int(value), format: .number.grouping(.never))\(unit.isEmpty ? "" : " " + unit)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(isCapable ? (isAutoActive ? .accentColor : .primary) : .secondary)
                .lineLimit(1)
                .fixedSize()
                // Minimum keeps typical values aligned; longer ones ("10000 K") widen instead of truncating
                .frame(minWidth: Self.valueWidth, alignment: .trailing)

            Button(action: {
                if isAutoActive {
                    autoBinding?.wrappedValue = false
                }
                value = defaultValue
                onCommit()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10))
            }
            .buttonStyle(.borderless)
            .disabled(!isCapable || (value == defaultValue && !isAutoActive))
            .help("Reset to default (\(Int(defaultValue)))")
        }
        .padding(.vertical, 2)
    }

    private func snap(_ raw: Double) -> Double {
        guard step > 0 else { return raw }
        let stepped = range.lowerBound + ((raw - range.lowerBound) / step).rounded() * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}

/// Icon + title column shared by all setting rows.
struct SettingRowLabel: View {
    let title: String
    let icon: String
    var isEnabled: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 16)
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(isEnabled ? .primary : .secondary)
        .frame(width: ControlSliderRow.labelWidth, alignment: .leading)
    }
}

/// Compact "Auto" switch: filled accent when on, so the state reads at a glance.
struct AutoPill: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Text("Auto")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isOn ? .white : .secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(isOn ? Color.accentColor : Color.primary.opacity(0.08)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(isOn ? "Automatic adjustment on — click for manual control" : "Turn on automatic adjustment")
        // Expose it to VoiceOver / keyboard access as a real on/off switch, not a button
        .accessibilityRepresentation {
            Toggle("Auto", isOn: $isOn)
        }
    }
}
