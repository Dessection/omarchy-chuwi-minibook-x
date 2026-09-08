#!/bin/bash
# ====================================================================
# Chuwi MiniBook X (N100) Hardware Support Installer for Omarchy / Hyprland
#
# Fixes:
# 1. Native portrait DSI-1 panel orientation (rotates to landscape)
# 2. Goodix touchscreen coordinate mapping and rotation
# 3. Accelerometer-driven auto-rotation for 360° tablet/tent modes
# 4. (Optional) SDDM Wayland greeter and Limine bootloader orientation
# ====================================================================

set -e

# Color helpers
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}====================================================================${RESET}"
echo -e "${BOLD} Chuwi MiniBook X (N100) Hardware Setup for Omarchy / Hyprland${RESET}"
echo -e "${CYAN}====================================================================${RESET}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Hardware check
echo -e "\n${BOLD}[1/5] Checking hardware...${RESET}"
PRODUCT_NAME="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
SYS_VENDOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo 'Unknown')"
echo "Detected hardware: $SYS_VENDOR - $PRODUCT_NAME"

if [[ "$PRODUCT_NAME" != *"MiniBook X"* ]]; then
  echo -e "${YELLOW}Warning: This machine does not identify as 'MiniBook X'. Proceeding anyway...${RESET}"
fi

# 2. Install required packages
echo -e "\n${BOLD}[2/5] Checking dependencies...${RESET}"
PACKAGES_TO_INSTALL=()

if ! pacman -Q iio-sensor-proxy &>/dev/null; then
  PACKAGES_TO_INSTALL+=("iio-sensor-proxy")
fi

if ! pacman -Q python-gobject &>/dev/null; then
  PACKAGES_TO_INSTALL+=("python-gobject")
fi

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
  echo "Installing missing dependencies: ${PACKAGES_TO_INSTALL[*]}"
  sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}"
else
  echo -e "${GREEN}All required dependencies already installed (iio-sensor-proxy, python-gobject).${RESET}"
fi

# Ensure iio-sensor-proxy service is enabled and running
if command -v systemctl &>/dev/null; then
  sudo systemctl enable --now iio-sensor-proxy.service 2>/dev/null || true
fi

# 3. Install Auto-Rotate Daemon & Systemd Service
echo -e "\n${BOLD}[3/5] Installing auto-rotation daemon...${RESET}"
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/bin/chuwi-minibook-x-rotate" "$HOME/.local/bin/chuwi-minibook-x-rotate"
chmod +x "$HOME/.local/bin/chuwi-minibook-x-rotate"

mkdir -p "$HOME/.config/systemd/user"
cp "$SCRIPT_DIR/config/systemd/user/chuwi-rotate.service" "$HOME/.config/systemd/user/chuwi-rotate.service"

systemctl --user daemon-reload
systemctl --user enable --now chuwi-rotate.service 2>/dev/null || true
echo -e "${GREEN}Auto-rotation service installed and started.${RESET}"

# 4. Configure Hyprland (Display & Touchscreen)
echo -e "\n${BOLD}[4/5] Configuring Hyprland display and touchscreen...${RESET}"
mkdir -p "$HOME/.config/hypr"

# Configure monitors.lua
MONITORS_FILE="$HOME/.config/hypr/monitors.lua"
if [ -f "$MONITORS_FILE" ]; then
  if ! grep -q "DSI-1" "$MONITORS_FILE"; then
    echo "Adding DSI-1 monitor orientation to $MONITORS_FILE..."
    cp "$MONITORS_FILE" "${MONITORS_FILE}.bak.$(date +%s)"
    printf '\n-- Chuwi MiniBook X internal display (native portrait panel rotated to landscape)\nhl.monitor({ output = "DSI-1", mode = "preferred", position = "0x0", scale = 1, transform = 3 })\n' >> "$MONITORS_FILE"
  else
    echo "DSI-1 monitor config already present in $MONITORS_FILE."
  fi
else
  echo "Creating $MONITORS_FILE..."
  cp "$SCRIPT_DIR/config/hypr/monitors.lua" "$MONITORS_FILE"
fi

# Configure input.lua (Touchscreen mapping)
INPUT_FILE="$HOME/.config/hypr/input.lua"
if [ -f "$INPUT_FILE" ]; then
  if ! grep -q "goodix-capacitive-touchscreen-1" "$INPUT_FILE"; then
    echo "Adding touchscreen device mapping to $INPUT_FILE..."
    cp "$INPUT_FILE" "${INPUT_FILE}.bak.$(date +%s)"
    printf '\n-- Chuwi MiniBook X touchscreen mapping\nhl.device({\n  name = "goodix-capacitive-touchscreen-1",\n  output = "DSI-1",\n  transform = 3,\n})\n' >> "$INPUT_FILE"
  else
    echo "Touchscreen config already present in $INPUT_FILE."
  fi
else
  echo "Creating $INPUT_FILE..."
  cp "$SCRIPT_DIR/config/hypr/input-touch.lua" "$INPUT_FILE"
fi

# Apply immediate rotation to active Hyprland session
if command -v hyprctl &>/dev/null; then
  echo "Applying rotation to active session..."
  hyprctl eval 'hl.monitor({ output = "DSI-1", transform = 3, scale = 1 })' 2>/dev/null || true
  hyprctl eval 'hl.device({ name = "goodix-capacitive-touchscreen-1", output = "DSI-1", transform = 3 })' 2>/dev/null || true
  hyprctl keyword monitor "DSI-1,preferred,auto,1,transform,3" 2>/dev/null || true
fi

# 5. Optional System-Level Tweaks (SDDM & Limine)
echo -e "\n${BOLD}[5/5] System-level tweaks (SDDM & Limine bootloader)...${RESET}"
APPLY_ROOT=false
if [[ "$1" == "--with-root" || "$1" == "-y" ]]; then
  APPLY_ROOT=true
elif [ -t 0 ]; then
  read -r -p "Do you want to configure SDDM greeter and Limine bootloader rotation? (Requires sudo) [y/N]: " RESP
  if [[ "$RESP" =~ ^[Yy]$ ]]; then
    APPLY_ROOT=true
  fi
fi

if [ "$APPLY_ROOT" = true ]; then
  if [ -d "/etc/sddm" ]; then
    echo "Installing SDDM greeter config to /etc/sddm/hyprland.lua..."
    sudo cp "$SCRIPT_DIR/config/sddm/hyprland.lua" "/etc/sddm/hyprland.lua"
  fi

  if [ -d "/etc/limine-entry-tool.d" ]; then
    echo "Installing Limine kernel parameter quirk..."
    sudo cp "$SCRIPT_DIR/config/limine/chuwi-minibook-x.conf" "/etc/limine-entry-tool.d/chuwi-minibook-x.conf"
    if command -v limine-entry-tool &>/dev/null; then
      sudo limine-entry-tool || true
    fi
  fi
  echo -e "${GREEN}System tweaks installed!${RESET}"
else
  echo "Skipped system tweaks. You can manually install them from config/sddm and config/limine if desired."
fi

echo -e "\n${GREEN}====================================================================${RESET}"
echo -e "${GREEN}✓ Chuwi MiniBook X hardware setup completed successfully!${RESET}"
echo -e "Screen, touch, and accelerometer auto-rotation are now fully active."
echo -e "${GREEN}====================================================================${RESET}\n"
