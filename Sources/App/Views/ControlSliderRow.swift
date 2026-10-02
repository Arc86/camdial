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

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isCapable ? .primary : .secondary)

                Spacer()

                if let auto = autoBinding {
                    Toggle("Auto", isOn: auto)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                        .help("Toggle automatic adjustment")
                    Text("Auto")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isAutoActive ? .accentColor : .secondary)
                }

                HStack(spacing: 3) {
                    Text("\(Int(value))\(unit.isEmpty ? "" : " " + unit)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(isCapable ? (isAutoActive ? .accentColor : .primary) : .secondary)

                    if isAutoActive {
                        Text("(Auto)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(minWidth: 54, alignment: .trailing)

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

            Slider(
                value: $value,
                in: range,
                step: step,
                onEditingChanged: { isEditing in
                    CameraViewModel.shared.isUserDragging = isEditing
                    if isEditing && isAutoActive {
                        autoBinding?.wrappedValue = false
                    }
                }
            )
            .onChange(of: value) { _ in
                onCommit()
            }
            .disabled(!isCapable)
            .opacity(isCapable ? 1.0 : 0.4)
        }
        .padding(.vertical, 4)
    }
}
