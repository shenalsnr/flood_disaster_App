#!/usr/bin/env python3
"""
Resolve git conflict hunks (<<<<<<< / ======= / >>>>>>>) in .dart files after
`git pull origin Development`.

For every hunk:
  * If YOUR side (HEAD) and the INCOMING side (Development) are the same code
    apart from tr(...) wrappers, Flexible/const, quotes, colours, spacing
    -> keep YOUR side (it already has translation + overflow fixes).
  * Otherwise (a teammate really changed the code) -> keep the INCOMING side
    and save YOUR side in conflict_review.txt so nothing is lost.

Usage (project root):
    python tools/resolve_conflicts_keep_mine.py          # all .dart under lib/
    python tools/resolve_conflicts_keep_mine.py a.dart b.dart
Afterwards run, in this order:
    python tools/wesafe_translate.py lib        # re-wrap new teammate strings in tr()
    python tools/wesafe_fix_overflow.py lib     # re-apply overflow wrappers
    python apply_palette.py lib                 # only if you use it
    git add . ; git commit
"""
import os, re, sys

def norm(t):
    t = re.sub(r"Color\(0x[0-9A-Fa-f]{8}\)", "C", t)
    t = re.sub(r"Colors\.\w+(\.withValues\([^)]*\))?", "C", t)
    for junk in ("Flexible(child:", "Expanded(child:", "const ", "tr(", "mainAxisSize:MainAxisSize.min,",
                 "mainAxisSize: MainAxisSize.min,", "maxLines: 1,", "overflow: TextOverflow.ellipsis,"):
        t = t.replace(junk, "")
    return re.sub(r"[\s()\[\]{},;'\"]", "", t)

def resolve(path, review):
    with open(path, encoding="utf8", newline="") as fh:
        src = fh.read()
    crlf = "\r\n" in src
    lines = src.replace("\r\n", "\n").split("\n")
    out, i, mine_n, theirs_n = [], 0, 0, 0
    while i < len(lines):
        if lines[i].startswith("<<<<<<<"):
            start = i
            mid = next(j for j in range(i, len(lines)) if lines[j].startswith("======="))
            end = next(j for j in range(mid, len(lines)) if lines[j].startswith(">>>>>>>"))
            mine, theirs = lines[start + 1:mid], lines[mid + 1:end]
            if norm("\n".join(mine)) == norm("\n".join(theirs)):
                out += mine; mine_n += 1
            else:
                out += theirs; theirs_n += 1
                review.append("=== %s (line %d)\n--- YOUR side (removed) ---\n%s\n--- INCOMING kept ---\n%s\n"
                              % (path, start + 1, "\n".join(mine), "\n".join(theirs)))
            i = end + 1
        else:
            out.append(lines[i]); i += 1
    text = "\n".join(out)
    if crlf: text = text.replace("\n", "\r\n")
    with open(path, "w", encoding="utf8", newline="") as fh:
        fh.write(text)
    return mine_n, theirs_n

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
    if not files:
        print("No conflict markers found under lib/."); return
    review = []
    for p in files:
        a, b = resolve(p, review)
        print("%-90s kept yours: %d   took incoming: %d" % (p, a, b))
    if review:
        with open("conflict_review.txt", "w", encoding="utf8") as fh:
            fh.write("\n".join(review))
        print("\n%d hunk(s) took the incoming side. Your versions are in conflict_review.txt" % len(review))
    print("Next: python tools/wesafe_translate.py lib ; python tools/wesafe_fix_overflow.py lib")

if __name__ == "__main__":
    main()
