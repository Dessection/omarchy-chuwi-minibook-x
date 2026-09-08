# Chuwi MiniBook X (N100) Hardware Fix for Omarchy & Hyprland

[![Hardware: Chuwi MiniBook X N100](https://img.shields.io/badge/Hardware-Chuwi%20MiniBook%20X%20(N100)-blue.svg)](#)
[![Compositor: Hyprland](https://img.shields.io/badge/Compositor-Hyprland-brightgreen.svg)](#)
[![OS: Omarchy / Arch Linux](https://img.shields.io/badge/OS-Omarchy%20%2F%20Arch%20Linux-1793d1.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A clean, standalone, zero-bloat hardware fix for the **Chuwi MiniBook X (Intel N100)** 2-in-1 convertible laptop running **[Omarchy](https://omarchy.org/)** or **Hyprland** on Arch Linux.

This repository contains **strictly hardware-specific fixes** (display orientation, touchscreen calibration, and 360° sensor auto-rotation). It contains no personal dotfiles, no custom themes, and no language or keyboard layout overrides.

---

## 💻 Supported Hardware

| Component | Hardware Details | Linux Identifier / Driver |
| :--- | :--- | :--- |
| **Device Model** | Chuwi MiniBook X (2-in-1 Convertible) | `MiniBook X` |
| **Processor** | Intel Processor N100 (Alder Lake-N) | `x86_64` |
| **Display** | 10.51" 1200×1920 (Native Portrait) | `DSI-1` |
| **Touchscreen** | Goodix Capacitive Digitizer | `goodix-capacitive-touchscreen-1` |
| **Orientation Sensor** | MEMS Accelerometer | `mxc4005` (via `iio-sensor-proxy`) |

---

## 🎯 The Problem

Out of the box on Linux / Arch / Omarchy, the Chuwi MiniBook X (N100) encounters several hardware quirks:

1. **Sideways Display**: The internal panel (`DSI-1`) is manufactured for tablets in a native portrait orientation. On first boot, the desktop, login screen, and bootloader appear rotated 90° sideways.
2. **Unaligned Touchscreen**: The Goodix capacitive touchscreen does not align with the display once rotated, causing touch inputs to register along inverted axes (e.g., tapping the top-right registers on the bottom-right).
3. **No Automatic 360° Rotation**: The onboard `mxc4005` accelerometer provides raw sensor data to the Linux kernel, but Hyprland has no built-in auto-rotation daemon. Folding the laptop into tablet or tent mode does not rotate the display or touch coordinates.
4. **Sideways SDDM / Boot Console**: The SDDM Wayland greeter and framebuffer console start in portrait mode.

---

## 🛠️ What This Fix Provides

- **Display Rotation (`DSI-1`)**: Configures the internal display to standard landscape mode (`transform = 3`).
- **Touchscreen Calibration**: Correctly binds `goodix-capacitive-touchscreen-1` to `DSI-1` with matching `transform = 3` so touches match the visual coordinates precisely.
- **Dynamic Auto-Rotation Daemon**: A lightweight background service listening to `iio-sensor-proxy` via system D-Bus. Automatically rotates **both screen and touch** seamlessly across all 4 orientations:
  - **Standard Laptop**: Landscape mode (keyboard down)
  - **Standing Tablet**: Portrait mode
  - **Tent Mode**: Inverted landscape
  - **Inverted Tablet**: Inverted portrait
- **(Optional) SDDM & Boot Console Tweaks**: Fixes orientation on the SDDM Wayland greeter and adds the kernel console framebuffer rotation quirk (`video=DSI-1:panel_orientation=right_side_up fbcon=rotate:1`).

---

## 🚀 Quick Install

Open a terminal on your Chuwi MiniBook X running Omarchy or Hyprland:

```bash
git clone https://github.com/Dessection/omarchy-chuwi-minibook-x.git
cd omarchy-chuwi-minibook-x
./install.sh
```

### Optional: Apply SDDM and Bootloader Console Fixes

To include the SDDM login screen and Limine boot console rotation quirks, run:

```bash
./install.sh --with-root
```

### What the installer does:
1. Verifies hardware compatibility via DMI table.
2. Installs required packages (`iio-sensor-proxy`, `python-gobject`) if not already present.
3. Installs and enables the `chuwi-rotate.service` user systemd service.
4. Non-destructively adds display and touch device configurations to `~/.config/hypr/`.
5. Immediately applies landscape rotation to your active Hyprland session without requiring a reboot.

---

## 🔍 Verification & Diagnostics

Once installed, you can verify the status of each hardware component:

### 1. Test Accelerometer Readings
Run `monitor-sensor` in a terminal and rotate the laptop:
```bash
monitor-sensor
```
*Expected output:* You should see real-time updates reporting `Accelerometer orientation changed: right-up`, `normal`, `bottom-up`, etc.

### 2. Check the Auto-Rotate Service Status
```bash
systemctl --user status chuwi-rotate.service
```

### 3. Verify Display and Touch Alignment
```bash
hyprctl monitors
hyprctl devices
```
*Expected output:* `DSI-1` should report `transform: 3`, and `goodix-capacitive-touchscreen-1` should be assigned to `DSI-1`.

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
├── uninstall.sh                      # Clean uninstaller
├── LICENSE                           # MIT License
└── README.md                         # Documentation
```

---

## 🗑️ Uninstallation

To disable the auto-rotation daemon and remove user services:

```bash
./uninstall.sh
```

---

## 🇳🇴 Kort oppsummering på norsk

Dette depotet løser fabrikk-særegenhetene til Chuwi MiniBook X (N100) på Linux/Omarchy:
* Skjermen er fra fabrikken et stående nettbrettpanel som havner 90° sidelengs ved oppstart.
* Berøringsskjermen (touch) bommer på trykkpunktene inntil den roteres sammen med bildet.
* Maskinens 360°-akselerometer mangler lytter i Hyprland.

Kjør `./install.sh`, så blir skjerm, touch og automatisk sensor-rotasjon satt opp umiddelbart uten at personlige innstillinger eller språk overstyres.

---

## 📄 License

Released under the [MIT License](LICENSE).
