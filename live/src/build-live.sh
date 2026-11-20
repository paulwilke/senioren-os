#!/usr/bin/bash
# Macht aus dem Senioren-OS-Image ein Live-System (nach dem Titanoboa-Beispiel "zirconium").
set -exo pipefail
SRC=/src

mkdir -p "$(realpath /root)"
mount -o remount,rw /proc/sys

# Programme gleich mitbringen, damit sie live ohne Internet da sind
mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -fsSLo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak config --system --set languages "de;en"
grep -vE '^\s*(#|$)' /usr/share/senioren-os/flatpaks.list \
    | xargs -r flatpak install --system -y --noninteractive flathub

# Datenrettung: APFS-Platten alter Macs lesen (nur lesend)
dnf5 -y install apfs-fuse rsync
install -m 0755 "$SRC/mac-daten-retten" /usr/bin/mac-daten-retten
install -m 0644 "$SRC/mac-daten-retten.desktop" /usr/share/applications/mac-daten-retten.desktop

# Live-Ansicht = Ansicht des Nutzers (festgezurrt), aber mit Terminal und Datenrettung im Dock
rm -f /usr/lib/systemd/user-environment-generators/90-senioren-admin
cp /usr/share/senioren-os/admin/applications/org.gnome.Ptyxis.desktop /usr/share/applications/ || true
cat > /etc/dconf/db/local.d/50-live <<'X'
[org/gnome/shell]
favorite-apps=['mac-daten-retten.desktop', 'org.mozilla.firefox.desktop', 'net.thunderbird.Thunderbird.desktop', 'com.rtosta.zapzap.desktop', 'com.cassidyjames.butler.desktop', 'org.libreoffice.LibreOffice.writer.desktop', 'org.libreoffice.LibreOffice.calc.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Loupe.desktop', 'org.gnome.Ptyxis.desktop']
X
dconf update

# Live-Start: dracut-live ins initramfs, Live-Benutzer mit automatischer Anmeldung
dnf5 -y install dracut-live livesys-scripts
kernel=$(kernel-install list --json pretty | jq -r '.[] | select(.has_kernel == true) | .version')
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"
systemctl enable livesys.service livesys-late.service

# Im Live-System keine Updates und kein Nachinstallieren
systemctl disable uupd.timer senioren-flatpaks.service || true

# Bootloader-Dateien, die das ISO-Werkzeug erwartet
dnf5 -y install grub2-efi-x64-cdboot
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/
cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi

rm -f /etc/localtime
systemd-firstboot --timezone Europe/Berlin

# /var/tmp im Live-System größer machen
mkdir -p /var/tmp
cat > /etc/systemd/system/var-tmp.mount <<'X'
[Unit]
Description=Larger tmpfs for /var/tmp on live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m

[Install]
WantedBy=local-fs.target
X
systemctl enable var-tmp.mount

mkdir -p /usr/lib/bootc-image-builder
cp "$SRC/iso.yaml" /usr/lib/bootc-image-builder/iso.yaml

dnf5 clean all
