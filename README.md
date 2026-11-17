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
| Programme | Firefox, Thunderbird (E-Mail), LibreOffice, Bildbetrachter, RustDesk (Fernhilfe durch die Familie) |
| Firefox | Startseite gesperrt (Sparkasse), Lesezeichen für YouTube, Nachrichten, Wetter, Mediatheken, WhatsApp Web, Videoanruf. uBlock Origin, HTTPS-only, keine Telemetrie, keine fremden Add-ons, kein about:config, Webseiten-Benachrichtigungen blockiert |
| Tastatur/Touchpad | Deutsche Mac-Tastatur, natürliches Scrollen, Tippen zum Klicken |
| Hardware | Broadcom-WLAN (`wl`), iPhone/iPad (Fotos über „Dateien“), Mac-Lüftersteuerung, falls verfügbar |
| Updates | Wöchentlich gebaut und in Pakete zerlegt (nur Geändertes wird geladen). Laden im Hintergrund, aktiv nach dem nächsten Neustart. Nie über getaktete Verbindungen |

**Admin-Konten** (Gruppe `wheel`) sind von allen Sperren ausgenommen und sehen alle Programme.
Nur das Konto des Nutzers ist festgezurrt.

## Installieren

1. **ISO holen:** In GitHub unter *Actions → „Installations-ISO bauen“ → Run workflow*.
   Nach etwa 20 Minuten liegt `install.iso` als Download am Lauf.
   (Oder lokal: siehe unten.)
2. **Auf einen USB-Stick schreiben** (mindestens 8 GB), z. B. mit [balenaEtcher](https://etcher.balena.io) oder `dd`.
3. **Am MacBook:** Stick einstecken, beim Einschalten **⌥ (Alt)** gedrückt halten, „EFI Boot“ wählen.
4. **Im Installer:** Sprache Deutsch, ganze Festplatte verwenden, zwei Benutzer anlegen:
   - **den Nutzer**, *ohne* Administrator-Rechte
   - **dich (Familie/Helfer)**, *mit* Administrator-Rechten
5. **Nach dem ersten Start** mit dem WLAN verbinden. LibreOffice, RustDesk und der Bildbetrachter
   werden dann automatisch installiert (ein paar Minuten).
6. In Thunderbird das E-Mail-Konto einrichten. In RustDesk unter Einstellungen ein festes Passwort setzen
   und dir die ID notieren.

Ab jetzt holt sich der Rechner seine Updates selbst aus `ghcr.io/<github-user>/senioren-os:latest`.

## Updates und schlechtes Netz

- GitHub baut **einmal pro Woche** (Sonntagnacht). Der Rechner lädt also höchstens einmal pro Woche etwas.
- Es wird **nicht das ganze System** geladen, sondern nur die geänderten Teile. Typisch sind 50–400 MB pro Woche.
- `uupd` lädt nur bei genug Akku und **nie über getaktete Verbindungen**. Handy-Hotspots werden meist automatisch erkannt.
  Für ein schwaches WLAN (z. B. im Urlaub): als Admin *Einstellungen → WLAN → Zahnrad → Details → „Getaktete Verbindung“*.
- Bricht ein Download ab, ist nichts kaputt. Beim nächsten Mal wird es erneut versucht.

## Anpassen

| Was | Wo |
|---|---|
| GNOME-Einstellungen (alles wird automatisch gesperrt) | `system_files/etc/dconf/db/local.d/00-senioren` |
| Zusätzlich gesperrte Werte | `system_files/etc/dconf/db/local.d/locks/senioren` |
| Firefox: Startseite, Lesezeichen, Regeln | `system_files/etc/firefox/policies/policies.json` |
| Programme aus Flathub | `system_files/usr/share/senioren-os/flatpaks.list` |
| Systempakete, Treiber, Icons, ausgeblendete Programme (`HIDE`) | `build_files/build.sh` |
| Fedora-Version | `FEDORA_MAJOR` in `Containerfile` (zweimal) |
| Update-Quelle für neu installierte Rechner | `iso/config.toml` |

Ändern → committen → GitHub baut neu → die Rechner haben es nach dem nächsten Neustart.

**Eigene Variante:** Repo forken und in `iso/config.toml` den GitHub-Benutzernamen anpassen.

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
