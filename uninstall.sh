#!/bin/bash
set -euo pipefail
[[ $EUID != 0 ]] || { echo 'Run as your normal user.' >&2; exit 1; }
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
systemctl --user disable --now chuwi-rotate.service
rm -f "$HOME/.config/systemd/user/chuwi-rotate.service" "$HOME/.local/bin/chuwi-minibook-x-rotate"
systemctl --user daemon-reload
python3 "$SCRIPT_DIR/setup-config.py" uninstall
hyprctl reload
errors=$(hyprctl configerrors)
[[ -z $errors ]] || { printf '%s\n' "$errors" >&2; exit 1; }
sddm_dir=/etc/sddm.conf.d
if [[ -f $sddm_dir/99-minibook-x-display.conf ]]; then
  sudo rm -f -- "$sddm_dir/99-minibook-x-display.conf" "$sddm_dir/minibook-x.lua"
fi
limine_dir=/etc/limine-entry-tool.d
if [[ -d $limine_dir ]]; then
  sudo rm -f -- "$limine_dir/99-minibook-console.conf" "$limine_dir/99-minibook-panel.conf"
  sudo limine-mkinitcpio
fi
echo 'Removed the desktop, login screen, and boot rotation settings. Reboot to apply.'
