# MiniBook X N100: Omarchy display and touchscreen fixes

Based on Dessection/omarchy-chuwi-minibook-x commit
0dca8213ef56acfb15c652b46a8c5b30800252ae (MIT license retained).
This local edition supersedes the upstream installation instructions in README.md.

On the MiniBook, extract the archive, open a terminal in this folder, and run:

```bash
./install.sh
```

Run as your normal user in the MiniBook's Hyprland desktop. The installer checks
for MiniBook X hardware, DSI-1, a working Hyprland Lua config, and the Omarchy
SDDM Wayland greeter with Limine. It uses sudo to configure SDDM and Limine,
rebuild the boot image, start the sensor service, and install Arch packages if needed.

The installer backs up settings under `~/.local/state/chuwi-minibook-x/backups/`,
updates its marked desktop settings, enables the rotation service, and installs
login screen rotation, touch mapping, and boot orientation. It preserves the current desktop
display scale and uses Omarchy's greeter keyboard settings. You can run the same
command over an earlier installation.

Save your work and reboot. Check the login screen orientation and touchscreen
alignment, then sign in and check auto-rotation in all four orientations.

Diagnostics:

```bash
systemctl --user status chuwi-rotate.service
journalctl --user -u chuwi-rotate.service -b
monitor-sensor
hyprctl configerrors
```

To remove this local installation:

```bash
./uninstall.sh
```

This removes the marked desktop settings, rotation service, SDDM override, and
Limine drop-ins. Reboot after the boot image rebuilds.
Dependencies and backup files remain. If replacing an older rotation daemon or
service, copies of those files are retained in the install backup for manual
restoration. Existing DSI-1 rules may need manual reconciliation; the installer
adds an override without deleting them. Tablet keyboard/touchpad disabling is
not implemented.

## MiniBook X N100 verification for the PR

- SDDM loaded the override, and the password screen was upright after logging out.
- `fbcon=rotate:1` made the text console upright. Both that setting and
  `panel_orientation=right_side_up` were confirmed in `/proc/cmdline` after rebuilding
  the boot image and rebooting.
- One reboot still showed a sideways Omarchy frame just after submitting the
  password. On the next two reboots and a full shutdown followed by power-on, sign-in
  showed the CHUWI logo followed by a brief blank screen before the desktop appeared.
- Reapplying the combined installer on the same MiniBook succeeded. After reboot,
  both kernel settings were present in `/proc/cmdline` and no sideways flash was
  observed. The blank screen after sign-in lasted roughly five seconds.
