#!/usr/bin/python3
"""Erzeugt die Firefox-Regeln aus der Vorgabe im Image und optional eigenen Werten pro Rechner.

Vorgabe:     /usr/share/senioren-os/firefox-policies.json   (kommt mit jedem Update)
Pro Rechner: /etc/senioren-os/firefox-lokal.json            (bleibt bei Updates erhalten)
Ergebnis:    /etc/firefox/policies/policies.json

firefox-lokal.json hat dieselbe Form ({"policies": {...}}). Jeder Eintrag darin ersetzt den
gleichnamigen Eintrag der Vorgabe vollständig, z. B. "Homepage" oder "Bookmarks"."""
import json, os

VORGABE = "/usr/share/senioren-os/firefox-policies.json"
LOKAL = "/etc/senioren-os/firefox-lokal.json"
ZIEL = "/etc/firefox/policies/policies.json"

regeln = json.load(open(VORGABE))
if os.path.exists(LOKAL):
    try:
        regeln["policies"].update(json.load(open(LOKAL))["policies"])
    except (ValueError, KeyError) as e:   # kaputte lokale Datei: lieber Vorgabe als gar nichts
        print(f"{LOKAL} ignoriert: {e}")

os.makedirs(os.path.dirname(ZIEL), exist_ok=True)
tmp = ZIEL + ".neu"
with open(tmp, "w") as f:
    json.dump(regeln, f, ensure_ascii=False, indent=2)
os.chmod(tmp, 0o644)
os.replace(tmp, ZIEL)
