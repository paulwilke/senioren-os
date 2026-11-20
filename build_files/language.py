#!/usr/bin/python3
"""Applies LANGUAGE, LOCALE and KEYBOARD from senioren-os.conf to the image.

Firefox and Thunderbird get their language pack force-installed by policy. Relying on
Fedora's start script (which copies the pack into the profile) or on the system language
alone is not enough: our policies block add-ons, and then the apps fall back to English."""
import glob, json, os, re, sys

conf = {}
for line in open(sys.argv[1]):
    if m := re.match(r"^\s*([A-Z]+)\s*=\s*(\S+)", line):
        conf[m[1]] = m[2]
lang, locale, keyboard = conf["LANGUAGE"], conf["LOCALE"], conf["KEYBOARD"]


def langpack(app_dir, app_id):
    """Path of the language pack for `lang`: exact match first, then a regional one (es -> es-ES)."""
    for pattern in (f"langpack-{lang}@{app_id}.xpi", f"langpack-{lang}-*@{app_id}.xpi"):
        hits = sorted(glob.glob(os.path.join(app_dir, pattern)))
        if hits:
            return hits[0]
    return None


def set_language(policy_file, app_dir, app_id):
    data = json.load(open(policy_file))
    p = data["policies"]
    p["RequestedLocales"] = [lang]
    ext = p.setdefault("ExtensionSettings", {})
    for key in [k for k in ext if k.startswith("langpack-")]:
        del ext[key]
    pack = None if lang == "en" else langpack(app_dir, app_id)
    if lang != "en" and not pack:
        sys.exit(f"No language pack for '{lang}' in {app_dir}")
    if pack:
        ext[os.path.basename(pack)[:-4]] = {
            "installation_mode": "force_installed",
            "install_url": "file://" + pack,
        }
    json.dump(data, open(policy_file, "w"), ensure_ascii=False, indent=2)
    print(f"{policy_file}: {lang}, {pack or 'built-in English'}")


set_language("/usr/share/senioren-os/firefox-policies.json",
             "/usr/lib64/firefox/langpacks", "firefox.mozilla.org")
set_language("/etc/thunderbird/policies/policies.json",
             "/usr/lib64/thunderbird/extensions", "thunderbird.mozilla.org")

# Keyboard in the GNOME defaults (also locked for the user)
dconf = "/etc/dconf/db/local.d/00-senioren"
text = open(dconf).read()
text, n = re.subn(r"^sources=.*$", f"sources=[('xkb', '{keyboard}')]", text, flags=re.M)
assert n == 1, "input-sources not found in 00-senioren"
open(dconf, "w").write(text)

# System locale as default; Anaconda may write its own per machine
open("/etc/locale.conf", "w").write(f'LANG="{locale}"\n')
print(f"keyboard {keyboard}, locale {locale}")
