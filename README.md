# Senioren-OS

A calm, Mac-like Linux for older people who just want to browse the web, read e-mail,
watch YouTube, do online banking and write the occasional letter.
Built for older Intel MacBooks (tested on a MacBook Pro Retina 15", 2012),
but runs on any x86-64 computer.

It is based on **Fedora Silverblue** via [Universal Blue](https://universal-blue.org) (`silverblue-main`).
The system is read-only ("atomic"): updates arrive as a whole, and if something goes wrong
you simply pick the previous version at boot.

Everything is open source. The only exception is the Broadcom Wi-Fi driver that many MacBooks need
(from RPM Fusion nonfree).

> **Language:** Senioren-OS is made for German-speaking users. The documentation and code comments
> are in English, but everything the user sees (desktop, apps, keyboard layout, Firefox bookmarks, installer
> entries, the data rescue tool) is German. The language is set in `senioren-os.conf`, see [Using another language](#using-another-language).

## What's included

| Area | Contents |
|---|---|
| Desktop | GNOME in Mac style: dock at the bottom (always visible), window buttons on the left, WhiteSur icons and cursors, Inter font +20 %, large mouse pointer, accessibility menu always visible |
| Locked down | All settings from `00-senioren` are locked: dock incl. trash, wallpaper, font, window buttons, app grid. Settings, Terminal and the software center are hidden. Alt+F2 is disabled |
| Calm | A single fixed workspace, no "hot corner", no update notifications, no welcome tour, no automatic screen lock |
| Apps | Firefox, Thunderbird (e-mail), LibreOffice, image viewer, RustDesk (remote help from the family), ZapZap (WhatsApp), Butler (Home Assistant, e.g. a solar power system) |
| Firefox | Locked homepage (Sparkasse), bookmarks for YouTube, news, weather, TV media libraries, video calls. uBlock Origin, HTTPS-only, no telemetry, no third-party add-ons, no about:config, website notifications blocked |
| Keyboard/touchpad | German Mac keyboard, natural scrolling, tap to click |
| Hardware | Broadcom Wi-Fi (`wl`), iPhone/iPad (photos via "Files"), Mac fan control if available |
| Remote maintenance | Tailscale + SSH (admin accounts only, keys only, only via Tailscale). On foreign networks nothing is reachable from outside |
| Updates | Built daily and split into chunks (only what changed is downloaded). Downloaded in the background, active after the next reboot. Never over metered connections |

**Admin accounts** (group `wheel`) are exempt from all restrictions and see all apps.
Only the user's own account is locked down.

## One USB stick for everything: try it, rescue Mac data, install

*Actions → "Build live ISO" → Run workflow*, after about 30–40 minutes download `senioren-os-live.iso`
and write it to a USB stick with balenaEtcher. On the Mac, boot holding **Alt** → "EFI Boot" →
"Senioren-OS ausprobieren" (try Senioren-OS). Nothing is installed and nothing is changed.

- This is what it looks like for the user (locked down). In addition the dock has a terminal and **"Mac-Daten retten"** (rescue Mac data).
- **"Mac-Daten retten"** finds the old Mac disk (APFS, read-only) and copies all user folders
  to an external disk (ideally exFAT) into the folder `mac-backup`.
- Good for testing Wi-Fi, graphics and font size on exactly this machine before installing.
- **"Senioren-OS installieren"** (install Senioren-OS) in the dock starts the installer. It needs **internet**
  (Wi-Fi works in the live system), because it downloads the current system from GitHub (about 4 GB). The apps are copied from the stick.

The plain installation ISO (*"Build installation ISO"*) is still available, e.g. for machines without network access during installation.

## Installing

1. **Get the ISO:** on GitHub under *Actions → "Build installation ISO" → Run workflow*.
   After about 20 minutes `install.iso` is available as a download on the run.
   (Or build locally: see below.)
2. **Write it to a USB stick** (at least 8 GB), e.g. with [balenaEtcher](https://etcher.balena.io) or `dd`.
3. **On the MacBook:** plug in the stick, hold **⌥ (Alt)** while powering on, choose "EFI Boot".
4. **In the installer:** language German, use the whole disk, create two users:
   - **the user**, *without* administrator rights
   - **you (family/helper)**, *with* administrator rights
5. **After the first boot**, connect to Wi-Fi. LibreOffice, RustDesk, ZapZap, Butler and the image viewer
   are then installed automatically (a few minutes).
6. Set up the e-mail account in Thunderbird. In RustDesk, set a permanent password under settings
   and write down the ID.

7. Open ZapZap and scan the QR code with the phone. In Butler, enter the Home Assistant address
   (e.g. the Tailscale address or the Nabu Casa address) and sign in.
8. Set up remote maintenance, see below.

From now on the machine fetches its updates itself from `ghcr.io/<github-user>/senioren-os:latest`.

## Remote maintenance (Tailscale + SSH + AI agent)

Once, on the machine, in the **admin account**:

```bash
sudo tailscale up --hostname=senioren-mac        # open the link and sign in to your own tailnet
mkdir -p ~/.ssh && nano ~/.ssh/authorized_keys   # paste your own public SSH key
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

In the Tailscale admin console, enable **"Disable key expiry"** for this device,
otherwise it drops off the network after 180 days, e.g. in the middle of a holiday.

Afterwards, from anywhere:

```bash
ssh admin@senioren-mac
```

**AI agent for repairs:** install Claude Code in the admin account only (it goes to `~/.local/bin`
and works on the read-only system):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

When there is a problem, log in via SSH and let `claude` investigate. The user's account deliberately
gets no agent: it has no admin rights, and an agent that can be steered by voice would be
an entry point for phone and website scams.

## Updates and poor connections

- GitHub rebuilds **every night**. The machine checks daily around 11 am and catches up on a missed update at the next power-on.
- **Not the whole system** is downloaded, only the parts that changed. Typically a few to a few hundred MB per day.
- `uupd` only downloads with enough battery and **never over metered connections**. Phone hotspots are usually detected automatically.
  For a weak Wi-Fi (e.g. on holiday): as admin *Settings → Wi-Fi → gear icon → Details → "Metered connection"*.
- If a download is interrupted, nothing breaks. It is retried next time.

## Customizing

| What | Where |
|---|---|
| GNOME settings (all of them are locked automatically) | `system_files/etc/dconf/db/local.d/00-senioren` |
| Additionally locked keys | `system_files/etc/dconf/db/local.d/locks/senioren` |
| Firefox: homepage, bookmarks, policies | `system_files/usr/share/senioren-os/firefox-policies.json` |
| Firefox per machine (local Sparkasse, own bookmarks) | on the machine `/etc/senioren-os/firefox-lokal.json`, see below |
| Apps from Flathub | `system_files/usr/share/senioren-os/flatpaks.list` |
| System packages, drivers, icons, hidden apps (`HIDE`) | `build_files/build.sh` |
| Language and keyboard | `senioren-os.conf` |
| Fedora version | `FEDORA_MAJOR` in `Containerfile` (twice) |
| Update source for newly installed machines | `iso/config.toml` |

Change → commit → GitHub rebuilds → the machines have it after their next reboot.

**Your own variant:** fork the repo and adjust the GitHub user name in `iso/config.toml`.

## Per-machine homepage and bookmarks

The default points to sparkasse.de. The user's own local Sparkasse and personal bookmarks do not belong
in the public image; as admin, put them on the machine itself. Each entry replaces the default entry
of the same name, stays locked and survives updates:

```bash
sudo mkdir -p /etc/senioren-os
sudo tee /etc/senioren-os/firefox-lokal.json <<'X'
{"policies": {
  "Homepage": {"URL": "https://www.MEINE-SPARKASSE.de", "StartPage": "homepage", "Locked": true},
  "Bookmarks": [
    {"Title": "Sparkasse", "URL": "https://www.MEINE-SPARKASSE.de", "Placement": "toolbar"},
    {"Title": "YouTube", "URL": "https://www.youtube.com", "Placement": "toolbar"}
  ]
}}
X
sudo systemctl restart senioren-firefox-policies   # then restart Firefox
```

## Extra apps on a single machine (e.g. ChatGPT)

Non-free apps such as the official ChatGPT app do not belong in the public image.
Install them as admin on the machine itself:

```bash
# download the .rpm from the vendor's website, then:
sudo rpm-ostree install ~/Downloads/ChatGPT-*.rpm
systemctl reboot
```

The app survives system updates. New versions of the app have to be installed by hand
unless the vendor provides a package repository.

**Adding it to the dock:** the dock list is locked. So, as admin, create a separate file
that overrides the default and survives updates:

```bash
ls /usr/share/applications | grep -i chatgpt      # find the name of the .desktop file
sudo tee /etc/dconf/db/local.d/50-lokal <<'X'
[org/gnome/shell]
favorite-apps=['org.mozilla.firefox.desktop', 'net.thunderbird.Thunderbird.desktop', 'com.rtosta.zapzap.desktop', 'com.cassidyjames.butler.desktop', 'CHATGPT.desktop', 'org.libreoffice.LibreOffice.writer.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Loupe.desktop', 'com.rustdesk.RustDesk.desktop']
X
sudo dconf update
```

Claude Desktop is officially only available for Ubuntu and Debian (beta), not for Fedora. Until then: claude.ai in Firefox.

## Using another language

Language and keyboard are set in one place, [`senioren-os.conf`](senioren-os.conf):

```bash
LANGUAGE=de            # desktop, Firefox, Thunderbird, spell checking (e.g. en, fr, es, it, nl)
LOCALE=de_DE.UTF-8     # date, numbers, currency
KEYBOARD=de+mac        # keyboard layout (e.g. us, de, fr+mac, es)
```

Change, commit, push: the next build installs the matching language packages and makes Firefox and
Thunderbird use their language pack (installed by policy, so the add-on lock cannot switch them back
to English). The installer still asks for the system language of each machine.

Still German regardless of this setting: the default bookmark titles in `firefox-policies.json`, the
texts of "Mac-Daten retten" and the live ISO boot menu. Translate them in a fork if needed.

**Only one machine in another language** (as admin):

```bash
sudo localectl set-locale LANG=en_US.UTF-8        # system language, effective after the next login
sudo tee /etc/dconf/db/local.d/50-language <<'X'
[org/gnome/desktop/input-sources]
sources=[('xkb', 'us')]
X
sudo dconf update
```

For Firefox, put `"RequestedLocales": ["en-US"]` into `/etc/senioren-os/firefox-lokal.json` (see above).

## Building locally

With Podman. On Apple Silicon Macs the build runs under emulation (takes a long time) and needs about 25–30 GB of space.

```bash
./build.sh image   # build the image
./build.sh iso     # installation ISO into ./output
```

## Emergency

If something stops working after an update: at boot, pick the **second entry** in the menu (the previous version).
To roll back permanently, run `sudo bootc rollback` as admin.

## License

Apache-2.0 for this repo. The bundled packages have their own licenses, e.g. the WhiteSur icons and cursors (GPL-3.0), which are downloaded at build time.
The Apple logos and the app icons that copy Apple's own apps (Finder, Safari, App Store, Mail, ...) are removed from the icon theme during the build; those apps show their regular icons. The wallpaper `huegel.svg` is our own work (Apache-2.0).
This project is not affiliated with Apple. "Mac" only describes the style of operation.
