#!/usr/bin/env python3
"""Classify column headers across every delimited and Excel file under a root.

Walks the tree, reads headers from each .csv/.tsv/.tab/.xlsx/.xlsm, and prints
per file: MUST REMOVE columns (direct identifiers), DECIDE columns (the user's
judgment call), and open-text columns that need a human read.

Usage: python3 scan_headers.py <scan_root>
"""
import csv, os, re, sys, zipfile

HARD = set("""ipaddress ip_address ip locationlatitude locationlongitude locationaccuracy latitude longitude
recipientemail recipientfirstname recipientlastname recipientname externalreference externaldatareference
workerid worker_id assignmentid assignment_id hitid hit_id prolific_pid prolificpid pid prolific_id
participant_id study_id session_id sessionid psid cr_id panelist_id panelistid respondent_id respondentid
rid ttid supplier_id transaction_id email e_mail emailaddress email_address phone phonenumber phone_number
name firstname lastname first_name last_name fullname full_name address street zip zipcode zip_code
postal_code student_id netid ssn dob date_of_birth birthdate""".split())
DECIDE = set("""responseid response_id startdate enddate recordeddate userlanguage distributionchannel
q_recaptchascore q_relevantidduplicate q_relevantidduplicatescore q_relevantidfraudscore
q_relevantidlaststartdate city state region country zip3 timezone useragent user_agent browser os
screenresolution""".split())
SUB = ("email", "phone", "ipaddr", "worker", "prolific", "mturk", "panelist", "latitude", "longitude",
       "firstname", "lastname", "fullname", "birth", "ssn", "netid", "studentid", "respondentid", "geoip")

def norm(s):
    return re.sub(r"[^a-z0-9_]", "", s.strip().lower())

def classify(cols):
    hard, decide = [], []
    for c in cols:
        n = norm(c)
        if not n:
            continue
        if n in HARD or any(k in n for k in SUB):
            hard.append(c)
        elif n in DECIDE:
            decide.append(c)
    return hard, decide

def open_text(hdr, body):
    out = []
    for j, h in enumerate(hdr):
        vals = [r[j] for r in body if j < len(r) and r[j].strip()]
        if not vals:
            continue
        longish = sum(1 for v in vals if len(v) >= 40 or len(v.split()) >= 5)
        if longish >= max(1, len(vals) // 5):
            out.append(h)
    return out

def read_delim(p, low):
    d = "\t" if low.endswith((".tsv", ".tab")) else ","
    rows = []
    with open(p, newline="", encoding="utf-8", errors="replace") as f:
        for i, r in enumerate(csv.reader(f, delimiter=d)):
            if i > 200:
                break
            rows.append(r)
    if not rows:
        return None, []
    hdr = rows[0]
    body = [r for r in rows[1:] if '{"ImportId"' not in "".join(r)]
    # Qualtrics row 2 is question text, not data
    if body and sum(1 for c in body[0] if len(c) > 60) > max(1, len(hdr) // 4):
        body = body[1:]
    return hdr, body

def main():
    if len(sys.argv) != 2:
        sys.exit("usage: python3 scan_headers.py <scan_root>")
    for dp, _, fns in os.walk(sys.argv[1]):
        for fn in sorted(fns):
            p, low = os.path.join(dp, fn), fn.lower()
            if low.endswith((".csv", ".tsv", ".tab")):
                hdr, body = read_delim(p, low)
                if hdr is None:
                    continue
                hard, decide = classify(hdr)
                txt = open_text(hdr, body)
            elif low.endswith((".xlsx", ".xlsm")):
                try:
                    with zipfile.ZipFile(p) as z:
                        blob = z.read("xl/sharedStrings.xml").decode("utf-8", "replace")
                except Exception as e:
                    print(f"{p}: xlsx not readable ({e})")
                    continue
                # the strings table holds headers and values together, so this is a superset
                hard, decide = classify(re.findall(r"<t[^>]*>(.*?)</t>", blob, re.S))
                txt = []
            else:
                continue
            if hard or decide or txt:
                print(p)
                if hard:
                    print("  MUST REMOVE:", ", ".join(sorted(set(hard))))
                if decide:
                    print("  DECIDE     :", ", ".join(sorted(set(decide))))
                if txt:
                    print("  OPEN TEXT  :", ", ".join(sorted(set(txt))[:12]), "(read a sample)")

if __name__ == "__main__":
    main()
