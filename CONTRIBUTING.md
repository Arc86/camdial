# Contributing to CamDial

Thank you for your interest in improving **CamDial**! We welcome bug reports, pull requests, and discussions on expanding webcam compatibility.

---

## 1. Prerequisites

- **Operating System**: macOS 12.0 (Monterey) or later (Apple Silicon or Intel).
- **Tools**: Xcode Command Line Tools (`xcode-select --install`).
- **Hardware**: Any USB Video Class (UVC) compliant external webcam or monitor-integrated camera for hardware verification.

---

## 2. Local Development & Building

The project uses a lightweight `Makefile` without heavy external package managers.

### Build Everything:
```bash
make clean && make all
```

### Build Only the CLI Tool:
```bash
make cli
./build/camdial list
./build/camdial get
```

### Build Only the macOS App:
```bash
make app
open build/CamDial.app
```

### Create a Release Archive:
```bash
make dist
# Outputs build/CamDial-v1.0.0.zip
```

---

## 3. Architecture & Guidelines

Before modifying hardware control logic, please read **[ARCHITECTURE.md](ARCHITECTURE.md)**. Key invariants to keep in mind:

1. **Do Not Seize Interfaces**: Requests should be issued over USB control pipes without seizing interfaces so other video applications (Zoom, Teams, FaceTime) remain uninterrupted.
2. **Protect USB-C Hubs & Monitors**: Never create `IOUSBDeviceUserClient` instances on devices that do not expose a Video interface (`bInterfaceClass == 14`).
3. **Scope Class Descriptors**: Only parse Unit IDs when inside a Video Control interface descriptor (`bInterfaceSubClass == 1`).
4. **Retain Plugin Pointers**: Any `IOCFPlugInInterface` providing a COM interface must remain retained for the lifetime of `UVCDevice` to prevent dangling pointer faults.
5. **Window Geometry Stability**: The GUI window size is locked to `360 × 440` points. Toggling the preview must not balloon the window or push top controls off-screen.

---

## 4. Submitting Changes

1. Fork the repository and create your feature branch: `git checkout -b feature/my-cool-feature`.
2. Verify that both the CLI binary and the macOS App compile cleanly without warnings:
   ```bash
   make clean && make all
   ```
3. Test your changes against connected hardware using `./build/camdial get`.
4. Commit your changes with a descriptive commit message:
   ```bash
   git commit -m "feat(exposure): add support for manual shutter priority mode"
   ```
5. Push to your branch and open a Pull Request.
