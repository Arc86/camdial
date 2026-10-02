# CamDial

[![CI](https://github.com/willem/camdial/actions/workflows/ci.yml/badge.svg)](https://github.com/willem/camdial/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2012%2B-blue.svg)](https://apple.com/macos)
[![Swift: 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)

**CamDial** is a native macOS hardware controller and CLI utility for external USB webcams and monitor-integrated cameras.

It speaks directly to the hardware registers of your webcam using the **USB Video Class (UVC 1.1 / 1.5)** protocol over Apple's IOKit framework. Adjustments are applied directly onto the camera sensor and persist across **all** macOS video apps (Zoom, Microsoft Teams, Google Meet, FaceTime, QuickTime, OBS Studio, Discord, etc.) without freezing or seizing active video calls.

---

## Why CamDial Was Built: The Monitor Webcam Dilemma

Many modern monitors—such as the **Samsung ViewFinity S6** (and other displays with integrated or pop-up webcams)—come with very capable hardware sensors. However, macOS provides **zero native controls** to fine-tune external camera picture settings. 

Out of the box, the default lighting, contrast, and color temperature are often poor:
- Faces appear in deep shadow or harsh window glare.
- Auto-exposure frequently overcompensates or blows out highlights.
- The default color tint is often overly cool or muddy.

Because macOS lacks native hardware sliders for external webcams, you are typically left with no way to adjust your picture—or forced to install heavy virtual camera software that drains battery and degrades video fidelity.

**CamDial was built to solve this exact problem.** It dials straight into the camera sensor's hardware registers with zero overhead, giving you true hardware control right from your menu bar or terminal.

---

## Features

- **Picture & Color Controls**:
  - **Brightness**: Sensor black-level offset
  - **Contrast**: Contrast gain curve
  - **Saturation**: Color vibrance and saturation
  - **Sharpness**: Edge filtering
  - **White Balance**: Auto White Balance toggle + Manual Color Temperature in Kelvin (2,800 K – 7,500 K)
  - **Hue & Gamma**: Color tint and midtone luminance curves (if supported by hardware)
  - **Backlight Compensation**: Enhances subject exposure in high-backlight scenes
- **Lighting & Exposure Controls**:
  - **Auto Exposure**: Toggle between automatic and full manual exposure
  - **Shutter / Exposure Time**: Precise sensor integration time control
  - **Sensor Gain**: Analog/digital ISO sensitivity
  - **Anti-Flicker / Power Line Frequency**: Disabled, 50 Hz (Europe, Asia, Africa, AU), 60 Hz (Americas, Japan)
- **Focus & Framing**:
  - **Auto Focus**: Toggle hardware autofocus on/off
  - **Manual Focus**: Fine-tune focal distance
  - **Zoom**: Optical / digital zoom factor (if supported by camera)
- **Live Video Preview**:
  - Embedded real-time video preview right inside the app
  - Compact 16:9 frame that animates smoothly in place without shifting the window frame
- **Live Auto-Tracking Sliders**:
  - Sliders dynamically track the camera's internal auto-adjusted values (White Balance Kelvin, Shutter Time, Gain, Focus) in real-time.
  - Moving any slider smoothly disengages auto mode and applies your custom setting immediately.
- **Instant Profiles & Presets (1-Click Switch, No Apply Button Needed)**:
  - Built-in profiles:
    - **Side Light / Window Compensation**: Specially tuned for harsh single-direction sunlight; lifts deep shadows, softens contrast, enables backlight compensation, and balances daylight kelvin.
    - **Natural Daylight**: Crisp 5500K neutral daylight look.
    - **Warm Studio**: 3400K cozy amber tone.
    - **Night / Low Light**: Maximum shadow lifting & sensitivity.
    - **Vibrant & Crisp**: Rich saturation & high contrast.
    - **Black & White**: Monochrome profile.
    - **Factory Default**: Instant camera hardware reset.
  - Create and save custom named profiles with 1-click switching.
  - **Auto-Restore**: Remembers your preferred settings for each webcam model and automatically re-applies them whenever the camera is plugged in or on app launch!
- **Dual Interface**:
  - **Menu Bar App (`CamDial.app`)**: Sits unobtrusively in your macOS menu bar with a quick popover, plus a **Pin** button to keep controls floating on top while on a call.
  - **Command-Line Interface (`camdial`)**: Standalone CLI for scripts, terminal control, Raycast/Alfred extensions, and Elgato Stream Deck automations.

---

## Compatibility

- **Monitor-Integrated Webcams**:
  - Samsung ViewFinity S6 (S65VC series)
  - Dell UltraSharp & Video Conferencing monitors
  - LG UltraFine & integrated display webcams
- **External USB Webcams**:
  - Logitech (C920, C922, C930e, Brio 4K, StreamCam, MX Brio, etc.)
  - Elgato (Facecam, Facecam Pro, Cam Link)
  - Razer (Kiyo, Kiyo Pro)
  - Anker (PowerConf C200, C300)
  - OBSbot (Tiny, Meet)
  - Insta360 Link, AverMedia, and all generic UVC plug-and-play webcams.
- **Built-in & Continuity Cameras**: Automatically detected through AVFoundation with live preview and software control.

---

## Quick Start

### 1. Launch the GUI App
```bash
open build/CamDial.app
```
Look for the camera icon in your macOS menu bar at the top right of your screen. Click it to open the controls!
- Click the **pin icon** in the top-right of the popover to detach it into a floating window that stays visible over your meeting window.
- Click the **video preview icon** to toggle the live camera feed without shifting the window frame.

### 2. Using the CLI (`camdial`)

#### List all detected webcams:
```bash
./build/camdial list
```

#### Read current hardware values and ranges:
```bash
./build/camdial get
```

#### Adjust camera settings:
```bash
# Set brightness and saturation
./build/camdial set --brightness 130 --saturation 140

# Turn off auto white balance and set color temperature to 5000K
./build/camdial set --white-balance-auto false --white-balance 5000

# Set manual exposure and sensor gain
./build/camdial set --exposure-auto false --exposure 156 --gain 35

# Set anti-flicker to 50Hz (European powerline)
./build/camdial set --anti-flicker 50
```

#### Apply a preset:
```bash
./build/camdial preset apply "Side Light / Window Compensation"
./build/camdial preset apply "Natural Daylight"
```

#### Reset camera to hardware factory defaults:
```bash
./build/camdial reset
```

---

## Building from Source

Requirements: macOS 12+ (Apple Silicon or Intel), Xcode Command Line Tools.

```bash
# Build both CLI binary and GUI app:
make all

# Build individually:
make cli
make app

# Package release zip:
make dist

# Install CLI system-wide:
make install-cli
```

---

## Architecture & Contributing

For low-level hardware implementation details, descriptor parsing notes, and developer guides, see:
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Deep dive into the IOKit UVC engine, COM plugin memory management, descriptor scoping, and auto-tracking loops.
- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Pull request workflow, coding standards, and hardware verification checklist.
- **[PLAN.md](PLAN.md)**: Original project specification and roadmap.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
