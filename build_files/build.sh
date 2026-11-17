#!/usr/bin/bash
# Baut Senioren-OS auf Basis von Universal Blue silverblue-main.
set -euxo pipefail

CTX=/ctx

### 1. Eigene Systemdateien (dconf, Firefox-Richtlinien, Dienste) ##########
cp -a "$CTX/system_files/." /

### 2. Broadcom-WLAN (BCM4331 im MacBook Pro 2012) #########################
# Fertig gebautes kmod-wl von Universal Blue, passend zum Kernel im Image.
KERNEL=$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | tail -1)
skopeo copy --retry-times 3 \
    "docker://ghcr.io/ublue-os/akmods:main-${FEDORA_MAJOR}-${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xzf "/tmp/akmods/${AKMODS_TARGZ}" -C /tmp/
ls /tmp/rpms/kmods/

dnf5 -y install \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR}.noarch.rpm"
dnf5 -y install broadcom-wl /tmp/rpms/kmods/kmod-wl-*.rpm
dnf5 -y remove rpmfusion-nonfree-release
# Sicherstellen, dass "wl" nicht blockiert ist (Universal Blue blockiert es teils standardmäßig)
rm -f /etc/modprobe.d/default-disable-broadcom-wl.conf /etc/modprobe.d/broadcom-wl-blacklist.conf
test -n "$(find /usr/lib/modules/"${KERNEL}" -name 'wl.ko*')"

### 3. Programme als Systempakete ##########################################
dnf5 -y install \
    firefox firefox-langpacks thunderbird \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-appindicator \
    langpacks-de glibc-langpack-de hunspell-de \
    rsms-inter-fonts \
    usbmuxd libimobiledevice-utils ifuse gvfs-afc gvfs-gphoto2

# Nur falls verfügbar: Lüftersteuerung für Macs
dnf5 -y install --skip-unavailable mbpfan || true

# Unnötiges für den Nutzer entfernen (bleibt per Flatpak nachinstallierbar)
dnf5 -y remove --no-autoremove gnome-tour gnome-extensions-app || true

### 4. Mac-artige Icons und Mauszeiger (GPL-3.0, feste Versionen) ##########
ICONS_TAG=2026-09-10
CURSORS_SHA=e190baf618ed95ee217d2fd45589bd309b37672b

curl -fsSL "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/tags/${ICONS_TAG}.tar.gz" \
    | tar -xz -C /tmp
( cd /tmp/WhiteSur-icon-theme-* && ./install.sh -d /usr/share/icons -t default -b )

curl -fsSL "https://github.com/vinceliuice/WhiteSur-cursors/archive/${CURSORS_SHA}.tar.gz" \
    | tar -xz -C /tmp
cp -a /tmp/WhiteSur-cursors-*/dist /usr/share/icons/WhiteSur-cursors

# Markenrechtlich geschützte Apple-Logos entfernen; es greift dann das Standard-Icon
find /usr/share/icons/WhiteSur* \( -type f -o -type l \) \( -iname '*apple*' -o -iname 'start-here*' -o -iname 'distributor-logo*' \) -delete
gtk-update-icon-cache -f /usr/share/icons/WhiteSur || true
gtk-update-icon-cache -f /usr/share/icons/WhiteSur-light || true

### 5. Einstellungen festzurren ###########################################
# Jeden Schlüssel aus 00-senioren sperren, damit der Nutzer nichts verstellen kann.
awk '
  /^\[.*\]$/ { sec = substr($0, 2, length($0) - 2); next }
  /^[a-z0-9-]+=/ { split($0, kv, "="); print "/" sec "/" kv[1] }
' /etc/dconf/db/local.d/00-senioren > /etc/dconf/db/local.d/locks/00-senioren-auto
wc -l /etc/dconf/db/local.d/locks/00-senioren-auto
# Admin-Konten bekommen dieselben Voreinstellungen, aber ohne Sperren
mkdir -p /etc/dconf/db/senioren-admin.d
cp /etc/dconf/db/local.d/00-senioren /etc/dconf/db/senioren-admin.d/00-senioren
dconf update

# Werkzeuge, mit denen man das System verstellen kann, aus der Programmübersicht
# nehmen. Für den Admin bleiben sie per Befehl erreichbar.
HIDE=(
    org.gnome.Settings org.gnome.Software org.gnome.Ptyxis org.gnome.Terminal
    org.gnome.Extensions com.mattjakeman.ExtensionManager io.github.kolunmi.Bazaar
    org.gnome.tweaks org.gnome.Tour yelp org.gnome.Yelp org.gnome.DiskUtility
    org.gnome.SystemMonitor org.gnome.baobab org.gnome.Logs org.gnome.Connections
    nvtop htop system-update ublue-os-system-update documentation
    org.freedesktop.MalcontentControl
)
mkdir -p /usr/share/senioren-os/admin/applications
for app in "${HIDE[@]}"; do
    f=/usr/share/applications/${app}.desktop
    [[ -f $f ]] || continue
    cp "$f" /usr/share/senioren-os/admin/applications/   # sichtbare Kopie für Admins
    sed -i '/^NoDisplay=/d; /^\[Desktop Entry\]/a NoDisplay=true' "$f"
    echo "versteckt: $app"
done

systemctl enable senioren-flatpaks.service
[[ -e /usr/lib/systemd/system/mbpfan.service ]] && systemctl enable mbpfan.service

# Automatische Updates: Universal Blue "uupd" lädt System + Flatpaks im
# Hintergrund und aktiviert sie beim nächsten Neustart (kein Zwangsneustart).
if [[ -e /usr/lib/systemd/system/uupd.timer ]]; then
    systemctl enable uupd.timer
else
    sed -i 's/^#\?AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf
    systemctl enable rpm-ostreed-automatic.timer flatpak-system-update.timer || true
fi

### 6. Aufräumen ###########################################################
dnf5 clean all
rm -rf /tmp/* /var/tmp/* || true
