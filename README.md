# Senioren-OS

A calm, Mac-like Linux for older people who just want to browse the web, read e-mail,
watch YouTube, do online banking and write the occasional letter.
Targets x86-64 PCs and older Intel Macs. It has been tested on a 15-inch Retina MacBook Pro
from 2012. Try the live ISO to check your hardware before installing.

It is based on **Fedora Silverblue** via [Universal Blue](https://universal-blue.org) (`silverblue-main`).
The system is read-only ("atomic"): updates arrive as a whole, and if something goes wrong
you simply pick the previous version at boot.

The repository is Apache-2.0 licensed. The image includes third-party components under their own
licenses, including the Broadcom Wi-Fi driver from RPM Fusion Nonfree.

> **Language:** The desktop, apps and keyboard are configured for German by default.
> See [Using another language](#using-another-language) for settings and translation limits.

## What's included

| Area | Contents |
|---|---|
| Desktop | GNOME in Mac style: dock at the bottom (always visible), window buttons on the left, WhiteSur icons and cursors, Inter font +20 %, large mouse pointer, accessibility menu always visible |
| Locked down | All settings from `00-senioren` are locked except the wallpaper (own photo via the image viewer): dock incl. trash, font, window buttons, app grid. Settings, Terminal and the software center are hidden. Alt+F2 is disabled |
| Calm | A single fixed workspace, no "hot corner", no update notifications, no welcome tour, no automatic screen lock |
| Apps | Firefox, Thunderbird (e-mail), LibreOffice, photo gallery (gThumb), image viewer, PDF viewer (Papers), video player (Showtime), audio player (Decibels), text editor, Gear Lever (installs downloaded AppImages), RustDesk (remote help from the family), ZapZap (WhatsApp), Butler (Home Assistant, e.g. a solar power system) |
| Firefox | Locked homepage (Google), bookmarks for the Sparkasse, YouTube, news, weather, TV media libraries, video calls. uBlock Origin, HTTPS-only, no telemetry, no third-party add-ons, no about:config, website notifications blocked |
| Keyboard/touchpad | German Mac keyboard, natural scrolling, tap to click |
| Hardware | Broadcom Wi-Fi (`wl`, reloaded automatically when it gets stuck after roaming between access points), iPhone/iPad (photos via "Files"), Mac fan control if available |
| Remote maintenance | Optional Tailscale and key-based SSH for administrator accounts |
| Updates | Built daily and split into chunks (only what changed is downloaded). Downloaded in the background, active after the next reboot. See the update and network notes below |

**Admin accounts** (group `wheel`) get an unlocked GNOME profile and access to the hidden launchers.
System-wide browser policies still apply.

## One USB stick for everything: try it, rescue Mac data, install

The ISOs are workflow artifacts. On a repository where you have permission to run workflows,
open *Actions → "Build live ISO (try out + data rescue)" → Run workflow*. Download
`senioren-os-live.iso` and its checksum from the completed run and verify the checksum before
writing the ISO to a USB stick with balenaEtcher. On the Mac, boot holding **Alt** → "EFI Boot" →
"Senioren-OS ausprobieren" (try Senioren-OS). This starts a live session. On some Macs it can update the firmware graphics preference or correct the hardware clock.

- This is what it looks like for the user (locked down). In addition the dock has a terminal and **"Mac-Daten retten"** (rescue Mac data).
- **"Mac-Daten retten"** finds the old Mac disk (APFS, read-only) and copies the user folders it finds
  to an external disk (ideally exFAT) into the folder `mac-backup`. Check the copy on another
  computer before starting installation.
- Good for testing Wi-Fi, graphics and font size on exactly this machine before installing.
- **"Senioren-OS installieren"** (install Senioren-OS) in the dock starts the installer. It needs **internet**
  (Wi-Fi works in the live system), because it downloads the current system from GitHub (about 4 GB). The installer tries to copy the apps from the stick. If that fails, the first-boot service installs them from Flathub.

The plain installation ISO (*"Build installation ISO"*) is still available, e.g. for machines without network access during installation.

## Installing

1. **Get the ISO:** on GitHub under *Actions → "Build installation ISO" → Run workflow*.
   After about 20 minutes `install.iso` is available as a download on the run.
   (Or build locally: see below.)
2. **Write it to a USB stick** (at least 8 GB), e.g. with [balenaEtcher](https://etcher.balena.io) or `dd`.
3. **On the MacBook:** plug in the stick, hold **⌥ (Alt)** while powering on, choose "EFI Boot".
4. **In the installer:** choose the language and confirm the target disk. **Using the whole disk erases its contents.**
   Verify your backup on a separate drive before continuing. Create two accounts:
   - **the user**, *without* administrator rights
   - **you (family/helper)**, *with* administrator rights
5. **After the first boot**, connect to Wi-Fi. LibreOffice, RustDesk, ZapZap, Butler, photo gallery, image viewer, PDF viewer and video player
   are then installed automatically (a few minutes).
6. Set up the e-mail account in Thunderbird if needed.

7. If you use WhatsApp, open ZapZap and scan the QR code with the phone. If you use Home Assistant, open Butler and enter the address
   (e.g. the Tailscale address or the Nabu Casa address) and sign in.

From now on the machine fetches its updates itself from `ghcr.io/<github-user>/senioren-os:latest`.

## Optional remote maintenance

For interactive screen sharing, open RustDesk and have the user approve the session. Close
RustDesk when finished. Configure unattended access only if you need it.

### Tailscale and SSH

Once, on the machine, in the **admin account**:

```bash
sudo tailscale up --hostname=senioren-mac        # open the link and sign in to your own tailnet
mkdir -p ~/.ssh && nano ~/.ssh/authorized_keys   # paste your own public SSH key
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

Keep the device's key expiry enabled and reauthorize it when needed. Limit tailnet access
to the people and devices you use for support. From an authorized device, replace `admin`
with the actual administrator account name:

```bash
ssh admin@senioren-mac
```

To remove remote access, remove the support key from `~/.ssh/authorized_keys` and disconnect
the machine from the tailnet with `sudo tailscale logout` if it no longer needs Tailscale.

## Updates and poor connections

- GitHub schedules a nightly image build. The installed system schedules an update check around
  11 a.m. local time with up to 30 minutes of delay. It also schedules a check after boot.
- The system updater can reuse unchanged image layers. Flatpak updates have their own download sizes
  and may take effect when the app is next launched. A new system deployment takes effect at reboot.
- The first-boot Flatpak installer and the live installer can download apps or the system separately
  from the scheduled updater. Use an unmetered connection for installation and initial setup.

## Customizing

| What | Where |
|---|---|
| GNOME defaults (locked for standard users except the wallpaper) | `system_files/etc/dconf/db/local.d/00-senioren` |
| Additionally locked keys | `system_files/etc/dconf/db/local.d/locks/senioren` |
| Firefox: homepage, bookmarks, policies | `system_files/usr/share/senioren-os/firefox-policies.json` |
| Firefox per machine (local Sparkasse, own bookmarks) | on the machine `/etc/senioren-os/firefox-lokal.json`, see below |
| Apps from Flathub | `system_files/usr/share/senioren-os/flatpaks.list` |
| System packages, drivers, icons, hidden apps (`HIDE`) | `build_files/build.sh` |
| Language and keyboard | `senioren-os.conf` |
| Fedora version | `FEDORA_MAJOR` in `Containerfile` (twice) |
| Update source for newly installed machines | `iso/config.toml` |

Push image changes to `main` to trigger a build. The machine must download the new deployment
before it can boot into it. Changes to the live environment require a fresh live ISO build.

**Your own variant:** the workflows build from the fork owner's image namespace. Also update the
registry references in `iso/config.toml`, `live/Containerfile`, `live/src/build-live.sh` and
`build.sh` so the installers and local builds use your image.

## Files that cannot be opened here

Double-clicking a Windows program (`.exe`, `.msi`), a Mac disk image (`.dmg`, `.pkg`), a phone app
(`.apk`), an installer package or a disk image opens a plain notice instead of an error or a disk
tool: what the file is, that it does not run here, whom to ask, and a button to move it to the trash.
The default support label is `deine Familie`. To set another label, create a local override:

```bash
sudo mkdir -p /etc/senioren-os
printf '%s\n' "deine Ansprechperson" | sudo tee /etc/senioren-os/helfer
```

AppImages open in Gear Lever, which makes them executable and adds them to the app menu.

## Per-machine homepage and bookmarks

The default homepage is Google and the Sparkasse bookmark points to sparkasse.de. The user's own local Sparkasse and personal bookmarks do not belong
in the public image; as admin, put them on the machine itself. Each entry replaces the default entry
of the same name, stays locked and survives updates:

```bash
sudo mkdir -p /etc/senioren-os
sudo tee /etc/senioren-os/firefox-lokal.json <<'X'
{"policies": {
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

The app survives system updates. A package installed from a local file is not updated, though.
If the vendor provides a package repository, install from that instead; then new versions arrive
with the daily system update. The official ChatGPT `.rpm` ships its repository definition, so
copy it into `/etc` first (`rpm-ostree` does not run the vendor's repository setup):

```bash
mkdir /tmp/chatgpt && cd /tmp/chatgpt
curl -fLO https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm
rpm2cpio chatgpt.x86_64.rpm | cpio -idm './etc/yum.repos.d/*' './etc/pki/rpm-gpg/*'
sudo cp -r etc/. /etc/
sudo rpm-ostree install chatgpt     # from OpenAI's repository, updated automatically
systemctl reboot
```

**Adding it to the dock:** the dock list is locked. So, as admin, create a separate file
that overrides the default and survives updates:

```bash
ls /usr/share/applications | grep -i chatgpt      # name of the .desktop file (here: chatgpt.desktop)
sudo tee /etc/dconf/db/local.d/50-lokal <<'X'
[org/gnome/shell]
favorite-apps=['org.mozilla.firefox.desktop', 'net.thunderbird.Thunderbird.desktop', 'com.rtosta.zapzap.desktop', 'com.cassidyjames.butler.desktop', 'chatgpt.desktop', 'org.libreoffice.LibreOffice.writer.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.gThumb.desktop', 'com.rustdesk.RustDesk.desktop']
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

The local script expects the rootful Podman connection `podman-machine-default-root`. On Apple
Silicon the x86-64 build runs under emulation and needs about 25–30 GB of free space.

```bash
./build.sh image   # build the image
./build.sh iso     # installation ISO into ./output
```

## Emergency

If something stops working after an update: at boot, select the previous deployment in the boot menu.
To roll back permanently, run `sudo bootc rollback` as admin.

## License

Apache-2.0 for this repo. The bundled packages have their own licenses, e.g. the WhiteSur icons and cursors (GPL-3.0), which are downloaded at build time.
The Apple logos and the app icons that copy Apple's own apps (Finder, Safari, App Store, Mail, ...) are removed from the icon theme during the build; those apps show their regular icons. The wallpaper `meer.svg` is our own work (Apache-2.0).
This project is not affiliated with Apple. "Mac" only describes the style of operation.
