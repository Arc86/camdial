//
//  ControlSliderRow.swift
//  WebcamSettings
//
//  Standard slider row with live numeric readout (click to type a value),
//  reset button, and seamless auto sync
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

    /// Whether the value readout is currently a text field (owned here so a slider drag can close it).
    @State private var isEditingValue = false

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
                    // Dragging supersedes a pending typed value
                    if isEditing { isEditingValue = false }
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

            EditableValueText(
                title: title,
                value: value,
                unit: unit,
                range: range,
                isEnabled: isCapable,
                isAuto: isAutoActive,
                isEditing: $isEditingValue,
                onSubmit: { typed in
                    // Always assign: the view-model setter also switches Auto off,
                    // even when the typed value equals the current auto value
                    value = snap(typed)
                }
            )

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

/// Value readout that turns into a text field when clicked, for typing an exact value.
/// Accepts digits only (and a leading "-" for ranges below zero). Enter or moving focus
/// elsewhere applies it (clamped and snapped by the row); Esc, closing the window or
/// dragging the slider cancels it. An unchanged value is never re-sent.
struct EditableValueText: View {
    let title: String
    let value: Double
    let unit: String
    let range: ClosedRange<Double>
    let isEnabled: Bool
    let isAuto: Bool
    @Binding var isEditing: Bool
    let onSubmit: (Double) -> Void

    @State private var draft = ""
    @State private var originalDraft = ""
    @FocusState private var isFocused: Bool

    private var readout: String {
        // No digit grouping: "5264 K" rather than a locale-dependent "5.264 K"
        "\(Int(value).formatted(.number.grouping(.never)))\(unit.isEmpty ? "" : " " + unit)"
    }

    /// Enough characters for the widest bound, e.g. 5 for 0...10000, 4 for -100...100.
    private var maxLength: Int {
        max(String(Int(range.lowerBound)).count, String(Int(range.upperBound)).count)
    }

    var body: some View {
        Button(action: beginEditing) {
            Text(readout)
                .foregroundStyle(isEnabled ? (isAuto ? Color.accentColor : Color.primary) : Color.secondary)
                .lineLimit(1)
                .fixedSize()
                // Minimum keeps typical values aligned; longer ones ("10000 K") widen instead of truncating
                .frame(minWidth: ControlSliderRow.valueWidth, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help("Click to type a value (\(Int(range.lowerBound))–\(Int(range.upperBound)))")
        .accessibilityLabel(title)
        .accessibilityValue(readout)
        .accessibilityHint("Type an exact value")
        // The readout stays in the layout (just hidden) so the column, and the slider
        // next to it, keep their width while the field is open
        .opacity(isEditing ? 0 : 1)
        .allowsHitTesting(!isEditing)
        .accessibilityHidden(isEditing)
        .overlay(alignment: .trailing) {
            if isEditing {
                field
            }
        }
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        // Closing the popover / panel doesn't move focus inside it, so cancel explicitly
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            if isEditing { isEditing = false }
        }
        .onDisappear { isEditing = false }
    }

    private var field: some View {
        TextField(title, text: $draft)
            .labelsHidden()
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .onChange(of: draft) { text in
                let cleaned = sanitized(text)
                if cleaned != text { draft = cleaned }
            }
            .onSubmit(commit)
            .onExitCommand { isEditing = false }
            .onChange(of: isFocused) { focused in
                if !focused { commit() }
            }
            .onAppear {
                // Focus after the field is in the window; AppKit selects the text on focus
                DispatchQueue.main.async { isFocused = true }
            }
            .padding(.horizontal, 3)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 1)
            }
            .frame(minWidth: ControlSliderRow.valueWidth)
    }

    private func beginEditing() {
        draft = String(Int(value))
        originalDraft = draft
        isEditing = true
    }

    private func commit() {
        guard isEditing else { return }
        isEditing = false
        // Unchanged: don't re-send the value (which would also switch Auto off).
        // Empty or a lone "-" leaves the value unchanged too.
        guard draft != originalDraft, let typed = Int(draft) else { return }
        onSubmit(Double(typed))
    }

    /// Keeps only ASCII digits, plus a leading "-" when the control's range goes below zero,
    /// capped to the length of the widest bound so the number can't overflow.
    private func sanitized(_ text: String) -> String {
        let digits = text.filter { ("0"..."9").contains($0) }
        let sign = range.lowerBound < 0 && text.hasPrefix("-") ? "-" : ""
        return sign + String(digits.prefix(maxLength))
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
        .foregroundStyle(isEnabled ? .primary : .secondary)
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
                .foregroundStyle(isOn ? Color.white : Color.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(isOn ? Color.accentColor : Color.primary.opacity(0.08), in: Capsule())
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
