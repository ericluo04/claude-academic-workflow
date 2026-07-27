#!/usr/bin/env python3
"""Print a random sample of one open-text column so a human can read it.

Strips the Qualtrics question-text and ImportId rows, warns on ragged rows
(wrong field count, which makes column attribution suspect), and shows up to
25 non-trivial values.

Usage: python3 sample_open_text.py <file.csv> <column_name>
"""
import csv, random, sys

def main():
    if len(sys.argv) != 3:
        sys.exit("usage: python3 sample_open_text.py <file.csv> <column_name>")
    p, col = sys.argv[1], sys.argv[2]
    with open(p, newline="", encoding="utf-8", errors="replace") as f:
        rows = list(csv.reader(f))
    hdr, body = rows[0], rows[1:]
    j = hdr.index(col)
    ragged = [i + 2 for i, r in enumerate(body) if len(r) != len(hdr)]
    if ragged:
        print(f"WARNING: {len(ragged)} row(s) do not have {len(hdr)} fields, first at line {ragged[0]}. "
              "Column attribution below can be wrong; fix the file before trusting it.")
    if len(body) > 1 and '{"ImportId"' in "".join(body[1]):
        body = body[2:]          # Qualtrics question-text and ImportId rows are not data
    vals = [r[j].strip() for r in body if j < len(r)]
    vals = [v for v in vals if len(v) > 20]
    random.seed(0)
    print(f"{len(vals)} non-trivial values in {col!r}; showing {min(25, len(vals))}")
    for v in random.sample(vals, min(25, len(vals))):
        print("---", v[:600])

if __name__ == "__main__":
    main()
