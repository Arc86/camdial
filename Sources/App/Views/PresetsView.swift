//
//  PresetsView.swift
//  WebcamSettings
//
//  Instant preset switching, custom profiles, and factory reset
//

import SwiftUI

public struct PresetsView: View {
    @ObservedObject var vm = CameraViewModel.shared
    @State private var presets = PresetManager.shared.presets
    @State private var newPresetName: String = ""
    @State private var showingSaveSheet = false
    @State private var activePresetName: String = "Factory Default"

    public init(device: CameraDevice? = nil) {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Top controls: Profile Menu & Save Custom
                HStack(spacing: 8) {
                    Picker("", selection: Binding(
                        get: { activePresetName },
                        set: { newName in
                            selectAndApplyPreset(named: newName)
                        }
                    )) {
                        ForEach(presets) { preset in
                            Text(preset.name).tag(preset.name)
                        }
                    }
                    .pickerStyle(.menu)

                    Button(action: { showingSaveSheet.toggle() }) {
                        Label("Save As...", systemImage: "plus.square")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if let current = presets.first(where: { $0.name == activePresetName }), !current.isBuiltIn {
                        Button(action: deleteActivePreset) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("Delete custom profile")
                    }
                }

                // Inline Save Drawer
                if showingSaveSheet {
                    HStack(spacing: 6) {
                        TextField("Profile Name (e.g. Window Sunny)", text: $newPresetName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))

                        Button("Cancel") {
                            showingSaveSheet = false
                            newPresetName = ""
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("Save") {
                            saveCurrentPreset()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(newPresetName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }

                Divider().padding(.vertical, 2)

                // Instant Preset Cards (1-Click Switch)
                VStack(spacing: 6) {
                    ForEach(presets) { preset in
                        PresetRowButton(
                            preset: preset,
                            isSelected: activePresetName == preset.name,
                            action: {
                                selectAndApplyPreset(named: preset.name)
                            }
                        )
                    }
                }

                Divider().padding(.vertical, 4)

                // Quick Hardware Reset Button
                Button(action: {
                    activePresetName = "Factory Default"
                    vm.resetToDefaults()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset All to Camera Factory Defaults")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
        }
        .onAppear {
            presets = PresetManager.shared.presets
        }
    }

    private func selectAndApplyPreset(named name: String) {
        guard let preset = presets.first(where: { $0.name == name }) else { return }
        activePresetName = name
        vm.applyPreset(preset)
    }

    private func saveCurrentPreset() {
        let trimmed = newPresetName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let uvc = vm.activeDevice?.uvcDevice else { return }

        var vals: [String: Int] = [:]
        var bools: [String: Bool] = [:]

        let dump = uvc.dumpSettings()
        for (k, v) in dump {
            if let i = v as? Int {
                vals[k] = i
            } else if let b = v as? Bool {
                bools[k] = b
            }
        }

        PresetManager.shared.saveCustomPreset(name: trimmed, values: vals, booleans: bools)
        presets = PresetManager.shared.presets
        activePresetName = trimmed
        showingSaveSheet = false
        newPresetName = ""
    }

    private func deleteActivePreset() {
        PresetManager.shared.deletePreset(named: activePresetName)
        presets = PresetManager.shared.presets
        let fallback = presets.first?.name ?? "Factory Default"
        selectAndApplyPreset(named: fallback)
    }
}

// MARK: - Preset Item Row Component

struct PresetRowButton: View {
    let preset: CameraPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: iconForPreset(preset.name))
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.primary)

                    Text(descriptionForPreset(preset.name))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 13))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func iconForPreset(_ name: String) -> String {
        switch name {
        case "Side Light / Window Compensation":
            return "sun.and.horizon"
        case "Natural Daylight":
            return "sun.max"
        case "Warm Studio":
            return "lamp.desk"
        case "Night / Low Light":
            return "moon.stars"
        case "Vibrant & Crisp":
            return "sparkles"
        case "Black & White":
            return "camera.filters"
        case "Factory Default":
            return "arrow.counterclockwise"
        default:
            return "slider.horizontal.3"
        }
    }

    private func descriptionForPreset(_ name: String) -> String {
        switch name {
        case "Side Light / Window Compensation":
            return "Lifts shadows & softens contrast for harsh window light"
        case "Natural Daylight":
            return "Cool 5500K neutral daylight balance"
        case "Warm Studio":
            return "Cozy 3400K amber studio tone"
        case "Night / Low Light":
            return "Brightened exposure & high sensitivity"
        case "Vibrant & Crisp":
            return "Enhanced color saturation & crisp focus"
        case "Black & White":
            return "Monochrome high-contrast profile"
        case "Factory Default":
            return "Camera hardware factory defaults"
        default:
            return "Custom user profile"
        }
    }
}
