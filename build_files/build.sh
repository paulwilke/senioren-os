#!/usr/bin/bash
# Builds Senioren-OS on top of Universal Blue silverblue-main.
set -euxo pipefail

CTX=/ctx
# Language and keyboard (LANGUAGE, LOCALE, KEYBOARD)
source "$CTX/senioren-os.conf"

### 1. Own system files (dconf, Firefox policies, services) ###############
cp -a "$CTX/system_files/." /

### 2. Broadcom-WLAN (BCM4331 im MacBook Pro 2012) #########################
# Prebuilt kmod-wl from Universal Blue, matching the kernel in the image.
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
# Make sure "wl" is not blacklisted (Universal Blue sometimes blocks it by default)
rm -f /etc/modprobe.d/default-disable-broadcom-wl.conf /etc/modprobe.d/broadcom-wl-blacklist.conf
test -n "$(find /usr/lib/modules/"${KERNEL}" -name 'wl.ko*')"

### 3. Apps as system packages ############################################
dnf5 -y install \
    firefox firefox-langpacks thunderbird \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-appindicator \
    rsms-inter-fonts \
    usbmuxd libimobiledevice-utils ifuse gvfs-afc gvfs-gphoto2

# Language from senioren-os.conf: translations, date formats, spell checking
dnf5 -y install --skip-unavailable \
    "langpacks-${LANGUAGE}" "glibc-langpack-${LANGUAGE}" "hunspell-${LANGUAGE}"
# Firefox/Thunderbird language pack enforced by policy, keyboard, system locale
"$CTX/build_files/language.py" "$CTX/senioren-os.conf"

# Tailscale (official repo; updates arrive with every image build)
curl -fsSL -o /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 -y install tailscale
sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/tailscale.repo

# Only if available: fan control for Macs
dnf5 -y install --skip-unavailable mbpfan || true

# Remove what the user does not need (can still be installed later via Flatpak)
dnf5 -y remove --no-autoremove gnome-tour gnome-extensions-app || true

### 4. Mac-like icons and cursors (GPL-3.0, pinned versions) ##############
ICONS_TAG=2026-09-10
CURSORS_SHA=e190baf618ed95ee217d2fd45589bd309b37672b

curl -fsSL "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/tags/${ICONS_TAG}.tar.gz" \
    | tar -xz -C /tmp
( cd /tmp/WhiteSur-icon-theme-* && ./install.sh -d /usr/share/icons -t default -b )

curl -fsSL "https://github.com/vinceliuice/WhiteSur-cursors/archive/${CURSORS_SHA}.tar.gz" \
    | tar -xz -C /tmp
cp -a /tmp/WhiteSur-cursors-*/dist /usr/share/icons/WhiteSur-cursors

# Remove trademarked Apple logos; the default icon is used instead
find /usr/share/icons/WhiteSur* \( -type f -o -type l \) \( -iname '*apple*' -o -iname 'start-here*' -o -iname 'distributor-logo*' \) -delete
gtk-update-icon-cache -f /usr/share/icons/WhiteSur || true
gtk-update-icon-cache -f /usr/share/icons/WhiteSur-light || true

### 5. Lock down settings #################################################
# Lock every key from 00-senioren so the user cannot change anything.
awk '
  /^\[.*\]$/ { sec = substr($0, 2, length($0) - 2); next }
  /^[a-z0-9-]+=/ { split($0, kv, "="); print "/" sec "/" kv[1] }
' /etc/dconf/db/local.d/00-senioren > /etc/dconf/db/local.d/locks/00-senioren-auto
wc -l /etc/dconf/db/local.d/locks/00-senioren-auto
# Admin accounts get the same defaults, but without locks
mkdir -p /etc/dconf/db/senioren-admin.d
cp /etc/dconf/db/local.d/00-senioren /etc/dconf/db/senioren-admin.d/00-senioren
dconf update

# Remove tools that can be used to change the system from the app grid.
# Admins still see them (see 90-senioren-admin) and can run them as commands.
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
    cp "$f" /usr/share/senioren-os/admin/applications/   # visible copy for admins
    sed -i '/^NoDisplay=/d; /^\[Desktop Entry\]/a NoDisplay=true' "$f"
    echo "hidden: $app"
done

# Firefox policies: defaults from /usr, merged at boot with /etc/senioren-os/firefox-lokal.json
/usr/libexec/senioren-firefox-policies.py
python3 -c "import json; json.load(open('/etc/firefox/policies/policies.json'))"

systemctl enable senioren-flatpaks.service senioren-mac-gpu.service senioren-firefox-policies.service
systemctl enable tailscaled.service sshd.service

# Firewall: on foreign networks (holiday, café) nothing is reachable from outside.
# SSH and everything else only via the own Tailscale network.
firewall-offline-cmd --set-default-zone=public
for svc in ssh cockpit; do
    if firewall-offline-cmd --zone=public --query-service="$svc"; then
        firewall-offline-cmd --zone=public --remove-service-from-zone="$svc"
    fi
done
firewall-offline-cmd --zone=trusted --add-interface=tailscale0
# Verify instead of hoping: SSH must not be open in the default zone
firewall-offline-cmd --zone=public --list-services
! firewall-offline-cmd --zone=public --query-service=ssh
[[ -e /usr/lib/systemd/system/mbpfan.service ]] && systemctl enable mbpfan.service

# Automatic updates with uupd (Universal Blue): downloads system + Flatpaks in the
# background, active after the next reboot, NEVER over metered connections.
dnf5 -y copr enable ublue-os/packages
dnf5 -y install uupd
dnf5 -y copr disable ublue-os/packages
systemctl disable rpm-ostreed-automatic.timer flatpak-system-update.timer 2>/dev/null || true
systemctl enable uupd.timer

### 6. Clean up ############################################################
dnf5 clean all
rm -rf /tmp/* /var/tmp/* || true
