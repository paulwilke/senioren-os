#!/usr/bin/python3
"""Generates the Firefox policies from the defaults in the image plus optional per-machine values.

Defaults:    /usr/share/senioren-os/firefox-policies.json   (comes with every update)
Per machine: /etc/senioren-os/firefox-lokal.json            (survives updates)
Result:      /etc/firefox/policies/policies.json

firefox-lokal.json has the same shape ({"policies": {...}}). Each entry in it completely replaces
the default entry of the same name, e.g. "Homepage" or "Bookmarks".

(VORGABE = defaults, LOKAL = local, ZIEL = target, regeln = policies.)"""
import json, os

VORGABE = "/usr/share/senioren-os/firefox-policies.json"
LOKAL = "/etc/senioren-os/firefox-lokal.json"
ZIEL = "/etc/firefox/policies/policies.json"

regeln = json.load(open(VORGABE))
if os.path.exists(LOKAL):
    try:
        regeln["policies"].update(json.load(open(LOKAL))["policies"])
    except (ValueError, KeyError) as e:   # broken local file: better the defaults than nothing
        print(f"{LOKAL} ignored: {e}")

os.makedirs(os.path.dirname(ZIEL), exist_ok=True)
tmp = ZIEL + ".neu"
with open(tmp, "w") as f:
    json.dump(regeln, f, ensure_ascii=False, indent=2)
os.chmod(tmp, 0o644)
os.replace(tmp, ZIEL)
