# Senioren-OS

Ein ruhiges, Mac-artiges Linux für ältere Menschen, die nur surfen, mailen,
YouTube schauen, Online-Banking machen und ab und zu einen Brief schreiben wollen.
Gebaut für ältere Intel-MacBooks (getestet wird mit einem MacBook Pro Retina 15", 2012),
läuft aber auf jedem x86-64-Rechner.

Basis ist **Fedora Silverblue** über [Universal Blue](https://universal-blue.org) (`silverblue-main`).
Das System ist schreibgeschützt („atomic“): Updates kommen als Ganzes, und wenn etwas schiefgeht,
wählt man beim Start einfach die vorherige Version.

Alles ist Open Source. Einzige Ausnahme ist der Broadcom-WLAN-Treiber, den viele MacBooks brauchen
(aus RPM Fusion nonfree).

## Was drin ist

| Bereich | Inhalt |
|---|---|
| Oberfläche | GNOME im Mac-Stil: Dock unten (immer sichtbar), Fensterknöpfe links, WhiteSur-Icons und -Mauszeiger, Schrift Inter +20 %, großer Mauszeiger, Bedienungshilfen-Menü immer sichtbar |
| Festgezurrt | Alle Einstellungen aus `00-senioren` sind gesperrt: Dock samt Papierkorb, Hintergrund, Schrift, Fensterknöpfe, Programmübersicht. Einstellungen, Terminal und Software-Center sind ausgeblendet. Alt+F2 ist gesperrt |
| Ruhe | Ein fester Arbeitsbereich, keine „heiße Ecke“, keine Update-Meldungen, kein Begrüßungs-Assistent, kein automatisches Sperren |
| Programme | Firefox, Thunderbird (E-Mail), LibreOffice, Bildbetrachter, RustDesk (Fernhilfe durch die Familie), ZapZap (WhatsApp), Butler (Home Assistant, z. B. PV-Anlage) |
| Firefox | Startseite gesperrt (Sparkasse), Lesezeichen für YouTube, Nachrichten, Wetter, Mediatheken, Videoanruf. uBlock Origin, HTTPS-only, keine Telemetrie, keine fremden Add-ons, kein about:config, Webseiten-Benachrichtigungen blockiert |
| Tastatur/Touchpad | Deutsche Mac-Tastatur, natürliches Scrollen, Tippen zum Klicken |
| Hardware | Broadcom-WLAN (`wl`), iPhone/iPad (Fotos über „Dateien“), Mac-Lüftersteuerung, falls verfügbar |
| Fernwartung | Tailscale + SSH (nur Admin-Konten, nur mit Schlüssel, nur über Tailscale). In fremden Netzen ist von außen nichts erreichbar |
| Updates | Täglich gebaut und in Pakete zerlegt (nur Geändertes wird geladen). Laden im Hintergrund, aktiv nach dem nächsten Neustart. Nie über getaktete Verbindungen |

**Admin-Konten** (Gruppe `wheel`) sind von allen Sperren ausgenommen und sehen alle Programme.
Nur das Konto des Nutzers ist festgezurrt.

## Ein Stick für alles: ausprobieren, Mac-Daten retten, installieren

*Actions → „Live-ISO bauen“ → Run workflow*, nach etwa 30–40 Minuten `senioren-os-live.iso` herunterladen
und mit balenaEtcher auf einen Stick schreiben. Am Mac mit **Alt** starten → „EFI Boot“ →
„Senioren-OS ausprobieren“. Es wird nichts installiert und nichts verändert.

- So sieht es für den Nutzer aus (festgezurrt). Zusätzlich gibt es im Dock ein Terminal und **„Mac-Daten retten“**.
- **„Mac-Daten retten“** findet die alte Mac-Platte (APFS, nur lesend) und kopiert alle Benutzerordner
  auf eine externe Platte (am besten exFAT) in den Ordner `mac-backup`.
- Gut zum Testen von WLAN, Grafik und Schriftgröße auf genau diesem Gerät, bevor installiert wird.
- **„Senioren-OS installieren“** im Dock startet den Installer. Er braucht **Internet** (WLAN geht im Live-System),
  weil er das aktuelle System von GitHub lädt (ca. 4 GB). Die Programme kommen direkt vom Stick.

Die bisherige reine Installations-ISO (*„Installations-ISO bauen“*) gibt es weiter, z. B. für Rechner ohne Netz bei der Installation.

## Installieren

1. **ISO holen:** In GitHub unter *Actions → „Installations-ISO bauen“ → Run workflow*.
   Nach etwa 20 Minuten liegt `install.iso` als Download am Lauf.
   (Oder lokal: siehe unten.)
2. **Auf einen USB-Stick schreiben** (mindestens 8 GB), z. B. mit [balenaEtcher](https://etcher.balena.io) oder `dd`.
3. **Am MacBook:** Stick einstecken, beim Einschalten **⌥ (Alt)** gedrückt halten, „EFI Boot“ wählen.
4. **Im Installer:** Sprache Deutsch, ganze Festplatte verwenden, zwei Benutzer anlegen:
   - **den Nutzer**, *ohne* Administrator-Rechte
   - **dich (Familie/Helfer)**, *mit* Administrator-Rechten
5. **Nach dem ersten Start** mit dem WLAN verbinden. LibreOffice, RustDesk, ZapZap, Butler und der Bildbetrachter
   werden dann automatisch installiert (ein paar Minuten).
6. In Thunderbird das E-Mail-Konto einrichten. In RustDesk unter Einstellungen ein festes Passwort setzen
   und dir die ID notieren.

7. ZapZap öffnen und den QR-Code mit dem Handy scannen. In Butler die Adresse von Home Assistant eintragen
   (z. B. die Tailscale-Adresse oder die Nabu-Casa-Adresse) und anmelden.
8. Fernwartung einrichten, siehe unten.

Ab jetzt holt sich der Rechner seine Updates selbst aus `ghcr.io/<github-user>/senioren-os:latest`.

## Fernwartung (Tailscale + SSH + KI-Agent)

Einmal am Rechner, im **Admin-Konto**:

```bash
sudo tailscale up --hostname=senioren-mac        # Link öffnen und im eigenen Tailnet anmelden
mkdir -p ~/.ssh && nano ~/.ssh/authorized_keys   # eigenen öffentlichen SSH-Schlüssel einfügen
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

In der Tailscale-Verwaltung bei diesem Gerät **„Disable key expiry“** einschalten,
sonst fliegt es nach 180 Tagen aus dem Netz, z. B. mitten im Urlaub.

Danach von überall:

```bash
ssh admin@senioren-mac
```

**KI-Agent zum Reparieren:** Claude Code nur im Admin-Konto installieren (landet in `~/.local/bin`,
funktioniert auf dem schreibgeschützten System):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Bei Problemen per SSH einloggen und `claude` die Sache untersuchen lassen. Das Konto des Nutzers
bekommt bewusst keinen Agenten: Es hat keine Admin-Rechte, und ein per Sprache steuerbarer Agent wäre
ein Einfallstor für Telefon- und Webseiten-Betrug.

## Updates und schlechtes Netz

- GitHub baut **jede Nacht** neu. Der Rechner prüft täglich gegen 11 Uhr und holt ein verpasstes Update beim nächsten Einschalten nach.
- Es wird **nicht das ganze System** geladen, sondern nur die geänderten Teile. Typisch sind wenige bis einige hundert MB pro Tag.
- `uupd` lädt nur bei genug Akku und **nie über getaktete Verbindungen**. Handy-Hotspots werden meist automatisch erkannt.
  Für ein schwaches WLAN (z. B. im Urlaub): als Admin *Einstellungen → WLAN → Zahnrad → Details → „Getaktete Verbindung“*.
- Bricht ein Download ab, ist nichts kaputt. Beim nächsten Mal wird es erneut versucht.

## Anpassen

| Was | Wo |
|---|---|
| GNOME-Einstellungen (alles wird automatisch gesperrt) | `system_files/etc/dconf/db/local.d/00-senioren` |
| Zusätzlich gesperrte Werte | `system_files/etc/dconf/db/local.d/locks/senioren` |
| Firefox: Startseite, Lesezeichen, Regeln | `system_files/usr/share/senioren-os/firefox-policies.json` |
| Firefox pro Rechner (eigene Sparkasse, eigene Lesezeichen) | auf dem Rechner `/etc/senioren-os/firefox-lokal.json`, siehe unten |
| Programme aus Flathub | `system_files/usr/share/senioren-os/flatpaks.list` |
| Systempakete, Treiber, Icons, ausgeblendete Programme (`HIDE`) | `build_files/build.sh` |
| Fedora-Version | `FEDORA_MAJOR` in `Containerfile` (zweimal) |
| Update-Quelle für neu installierte Rechner | `iso/config.toml` |

Ändern → committen → GitHub baut neu → die Rechner haben es nach dem nächsten Neustart.

**Eigene Variante:** Repo forken und in `iso/config.toml` den GitHub-Benutzernamen anpassen.

## Eigene Startseite und Lesezeichen pro Rechner

Die Vorgabe zeigt auf sparkasse.de. Die eigene Sparkasse und persönliche Lesezeichen gehören nicht
ins öffentliche Image, sondern als Admin auf den Rechner selbst. Jeder Eintrag ersetzt den
gleichnamigen der Vorgabe, bleibt gesperrt und übersteht Updates:

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
sudo systemctl restart senioren-firefox-policies   # danach Firefox neu starten
```

## Zusätzliche Apps auf einem einzelnen Rechner (z. B. ChatGPT)

Nicht-freie Apps wie die offizielle ChatGPT-App gehören nicht ins öffentliche Image.
Als Admin auf dem Rechner selbst installieren:

```bash
# .rpm von der Hersteller-Seite herunterladen, dann:
sudo rpm-ostree install ~/Downloads/ChatGPT-*.rpm
systemctl reboot
```

Die App bleibt bei System-Updates erhalten. Neue Versionen der App muss man selbst installieren,
falls der Hersteller kein Paket-Repo einrichtet.

**Ins Dock legen:** Die Dock-Liste ist gesperrt. Deshalb als Admin eine eigene Datei anlegen,
die die Voreinstellung überschreibt und bei Updates erhalten bleibt:

```bash
ls /usr/share/applications | grep -i chatgpt      # Namen der .desktop-Datei herausfinden
sudo tee /etc/dconf/db/local.d/50-lokal <<'X'
[org/gnome/shell]
favorite-apps=['org.mozilla.firefox.desktop', 'net.thunderbird.Thunderbird.desktop', 'com.rtosta.zapzap.desktop', 'com.cassidyjames.butler.desktop', 'CHATGPT.desktop', 'org.libreoffice.LibreOffice.writer.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Loupe.desktop', 'com.rustdesk.RustDesk.desktop']
X
sudo dconf update
```

Claude Desktop gibt es offiziell nur für Ubuntu und Debian (Beta), nicht für Fedora. Bis dahin: claude.ai in Firefox.

## Lokal bauen

Mit Podman. Auf Apple-Silicon-Macs läuft der Build per Emulation (dauert lange) und braucht etwa 25–30 GB Platz.

```bash
./build.sh image   # Image bauen
./build.sh iso     # Installations-ISO nach ./output
```

## Notfall

Wenn nach einem Update etwas nicht geht: beim Start im Menü den **zweiten Eintrag** wählen (die vorherige Version).
Dauerhaft zurück geht es als Admin mit `sudo bootc rollback`.

## Lizenz

Apache-2.0 für dieses Repo. Die eingebundenen Pakete haben ihre eigenen Lizenzen, z. B. WhiteSur-Icons und -Cursor (GPL-3.0), die beim Bauen heruntergeladen werden.
Die Apple-Logos aus dem Icon-Theme werden beim Bauen entfernt.
Dieses Projekt hat nichts mit Apple zu tun. „Mac“ beschreibt nur das Bedienkonzept.
