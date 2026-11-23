#!/bin/bash
# Installer for current Lua-based Omarchy. Run as your normal user.
set -euo pipefail
[[ $# == 0 ]] || { echo 'Usage: ./install.sh' >&2; exit 1; }
[[ $EUID != 0 ]] || { echo 'Run as your normal user, not sudo.' >&2; exit 1; }
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ $(cat /sys/class/dmi/id/product_name) == *'MiniBook X'* ]] || { echo 'This installer requires a MiniBook X.' >&2; exit 1; }
for tool in Hyprland hyprctl python3 pacman systemctl limine-mkinitcpio; do command -v "$tool" >/dev/null; done
[[ -f $HOME/.config/hypr/hyprland.lua && -f $HOME/.config/hypr/monitors.lua && -f $HOME/.config/hypr/input.lua ]] || { echo 'Expected an existing Lua-based Omarchy configuration.' >&2; exit 1; }
hyprctl eval 'return true' >/dev/null
hyprctl monitors -j | python3 -c 'import json,sys; assert any(m["name"] == "DSI-1" for m in json.load(sys.stdin)), "DSI-1 display missing"'
errors=$(hyprctl configerrors)
[[ -z $errors ]] || { printf 'Fix existing Hyprland errors first:\n%s\n' "$errors" >&2; exit 1; }
sddm_config="$SCRIPT_DIR/config/sddm"
sddm_dir=/etc/sddm.conf.d
limine_dir=/etc/limine-entry-tool.d
[[ -d $limine_dir ]] || { echo 'Expected an Omarchy Limine installation.' >&2; exit 1; }
if ! grep -Fxq 'CompositorCommand=start-hyprland -- --config /usr/share/sddm/hyprland.lua' "$sddm_dir/10-wayland.conf"; then
  echo 'Expected the Omarchy SDDM Wayland greeter configuration.' >&2
  exit 1
fi
Hyprland --verify-config --config "$sddm_config/hyprland.lua"
missing=()
for package in iio-sensor-proxy python-gobject; do
  if ! pacman -Q "$package" >/dev/null 2>&1; then missing+=("$package"); fi
done
if ((${#missing[@]})); then sudo pacman -S --needed "${missing[@]}"; fi
# SensorProxy supports D-Bus activation; it need not be enabled at boot.
sudo systemctl start iio-sensor-proxy.service
python3 -c 'from gi.repository import GLib, Gio'
backup="$HOME/.local/state/chuwi-minibook-x/backups/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$backup"
export CHUWI_BACKUP="$backup"
python3 "$SCRIPT_DIR/setup-config.py" install
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
for rel in .local/bin/chuwi-minibook-x-rotate .config/systemd/user/chuwi-rotate.service; do
  if [[ -e $HOME/$rel ]]; then
    mkdir -p "$backup/$(dirname "$rel")"
    cp -p "$HOME/$rel" "$backup/$rel"
  fi
done
install -m755 "$SCRIPT_DIR/bin/chuwi-minibook-x-rotate" "$HOME/.local/bin/"
install -m644 "$SCRIPT_DIR/config/systemd/user/chuwi-rotate.service" "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
hyprctl reload
errors=$(hyprctl configerrors)
[[ -z $errors ]] || { printf 'Configuration errors:\n%s\nBackups: %s\nRun ./uninstall.sh to remove our blocks.\n' "$errors" "$backup" >&2; exit 1; }
systemctl --user enable --now chuwi-rotate.service

# Install the compositor config before pointing SDDM at it.
sudo install -m644 "$sddm_config/hyprland.lua" "$sddm_dir/minibook-x.lua"
sudo install -m644 "$sddm_config/99-minibook-x-display.conf" "$sddm_dir/99-minibook-x-display.conf"
# Use the same drop-in names as the manual MiniBook fix.
sudo install -m644 "$SCRIPT_DIR/config/limine/99-minibook-console.conf" "$limine_dir/"
sudo install -m644 "$SCRIPT_DIR/config/limine/99-minibook-panel.conf" "$limine_dir/"
sudo limine-mkinitcpio
printf '\nInstalled. Backups: %s\n' "$backup"
echo 'Save your work and reboot to check the boot splash and login screen.'
