# Chuwi MiniBook X (N100) Hardware Fix for Omarchy & Hyprland

[![Hardware: Chuwi MiniBook X N100](https://img.shields.io/badge/Hardware-Chuwi%20MiniBook%20X%20(N100)-blue.svg)](#)
[![Compositor: Hyprland](https://img.shields.io/badge/Compositor-Hyprland-brightgreen.svg)](#)
[![OS: Omarchy / Arch Linux](https://img.shields.io/badge/OS-Omarchy%20%2F%20Arch%20Linux-1793d1.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A clean, standalone, zero-bloat hardware fix for the **Chuwi MiniBook X (Intel N100)** 2-in-1 laptop running **[Omarchy](https://omarchy.org/)** or **Hyprland** on Arch Linux.

This repository contains **strictly hardware-specific fixes** (display, touchscreen, and 360° sensor auto-rotation). It contains no personal dotfiles, no custom themes, and no language or keyboard layout overrides.

---

## 🎯 The Problem

Out of the box on Linux, the Chuwi MiniBook X (N100) has several hardware quirks:

1. **Sideways Display**: The internal panel (`DSI-1`, 1200x1920) is physically mounted as a native portrait tablet panel. On first boot, the desktop and login screen appear rotated 90° sideways.
2. **Unaligned Touchscreen**: The Goodix capacitive touchscreen does not align with the display once rotated, causing touch inputs to register along incorrect axes.
3. **No Automatic Rotation**: The built-in `mxc4005` accelerometer is recognized by the kernel, but Hyprland has no built-in auto-rotation daemon, so folding the laptop into tablet or tent mode does not rotate the screen.
4. **Sideways SDDM / Boot Console**: The SDDM login greeter and early boot console default to portrait orientation.

---

## 🛠️ What This Fix Provides

- **Display Rotation (`DSI-1`)**: Configures the internal display to standard landscape mode (`transform = 3`).
- **Touchscreen Calibration**: Correctly binds `goodix-capacitive-touchscreen-1` to `DSI-1` with matching `transform = 3` so touches match the visual coordinates precisely.
- **Dynamic Auto-Rotation Daemon**: A lightweight background service listening to `iio-sensor-proxy` via system D-Bus. Automatically rotates **both screen and touch** seamlessly across all 4 orientations:
  - Standard laptop mode (landscape)
  - Standing portrait mode (tablet)
  - Tent mode (inverted landscape)
  - Inverted portrait mode
- **(Optional) SDDM & Boot Console Tweaks**: Fixes orientation on the SDDM Wayland greeter and adds the kernel console framebuffer rotation quirk.

---

## 🚀 Quick Install

Run the following commands on your Chuwi MiniBook X in Omarchy / Hyprland:

```bash
git clone https://github.com/Dessection/omarchy-chuwi-minibook-x.git
cd omarchy-chuwi-minibook-x
./install.sh
```

To automatically apply the optional SDDM and Limine bootloader fixes as well:

```bash
./install.sh --with-root
```

The script will:
1. Detect your hardware model.
2. Ensure required dependencies (`iio-sensor-proxy`, `python-gobject`) are installed.
3. Install and enable the `chuwi-rotate.service` user systemd service.
4. Add non-destructive display and touch device configurations to `~/.config/hypr/`.
5. Immediately rotate your active screen and touch input without needing a reboot.

---

## 📂 Repository Structure

```text
omarchy-chuwi-minibook-x/
├── bin/
│   └── chuwi-minibook-x-rotate       # Accelerometer listener & dynamic rotation daemon
├── config/
│   ├── hypr/
│   │   ├── monitors.lua              # Hyprland monitor rotation configuration (Omarchy Lua)
│   │   └── input-touch.lua           # Touchscreen device mapping (Omarchy Lua)
│   ├── systemd/
│   │   └── user/
│   │       └── chuwi-rotate.service  # Systemd user service unit for auto-rotation
│   ├── sddm/
│   │   └── hyprland.lua              # SDDM Wayland greeter orientation fix
│   └── limine/
│       └── chuwi-minibook-x.conf     # Kernel cmdline rotation parameter for Limine
├── install.sh                        # Automated setup script
├── uninstall.sh                      # Revert all changes
├── LICENSE                           # MIT License
└── README.md                         # Documentation
```

---

## 🗑️ Uninstallation

To remove the background service and daemon:

```bash
./uninstall.sh
```

---

## 📄 License

Released under the [MIT License](LICENSE).
