#!/bin/bash
# ====================================================================
# Chuwi MiniBook X Hardware Setup Uninstaller
# ====================================================================

set -e

echo "Removing Chuwi MiniBook X auto-rotation daemon and services..."

# Stop and disable systemd user service
if systemctl --user is-active chuwi-rotate.service &>/dev/null; then
  systemctl --user stop chuwi-rotate.service || true
fi
systemctl --user disable chuwi-rotate.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/chuwi-rotate.service"
systemctl --user daemon-reload

# Remove binary
rm -f "$HOME/.local/bin/chuwi-minibook-x-rotate"

echo "Reverting system tweaks (if present, requires sudo)..."
if [ -f "/etc/limine-entry-tool.d/chuwi-minibook-x.conf" ]; then
  sudo rm -f "/etc/limine-entry-tool.d/chuwi-minibook-x.conf"
  if command -v limine-entry-tool &>/dev/null; then
    sudo limine-entry-tool || true
  fi
fi

echo "Uninstallation complete. Note: To reset ~/.config/hypr/monitors.lua and input.lua, restore any .bak files created during install."
