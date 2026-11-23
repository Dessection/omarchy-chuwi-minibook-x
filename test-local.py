import ast
import importlib.machinery
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent
sys.modules['gi'] = types.ModuleType('gi')
sys.modules['gi.repository'] = types.SimpleNamespace(GLib=None, Gio=None)
daemon = types.ModuleType('rotation')
exec(compile((ROOT/'bin/chuwi-minibook-x-rotate').read_text(), 'rotation', 'exec'), daemon.__dict__)

class Tests(unittest.TestCase):
    def setUp(self):
        daemon.current_transform = None

    def test_rotation_preserves_fractional_scale(self):
        calls = []
        def command(*args):
            calls.append(args)
            return json.dumps([{'name':'DSI-1','scale':1.6}]) if args[0]=='monitors' else 'ok'
        with patch.object(daemon, 'hyprctl', command):
            for transform in range(4):
                daemon.apply_transform(transform)
        monitor_calls = [c[1] for c in calls if c[0]=='eval' and 'hl.monitor' in c[1]]
        self.assertEqual(len(monitor_calls), 4)
        self.assertTrue(all('scale = 1.6' in c for c in monitor_calls))
        self.assertFalse(any(c[0]=='keyword' for c in calls))

    def test_failure_allows_same_orientation_retry(self):
        with patch.object(daemon, 'hyprctl', side_effect=RuntimeError('failed')):
            daemon.apply_transform(3)
        self.assertIsNone(daemon.current_transform)

    def test_exit_zero_error_detected(self):
        with patch.object(daemon.subprocess, 'run', return_value=types.SimpleNamespace(stdout='Lua error',stderr='')):
            with self.assertRaises(RuntimeError): daemon.hyprctl('eval','bad')

    def test_install_idempotent_and_uninstall_preserves_other_edits(self):
        config = types.ModuleType('config')
        exec(compile((ROOT/'setup-config.py').read_text(), 'config', 'exec'), config.__dict__)
        with tempfile.TemporaryDirectory(dir=ROOT) as tmp:
            home=Path(tmp); hypr=home/'.config/hypr'; hypr.mkdir(parents=True)
            for name in ('monitors.lua','input.lua'): (hypr/name).write_text('-- existing\n')
            with patch.object(config.Path,'home',return_value=home), patch.object(config.subprocess,'check_output',return_value=b'[{"name":"DSI-1","scale":1.6}]'), patch.dict(os.environ,{'CHUWI_BACKUP':str(home/'backup')}):
                with patch.object(sys,'argv',['setup-config.py','install']):
                    config.main(); config.main()
                self.assertEqual((hypr/'monitors.lua').read_text().count(config.START),1)
                with (hypr/'input.lua').open('a') as f: f.write('-- later edit\n')
                with patch.object(sys,'argv',['setup-config.py','uninstall']): config.main()
                self.assertIn('-- later edit', (hypr/'input.lua').read_text())
                self.assertNotIn(config.START,(hypr/'monitors.lua').read_text())

if __name__=='__main__': unittest.main()
