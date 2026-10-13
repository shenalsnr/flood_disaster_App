#!/usr/bin/env python3
"""
WeSafe dark palette (blue accent) - colour-only update.

Changes ONLY colour values in .dart files under the given lib folder.
No logic, layout or data is touched.

Usage (from the project root):
    python apply_palette.py lib            # apply
    python apply_palette.py lib --dry-run  # only show what would change

Undo:  git checkout -- lib   (or: git restore lib)
"""
import os
import re
import sys

NAVY_TEXT = "0xFF06121F"  # dark text used on bright accent buttons

# exact colour -> new colour (alpha byte is kept, e.g. 0x3300E676 -> 0x3334D399)
MAP = {
    # accent: orange / cyan -> water blue
    "FF6D00": "38BDF8", "E5500F": "0EA5E9", "FF8F5A": "7DD3FC",
    "40C4FF": "38BDF8", "00B0FF": "38BDF8",
    # safe: greens -> emerald
    "00E676": "34D399", "22C55E": "34D399", "4ADE80": "34D399",
    "00C853": "34D399", "69F0AE": "6EE7B7",
    # danger: reds -> soft red (text / icons / borders)
    "FF5252": "F87171", "FF1744": "F87171", "FF3B3B": "F87171",
    # warning: ambers -> amber ; strong orange stays orange
    "FFC107": "FBBF24", "FFB300": "FBBF24", "FFB020": "FBBF24",
    "F59E0B": "FBBF24", "FFD740": "FBBF24", "FACC15": "FBBF24",
    "FF9F0A": "FB923C",
    # navy surfaces
    "070B14": "0B1220", "131B2B": "131C2E", "1E293B": "1C2740",
    "334155": "2B3A55",
    # text greys (secondary) and low-contrast greys (muted)
    "94A3B8": "B6C2D6", "8E9BAE": "B6C2D6", "8B9BB4": "B6C2D6",
    "8C97AB": "B6C2D6", "90A4AE": "B6C2D6",
    "64748B": "8A98B0", "5E6D82": "8A98B0", "63738A": "8A98B0",
    "70809A": "8A98B0", "7E8B9B": "8A98B0",
}

ACCENT_LINE = re.compile(
    r"0xFFFF6D00|C4\.accent|primaryActionOrange|AppColors\.primary\b")
RED_LINE = re.compile(r"0xFFFF5252|0xFFFF1744|Colors\.redAccent(?![\w\[]|\.shade)")
WHITE_FG = re.compile(r"foregroundColor:\s*(?:const\s+)?Colors\.white\b")


def per_line_rules(text, stats):
    lines = text.split("\n")
    out = list(lines)
    for i, line in enumerate(lines):
        # 1) bright accent button background + white label -> dark label
        if "backgroundColor" in line and ACCENT_LINE.search(line):
            for j in range(max(0, i - 4), min(len(lines), i + 7)):
                if WHITE_FG.search(out[j]):
                    out[j] = WHITE_FG.sub(
                        "foregroundColor: const Color(%s)" % NAVY_TEXT, out[j])
                    stats["label->navy"] += 1
                    break
        # 2) red used as a FILL (white text on top) -> darker red
        if "backgroundColor" in line and RED_LINE.search(line):
            new = re.sub(r"0xFFFF5252|0xFFFF1744", "0xFFDC2626", out[i])
            new = re.sub(r"Colors\.redAccent(?![\w\[]|\.shade)",
                         "Color(0xFFDC2626)", new)
            if new != out[i]:
                out[i] = new
                stats["red fill"] += 1
    return "\n".join(out)


def apply_map(text, stats):
    def repl(m):
        alpha, rgb = m.group(1), m.group(2).upper()
        if rgb in MAP:
            stats["colour"] += 1
            return "0x%s%s" % (alpha, MAP[rgb])
        return m.group(0)

    return re.sub(r"0x([0-9A-Fa-f]{2})([0-9A-Fa-f]{6})\b", repl, text)


def fix_remaining(text, rel, stats):
    # Colors.redAccent used as text / icon colour -> soft red
    new = re.sub(r"Colors\.redAccent(?![\w\[]|\.shade)", "Color(0xFFF87171)", text)
    if new != text:
        stats["redAccent"] += 1
    text = new
    # shelter theme: white label on the (now bright blue) primary
    if rel.endswith("shelter_theme.dart"):
        new = re.sub(r"(onPrimary|foregroundColor):\s*textHighContrastWhite",
                     r"\1: Color(%s)" % NAVY_TEXT, text)
        if new != text:
            stats["theme label->navy"] += 1
        text = new
    return text


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    root = args[0] if args else "lib"
    if not os.path.isdir(root):
        print("Folder not found:", root)
        sys.exit(1)
    changed = 0
    total = {}
    for d, _, files in os.walk(root):
        for f in files:
            if not f.endswith(".dart"):
                continue
            p = os.path.join(d, f)
            with open(p, encoding="utf8", newline="") as fh:
                src = fh.read()
            crlf = "\r\n" in src
            text = src.replace("\r\n", "\n")
            stats = {"colour": 0, "red fill": 0, "label->navy": 0,
                     "redAccent": 0, "theme label->navy": 0}
            text = per_line_rules(text, stats)
            text = apply_map(text, stats)
            text = fix_remaining(text, p.replace("\\", "/"), stats)
            if crlf:
                text = text.replace("\n", "\r\n")
            if text != src:
                changed += 1
                for k, v in stats.items():
                    total[k] = total.get(k, 0) + v
                if not dry:
                    with open(p, "w", encoding="utf8", newline="") as fh:
                        fh.write(text)
    print(("DRY RUN - " if dry else "") + "files changed:", changed)
    for k, v in total.items():
        print("  %-18s %d" % (k, v))


if __name__ == "__main__":
    main()
