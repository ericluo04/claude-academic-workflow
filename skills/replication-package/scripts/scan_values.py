#!/usr/bin/env python3
"""Scan cell values in delimited and Excel files for identifier shapes.

Catches the identifier sitting in a column with an innocuous name: emails,
phone numbers, IPv4/IPv6 addresses, MTurk worker ids, Qualtrics response ids.
Prints per hit the file, pattern, column, first line, count, and a masked
sample.

Usage: python3 scan_values.py <scan_root>
"""
import csv, os, re, sys, zipfile

PATS = {
    "email": re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"),
    "phone": re.compile(r"(?<!\d)(?:\+?1[ .\-]?)?\(?\d{3}\)?[ .\-]?\d{3}[ .\-]?\d{4}(?!\d)"),
    "ipv4": re.compile(r"(?<![\d.])(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}"
                       r"(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?![\d.])"),
    # four or more hextets, or a compressed ::, so a clock time cannot match
    "ipv6": re.compile(r"(?<![:.\w])(?:"
                       r"(?:[0-9A-Fa-f]{1,4}:){3,7}[0-9A-Fa-f]{1,4}"
                       r"|(?:[0-9A-Fa-f]{1,4}:){1,7}:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?"
                       r"|::(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?"
                       r")(?:%[0-9A-Za-z]+)?(?![:.\w])"),
    "mturk_worker": re.compile(r"\bA[A-Z0-9]{12,14}\b"),
    "qualtrics_response": re.compile(r"\bR_[A-Za-z0-9]{15,17}\b"),
}
CLOCK = re.compile(r"^\d{1,2}:\d{2}:\d{2}$")     # second line of defense on timestamps

def mask(s):
    return s[:3] + "*" * max(0, len(s) - 5) + s[-2:] if len(s) > 6 else "***"

def cells(p, low):
    if low.endswith((".xlsx", ".xlsm")):
        with zipfile.ZipFile(p) as z:
            blob = z.read("xl/sharedStrings.xml").decode("utf-8", "replace")
        for v in re.findall(r"<t[^>]*>(.*?)</t>", blob, re.S):
            yield 0, "(xlsx strings)", v
        return
    d = "\t" if low.endswith((".tsv", ".tab")) else ","
    with open(p, newline="", encoding="utf-8", errors="replace") as f:
        rd = csv.reader(f, delimiter=d)
        hdr = next(rd, [])
        for ln, row in enumerate(rd, start=2):
            for j, c in enumerate(row):
                yield ln, (hdr[j] if j < len(hdr) else f"col{j}"), c[:4000]

def main():
    if len(sys.argv) != 2:
        sys.exit("usage: python3 scan_values.py <scan_root>")
    for dp, _, fns in os.walk(sys.argv[1]):
        for fn in sorted(fns):
            p, low = os.path.join(dp, fn), fn.lower()
            if not low.endswith((".csv", ".tsv", ".tab", ".xlsx", ".xlsm")):
                continue
            hits = {}
            try:
                for ln, col, val in cells(p, low):
                    for name, rx in PATS.items():
                        m = rx.search(val)
                        if not m or (name == "ipv6" and CLOCK.match(m.group(0))):
                            continue
                        k = (name, col)
                        if k in hits:
                            hits[k][2] += 1
                        else:
                            hits[k] = [ln, mask(m.group(0)), 1]
            except Exception as e:
                print(f"{p}: not scanned ({e})")
                continue
            for (name, col), (ln, sample, n) in sorted(hits.items()):
                print(f"{p}: {name} in column {col!r}, first at line {ln}, {n} cell(s), e.g. {sample}")

if __name__ == "__main__":
    main()
