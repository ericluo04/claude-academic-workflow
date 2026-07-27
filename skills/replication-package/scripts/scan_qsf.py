#!/usr/bin/env python3
"""Grep a Qualtrics .qsf survey definition for the researcher's own footprint.

Reports email addresses, Qualtrics user/survey/contact-list ids, account and
datacenter fields, and URLs carrying tokens, with counts and examples, before
the .qsf ships in an archive.

Usage: python3 scan_qsf.py <survey.qsf>
"""
import re, sys

PATS = {
    "email address": r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
    "qualtrics user id": r"\bUR_[A-Za-z0-9]{11,}\b",
    "survey id": r"\bSV_[A-Za-z0-9]{11,}\b",
    "contact or mailing list id": r"\b(?:CG|ML|MS|CL)_[A-Za-z0-9]{11,}\b",
    "account or datacenter field": r"\"(?:brandBaseURL|brandID|datacenter|OrganizationID|UserID)\"\s*:\s*\"[^\"]+\"",
    "url carrying a token": r"https?://[^\s\"']*(?:token|auth|key|sig)=[^\s\"'&]+",
}

def main():
    if len(sys.argv) != 2:
        sys.exit("usage: python3 scan_qsf.py <survey.qsf>")
    raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    for label, pat in PATS.items():
        hits = sorted(set(re.findall(pat, raw, re.I)))
        if hits:
            print(f"{label}: {len(hits)} unique, e.g. {hits[:3]}")

if __name__ == "__main__":
    main()
