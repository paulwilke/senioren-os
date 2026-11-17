#!/usr/bin/bash
# Installiert die Senioren-OS-Programme aus Flathub (systemweit) und hält die Liste aktuell.
# Läuft bei jedem Start, tut aber nur etwas, wenn ein Programm fehlt.
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
