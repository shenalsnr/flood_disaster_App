#!/usr/bin/env python3
"""
Resolve git conflict hunks (<<<<<<< / ======= / >>>>>>>) in .dart files.

Rule for every hunk:
  1. If the incoming (Development) side becomes IDENTICAL to your side once the
     blue palette is applied  -> it is a colour-only conflict -> keep YOUR side.
  2. Otherwise (Development changed real code) -> keep the INCOMING side, and
     save YOUR side in conflict_review.txt so nothing is lost.

Usage (project root, apply_palette.py must be next to this file):
    python resolve_conflicts.py            # every .dart under lib/ that has markers
    python resolve_conflicts.py a.dart b.dart
Afterwards:  python apply_palette.py lib   then   git add .
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import apply_palette as ap  # noqa: E402


def palette(text):
    stats = {"colour": 0, "red fill": 0, "label->navy": 0,
             "redAccent": 0, "theme label->navy": 0}
    text = ap.per_line_rules(text, stats)
    text = ap.apply_map(text, stats)
    text = ap.fix_remaining(text, "x.dart", stats)
    return text


def norm(t):
    return re.sub(r"\s+", "", t)


def resolve(path, review):
    with open(path, encoding="utf8", newline="") as fh:
        src = fh.read()
    crlf = "\r\n" in src
    lines = src.replace("\r\n", "\n").split("\n")
    out, i, kept_mine, kept_theirs = [], 0, 0, 0
    while i < len(lines):
        if lines[i].startswith("<<<<<<<"):
            start = i
            mid = next(j for j in range(i, len(lines)) if lines[j].startswith("======="))
            end = next(j for j in range(mid, len(lines)) if lines[j].startswith(">>>>>>>"))
            mine = lines[start + 1:mid]
            theirs = lines[mid + 1:end]
            if norm(palette("\n".join(theirs))) == norm("\n".join(mine)):
                out += mine
                kept_mine += 1
            else:
                out += theirs
                kept_theirs += 1
                review.append("=== %s  (line %d)\n--- YOUR side (removed) ---\n%s\n"
                              "--- INCOMING kept ---\n%s\n"
                              % (path, start + 1, "\n".join(mine), "\n".join(theirs)))
            i = end + 1
        else:
            out.append(lines[i])
            i += 1
    text = "\n".join(out)
    if crlf:
        text = text.replace("\n", "\r\n")
    with open(path, "w", encoding="utf8", newline="") as fh:
        fh.write(text)
    return kept_mine, kept_theirs


def has_markers(p):
    with open(p, encoding="utf8", errors="ignore") as fh:
        return any(l.startswith("<<<<<<<") for l in fh)


def main():
    files = sys.argv[1:]
    if not files:
        for d, _, fs in os.walk("lib"):
            for f in fs:
                if f.endswith(".dart") and has_markers(os.path.join(d, f)):
                    files.append(os.path.join(d, f))
    review = []
    for p in files:
        a, b = resolve(p, review)
        print("%-95s colour-only: %d   real-change (incoming kept): %d" % (p, a, b))
    if review:
        with open("conflict_review.txt", "w", encoding="utf8") as fh:
            fh.write("\n".join(review))
        print("\n%d hunk(s) had real code changes - your side saved in conflict_review.txt"
              % len(review))
    print("Done. Now run: python apply_palette.py lib")


if __name__ == "__main__":
    main()
