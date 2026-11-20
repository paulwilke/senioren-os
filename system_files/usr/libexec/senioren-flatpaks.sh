#!/usr/bin/bash
# Installs the Senioren-OS apps from Flathub (system-wide) and keeps the list up to date.
# Runs at every boot, but only does something if an app is missing.
set -uo pipefail

LIST=/usr/share/senioren-os/flatpaks.list

flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak config --system --set languages "de;en"

mapfile -t WANTED < <(grep -vE '^\s*(#|$)' "$LIST")
mapfile -t HAVE < <(flatpak list --system --app --columns=application)

MISSING=()
for app in "${WANTED[@]}"; do
    printf '%s\n' "${HAVE[@]}" | grep -qx "$app" || MISSING+=("$app")
done

if ((${#MISSING[@]})); then
    flatpak install --system --noninteractive --assumeyes flathub "${MISSING[@]}"
fi
