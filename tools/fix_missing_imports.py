"""Run from project root: python tools/fix_missing_imports.py
Adds missing tr()/LanguageButton imports to any lib/*.dart that uses them,
and drops `const` before LanguageButton() (safe always)."""
import os, re, sys
IMP = {
 'tr(': "core/localization/app_strings.dart",
 'LanguageButton': "core/localization/language_button.dart",
}
root = 'lib'
base = os.path.join(root, 'core', 'localization')
n = 0
for d, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith('.dart'): continue
        p = os.path.join(d, f)
        if os.path.abspath(d).startswith(os.path.abspath(base)): continue
        s = open(p, encoding='utf-8', newline='').read()
        o = s
        s = s.replace('const LanguageButton()', 'LanguageButton()')
        need = []
        if re.search(r'(?<![\w.])tr\(', s) and 'app_strings.dart' not in s:
            need.append('app_strings.dart')
        if 'LanguageButton' in s and 'language_button.dart' not in s:
            need.append('language_button.dart')
        if need:
            rel = os.path.relpath(base, d).replace('\\', '/')
            nl = '\r\n' if '\r\n' in s else '\n'
            lines = ''.join("import '%s/%s';%s" % (rel, x, nl) for x in need)
            m = list(re.finditer(r"^import .*;\r?\n", s, re.M))
            i = m[-1].end() if m else 0
            s = s[:i] + lines + s[i:]
        if s != o:
            open(p, 'w', encoding='utf-8', newline='').write(s)
            print('fixed', p, need); n += 1
print('files fixed:', n)
