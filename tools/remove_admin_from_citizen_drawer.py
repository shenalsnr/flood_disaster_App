#!/usr/bin/env python3
"""Removes the 'Admin Dashboard' item from the CITIZEN side drawer.
Run in the project root:  python tools/remove_admin_from_citizen_drawer.py"""
import re, glob, sys
c = glob.glob('lib/**/citizen_drawer.dart', recursive=True)
if not c:
    print('citizen_drawer.dart not found - run from the project root.'); sys.exit(1)
p = c[0]
src = open(p, encoding='utf8', newline='').read()
crlf = '\r\n' in src
s = src.replace('\r\n', '\n')
pat = re.compile(
    r"(?:[ \t]*//[^\n]*Admin Tools[^\n]*\n)?"
    r"[ \t]*_DrawerItem\(\s*icon: Icons\.admin_panel_settings_rounded,\s*"
    r"title: (?:tr\()?'Admin Dashboard'\)?,.*?C1AdminMetricsScreen\(\),\s*\),\s*\);\s*\},\s*\),\n(?:[ \t]*\n)?", re.S)
s2, n = pat.subn('', s, count=1)
if not n:
    print('Admin item not found (already removed or the file changed).'); sys.exit(0)
# drop the import if nothing else uses the screen
if 'C1AdminMetricsScreen' not in s2:
    s2 = re.sub(r"import '[^']*c1_admin_metrics_screen\.dart';\n", '', s2)
open(p, 'w', encoding='utf8', newline='').write(s2.replace('\n', '\r\n') if crlf else s2)
print('Removed Admin Dashboard from', p)
