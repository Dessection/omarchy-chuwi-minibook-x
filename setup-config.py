#!/usr/bin/env python3
"""Add/remove only marked desktop overrides, with backups before each edit."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

START = '-- BEGIN CHUWI MINIBOOK X LOCAL FIX\n'
END = '-- END CHUWI MINIBOOK X LOCAL FIX\n'

def strip_block(text):
    if START not in text:
        return text
    before, rest = text.split(START, 1)
    if END not in rest:
        raise ValueError('Incomplete Chuwi config block; inspect manually')
    return before + rest.split(END, 1)[1]

def main():
    action = sys.argv[1]
    assert action in ('install', 'uninstall')
    home = Path.home()
    backup = Path(os.environ.get('CHUWI_BACKUP', str(home / '.local/state/chuwi-minibook-x/backups' / str(time.time_ns()))))
    blocks = {}
    if action == 'install':
        monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))
        scale = next(m['scale'] for m in monitors if m['name'] == 'DSI-1')
        import math
        if not isinstance(scale, (int, float)) or not math.isfinite(scale) or scale <= 0:
            raise ValueError('Invalid monitor scale')
        blocks['monitors.lua'] = f'hl.monitor({{ output = "DSI-1", mode = "preferred", position = "auto", scale = {scale}, transform = 3 }})\n'
        blocks['input.lua'] = 'hl.device({ name = "goodix-capacitive-touchscreen-1", output = "DSI-1", transform = 3 })\nhl.config({ input = { touchdevice = { output = "DSI-1", transform = 3 } } })\n'
    for name in ('monitors.lua', 'input.lua'):
        target = (home / '.config/hypr' / name).resolve()
        original = target.read_text()
        updated = strip_block(original)
        if action == 'install':
            updated = updated.rstrip('\n') + '\n\n' + START + blocks[name] + END
        if updated != original:
            backup.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, backup / name)
            # Atomic replacement avoids Hyprland loading a partially written file.
            temporary = target.with_name(target.name + '.chuwi-tmp')
            temporary.write_text(updated)
            shutil.copymode(target, temporary)
            temporary.replace(target)
    print(f'Configuration {action}: backups in {backup}')

if __name__ == '__main__':
    main()
