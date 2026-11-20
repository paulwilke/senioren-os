#!/usr/bin/bash
# Installs the Senioren-OS apps from Flathub (system-wide) and keeps them complete.
# Runs at every boot, but only downloads something if an app, its runtime or its
# translation is missing (e.g. after an interrupted installation).
set -uo pipefail

LIST=/usr/share/senioren-os/flatpaks.list
FP=/var/lib/flatpak
LANGUAGE=de
[[ -r /usr/share/senioren-os/senioren-os.conf ]] && source /usr/share/senioren-os/senioren-os.conf

flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak config --system --set languages "${LANGUAGE};en"

# Leftovers of an interrupted copy: empty, root-only folders without an installed version.
# They break apps for normal users, so remove them and let flatpak reinstall cleanly.
BROKEN=0
for d in "$FP"/app/* "$FP"/runtime/*; do
    [[ -d $d ]] || continue
    if ! compgen -G "$d/*/*/active" >/dev/null; then
        echo "incomplete: ${d#"$FP"/}"
        rm -rf "$d"
        BROKEN=1
    fi
done
((BROKEN)) && flatpak repair --system

mapfile -t WANTED < <(grep -vE '^\s*(#|$)' "$LIST")
MISSING=() INCOMPLETE=()
for app in "${WANTED[@]}"; do
    if ! flatpak info --system "$app" >/dev/null 2>&1; then
        MISSING+=("$app")
        continue
    fi
    # e.g. "runtime=org.gnome.Platform/x86_64/49" in the app's metadata
    runtime=$(sed -n 's/^runtime=//p' "$FP/app/$app/current/active/metadata" 2>/dev/null | head -1)
    if [[ -z $runtime ]] || [[ ! -e $FP/runtime/$runtime/active ]]; then
        INCOMPLETE+=("$app")
    fi
done

# Any failure (e.g. no internet yet) ends with an error, so systemd retries later
rc=0
if ((${#MISSING[@]})); then
    flatpak install --system --noninteractive --assumeyes flathub "${MISSING[@]}" || rc=1
fi
if ((${#INCOMPLETE[@]})); then
    # Reinstalling also pulls the runtime and the translations (.Locale)
    flatpak install --system --noninteractive --assumeyes --reinstall flathub "${INCOMPLETE[@]}" || rc=1
fi
if ((BROKEN)); then
    # Brings back missing translations and extensions of apps that were otherwise fine
    flatpak update --system --noninteractive --assumeyes || rc=1
fi
exit $rc
